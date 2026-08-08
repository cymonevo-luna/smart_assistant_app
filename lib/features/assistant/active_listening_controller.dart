import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import 'assistant_controller.dart';
import 'assistant_settings_provider.dart';
import 'models/assistant_settings.dart';
import 'services/active_listening_task_handler.dart';
import 'services/foreground_listening_service.dart';
import 'services/wake_word_engine.dart';

enum ActiveListeningMode {
  idle,
  monitoring,
  capturingCommand,
  paused,
}

class ActiveListeningState {
  const ActiveListeningState({
    this.mode = ActiveListeningMode.idle,
    this.wakeWord = 'Jarvis',
    this.activeListeningEnabled = false,
    this.errorMessage,
  });

  final ActiveListeningMode mode;
  final String wakeWord;
  final bool activeListeningEnabled;
  final String? errorMessage;

  bool get isMonitoring =>
      activeListeningEnabled && mode == ActiveListeningMode.monitoring;

  ActiveListeningState copyWith({
    ActiveListeningMode? mode,
    String? wakeWord,
    bool? activeListeningEnabled,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ActiveListeningState(
      mode: mode ?? this.mode,
      wakeWord: wakeWord ?? this.wakeWord,
      activeListeningEnabled:
          activeListeningEnabled ?? this.activeListeningEnabled,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Drives on-device wake-word monitoring (Porcupine — see
/// [PorcupineWakeWordEngine]) and hands off to [AssistantController] once
/// the wake word fires.
///
/// On Android, monitoring runs inside a foreground-service-backed isolate
/// ([ActiveListeningTaskHandler]) so it keeps running even if the app is
/// swiped away from recents. iOS does not allow background microphone
/// access for third-party apps, so there monitoring only runs while the app
/// is in the foreground.
class ActiveListeningController extends Notifier<ActiveListeningState> {
  ForegroundListeningService? _foregroundServiceInstance;
  WakeWordEngine? _iosEngine;

  bool _startingMonitoring = false;
  bool _settingsApplied = false;
  bool _taskDataCallbackRegistered = false;

  @override
  ActiveListeningState build() {
    _foregroundServiceInstance ??= ref.read(foregroundListeningServiceProvider);

    final settings =
        ref.watch(assistantSettingsProvider).value ?? _defaultSettings;

    ref.listen(assistantSettingsProvider, (previous, next) {
      final settings = next.value;
      if (settings == null) return;
      Future.microtask(
        () => _applySettings(settings, previous?.value),
      );
    });

    ref.listen(assistantControllerProvider, (previous, next) {
      _onAssistantStateChanged(next);
    });

    ref.onDispose(() {
      _settingsApplied = false;
      _detachTaskDataCallback();
      _foregroundServiceInstance?.stop();
      _iosEngine?.dispose();
      _iosEngine = null;
      _foregroundServiceInstance = null;
    });

    if (!_settingsApplied) {
      Future.microtask(() async {
        if (!ref.mounted) return;
        _settingsApplied = true;
        final current =
            ref.read(assistantSettingsProvider).value ?? _defaultSettings;
        await _applySettings(current, null);
      });
    }

    return ActiveListeningState(
      wakeWord: settings.wakeWord,
      activeListeningEnabled: settings.activeListeningEnabled,
    );
  }

  static const _defaultSettings = AssistantSettings(
    wakeWord: 'Jarvis',
    activeListeningEnabled: false,
  );

  Future<void> _applySettings(
    AssistantSettings settings,
    AssistantSettings? previous,
  ) async {
    state = state.copyWith(
      wakeWord: settings.wakeWord,
      activeListeningEnabled: settings.activeListeningEnabled,
    );

    if (!settings.activeListeningEnabled) {
      await _stopMonitoring();
      return;
    }

    if (!_shouldPauseForAssistant(ref.read(assistantControllerProvider))) {
      await _startMonitoring();
    }
  }

  void _onAssistantStateChanged(AssistantUiState assistantState) {
    if (!state.activeListeningEnabled) return;

    if (_shouldPauseForAssistant(assistantState)) {
      _pauseMonitoring();
    } else if (state.mode == ActiveListeningMode.paused) {
      _startMonitoring();
    }
  }

  bool _shouldPauseForAssistant(AssistantUiState assistantState) {
    return assistantState.interactionState != AssistantInteractionState.idle;
  }

  Future<void> _startMonitoring() async {
    if (!state.activeListeningEnabled || _startingMonitoring) return;
    if (_shouldPauseForAssistant(ref.read(assistantControllerProvider))) {
      state = state.copyWith(mode: ActiveListeningMode.paused);
      return;
    }
    if (AppConfig.picovoiceAccessKey.isEmpty) {
      state = state.copyWith(
        mode: ActiveListeningMode.idle,
        errorMessage: 'Active listening is not configured yet.',
      );
      return;
    }

    _startingMonitoring = true;

    final started =
        Platform.isAndroid ? await _startAndroidMonitoring() : await _startIosMonitoring();

    _startingMonitoring = false;

    if (!started) {
      state = state.copyWith(mode: ActiveListeningMode.idle);
      return;
    }

    state = state.copyWith(mode: ActiveListeningMode.monitoring, clearErrorMessage: true);
  }

  Future<bool> _startAndroidMonitoring() async {
    final foregroundService = _foregroundServiceInstance;
    if (foregroundService == null) return false;

    _attachTaskDataCallback();
    await foregroundService.start(notificationText: 'Listening for "${state.wakeWord}"…');
    return foregroundService.isRunning;
  }

  Future<bool> _startIosMonitoring() async {
    final engine = _iosEngine ??= PorcupineWakeWordEngine(
      accessKey: AppConfig.picovoiceAccessKey,
    )
      ..onWakeWord = _onWakeWordDetected
      ..onError = (message) => state = state.copyWith(errorMessage: message);
    return engine.start();
  }

  Future<void> _pauseMonitoring() async {
    if (state.mode != ActiveListeningMode.monitoring) return;
    await _stopEngine();
    state = state.copyWith(mode: ActiveListeningMode.paused);
  }

  Future<void> _stopMonitoring() async {
    _startingMonitoring = false;
    await _stopEngine();
    state = state.copyWith(mode: ActiveListeningMode.idle);
  }

  Future<void> _stopEngine() async {
    if (Platform.isAndroid) {
      _detachTaskDataCallback();
      await _foregroundServiceInstance?.stop();
    } else {
      await _iosEngine?.stop();
    }
  }

  void _attachTaskDataCallback() {
    if (_taskDataCallbackRegistered) return;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _taskDataCallbackRegistered = true;
  }

  void _detachTaskDataCallback() {
    if (!_taskDataCallbackRegistered) return;
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _taskDataCallbackRegistered = false;
  }

  void _onTaskData(Object data) {
    if (data == wakeWordDetectedMessage) {
      _onWakeWordDetected();
      return;
    }
    if (data is String && data.startsWith('wake_word_error:')) {
      state = state.copyWith(errorMessage: data.substring('wake_word_error:'.length));
    }
  }

  /// Porcupine only reports that the wake word fired — it never transcribes,
  /// so there is no trailing command text like the old transcript-matching
  /// approach could capture. The assistant always opens a normal listening
  /// session for the follow-up command.
  void _onWakeWordDetected() {
    _handleWakeWordDetected();
  }

  Future<void> _handleWakeWordDetected() async {
    await _pauseMonitoring();
    if (Platform.isAndroid) {
      FlutterForegroundTask.launchApp();
    }
    appRouter.goNamed(AppRoute.assistant.name);

    final assistant = ref.read(assistantControllerProvider.notifier);
    await assistant.startWakeWordCommandCapture();
  }
}

final activeListeningControllerProvider =
    NotifierProvider<ActiveListeningController, ActiveListeningState>(
  ActiveListeningController.new,
);
