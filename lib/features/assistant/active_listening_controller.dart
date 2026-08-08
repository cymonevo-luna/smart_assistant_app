import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import 'assistant_controller.dart';
import 'assistant_settings_provider.dart';
import 'models/assistant_settings.dart';
import 'services/foreground_listening_service.dart';
import 'services/speech_to_text_service.dart';
import 'services/wake_word_detector.dart';

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
  });

  final ActiveListeningMode mode;
  final String wakeWord;
  final bool activeListeningEnabled;

  bool get isMonitoring =>
      activeListeningEnabled && mode == ActiveListeningMode.monitoring;

  ActiveListeningState copyWith({
    ActiveListeningMode? mode,
    String? wakeWord,
    bool? activeListeningEnabled,
  }) {
    return ActiveListeningState(
      mode: mode ?? this.mode,
      wakeWord: wakeWord ?? this.wakeWord,
      activeListeningEnabled:
          activeListeningEnabled ?? this.activeListeningEnabled,
    );
  }
}

class ActiveListeningController extends Notifier<ActiveListeningState> {
  SpeechToTextService? _sttService;
  ForegroundListeningService? _foregroundServiceInstance;
  final WakeWordDetector _detector = WakeWordDetector();

  String _currentWakeWord = 'Jarvis';
  bool _wakeWordHandledForUtterance = false;
  bool _startingMonitoring = false;
  bool _settingsApplied = false;

  @override
  ActiveListeningState build() {
    _sttService ??= ref.read(speechToTextServiceProvider);
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
      _sttService?.stopContinuousListening();
      _foregroundServiceInstance?.stop();
      _sttService = null;
      _foregroundServiceInstance = null;
    });

    _currentWakeWord = settings.wakeWord;

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
    _currentWakeWord = settings.wakeWord;
    state = state.copyWith(
      wakeWord: settings.wakeWord,
      activeListeningEnabled: settings.activeListeningEnabled,
    );

    if (!settings.activeListeningEnabled) {
      await _stopMonitoring();
      return;
    }

    if (previous?.wakeWord != settings.wakeWord &&
        state.mode == ActiveListeningMode.monitoring) {
      _wakeWordHandledForUtterance = false;
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
    final stt = _sttService;
    final foregroundService = _foregroundServiceInstance;
    if (stt == null || foregroundService == null) return;
    if (!state.activeListeningEnabled || _startingMonitoring) return;
    if (_shouldPauseForAssistant(ref.read(assistantControllerProvider))) {
      state = state.copyWith(mode: ActiveListeningMode.paused);
      return;
    }

    _startingMonitoring = true;
    _wakeWordHandledForUtterance = false;

    final foregroundStarted = await foregroundService.start(
      notificationText: 'Listening for $_currentWakeWord…',
    );

    if (!foregroundStarted) {
      _startingMonitoring = false;
      state = state.copyWith(mode: ActiveListeningMode.idle);
      return;
    }

    if (stt.isContinuousListening) {
      _startingMonitoring = false;
      state = state.copyWith(mode: ActiveListeningMode.monitoring);
      return;
    }

    final started = await stt.startContinuousListening(
      onTranscript: _onTranscript,
    );

    _startingMonitoring = false;

    if (!started) {
      await foregroundService.stop();
      state = state.copyWith(mode: ActiveListeningMode.idle);
      return;
    }

    state = state.copyWith(mode: ActiveListeningMode.monitoring);
  }

  Future<void> _pauseMonitoring() async {
    final stt = _sttService;
    final foregroundService = _foregroundServiceInstance;
    if (stt == null || foregroundService == null) return;
    if (state.mode != ActiveListeningMode.monitoring) return;

    _wakeWordHandledForUtterance = false;
    await stt.stopContinuousListening();
    await foregroundService.stop();
    state = state.copyWith(mode: ActiveListeningMode.paused);
  }

  Future<void> _stopMonitoring() async {
    final stt = _sttService;
    final foregroundService = _foregroundServiceInstance;
    _wakeWordHandledForUtterance = false;
    _startingMonitoring = false;
    if (stt != null) {
      await stt.stopContinuousListening();
    }
    if (foregroundService != null) {
      await foregroundService.stop();
    }
    state = state.copyWith(mode: ActiveListeningMode.idle);
  }

  void _onTranscript(String transcript, bool isFinal) {
    if (state.mode != ActiveListeningMode.monitoring) return;
    if (_wakeWordHandledForUtterance) return;

    final result = _detector.detect(transcript, wakeWord: _currentWakeWord);
    if (!result.detected) return;

    if (result.command.isNotEmpty) {
      _wakeWordHandledForUtterance = true;
      _handleWakeWordDetected(WakeWordDetected(result.command));
      return;
    }

    if (isFinal) {
      _wakeWordHandledForUtterance = true;
      _handleWakeWordDetected(const WakeWordDetected(''));
    }
  }

  Future<void> _handleWakeWordDetected(WakeWordDetected event) async {
    await _pauseMonitoring();
    appRouter.goNamed(AppRoute.assistant.name);

    final assistant = ref.read(assistantControllerProvider.notifier);
    if (event.command.isNotEmpty) {
      await assistant.sendWakeWordCommand(event.command);
    } else {
      await assistant.startWakeWordCommandCapture();
    }
  }
}

final activeListeningControllerProvider =
    NotifierProvider<ActiveListeningController, ActiveListeningState>(
  ActiveListeningController.new,
);
