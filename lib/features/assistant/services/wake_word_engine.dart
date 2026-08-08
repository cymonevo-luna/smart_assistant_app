import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import '../../../core/config/app_config.dart';
import 'davoice_wake_word_engine.dart';

/// Low-power, on-device wake-word detection.
///
/// Unlike running the full speech recognizer continuously, this only runs a
/// tiny acoustic keyword-spotting model — it never transcribes audio or makes
/// a network call, so it is cheap enough to run indefinitely.
abstract class WakeWordEngine {
  /// Starts listening for the wake word. Returns `false` (and populates
  /// [lastError]) if the engine could not start (missing/invalid AccessKey,
  /// no microphone permission, etc).
  Future<bool> start();

  Future<void> stop();

  /// Releases native resources. The engine cannot be restarted afterwards.
  Future<void> dispose();

  bool get isRunning;

  String? get lastError;

  /// Invoked (on the isolate this engine runs in) when the wake word fires.
  set onWakeWord(void Function()? callback);

  /// Invoked when the engine hits a runtime error after starting.
  set onError(void Function(String message)? callback);
}

/// Porcupine-backed implementation. "Jarvis" ships as one of Porcupine's free
/// built-in keywords, so no custom model training/asset bundling is needed —
/// only a Picovoice AccessKey (see https://console.picovoice.ai/).
class PorcupineWakeWordEngine implements WakeWordEngine {
  PorcupineWakeWordEngine({required this._accessKey});

  final String _accessKey;

  PorcupineManager? _manager;
  bool _running = false;
  String? _lastError;

  @override
  bool get isRunning => _running;

  @override
  String? get lastError => _lastError;

  Future<PorcupineManager?> _ensureManager() async {
    if (_manager != null) return _manager;
    if (_accessKey.isEmpty) {
      _lastError = 'Wake word is not configured (missing Picovoice access key).';
      return null;
    }

    try {
      _manager = await PorcupineManager.fromBuiltInKeywords(
        _accessKey,
        [BuiltInKeyword.JARVIS],
        (keywordIndex) => onWakeWord?.call(),
        errorCallback: (error) {
          _lastError = error.message ?? 'Wake word engine error.';
          onError?.call(_lastError!);
        },
      );
      _lastError = null;
      return _manager;
    } on PorcupineException catch (e) {
      _lastError = e.message ?? 'Could not initialize wake word detection.';
      return null;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  /// Invoked (on the isolate this engine runs in) when the wake word fires.
  void Function()? onWakeWord;

  /// Invoked when the engine hits a runtime error after starting.
  void Function(String message)? onError;

  @override
  Future<bool> start() async {
    if (_running) return true;

    final manager = await _ensureManager();
    if (manager == null) return false;

    try {
      await manager.start();
      _running = true;
      return true;
    } on PorcupineException catch (e) {
      _lastError = e.message ?? 'Could not start wake word detection.';
      return false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    try {
      await _manager?.stop();
    } on PorcupineException catch (e) {
      _lastError = e.message;
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _manager?.delete();
    _manager = null;
  }
}

/// Builds the [WakeWordEngine] selected by [AppConfig.wakeWordEngine],
/// falling back to [NoOpWakeWordEngine] when its required config is missing.
/// Single call site for both the Android background isolate
/// ([ActiveListeningTaskHandler]) and the iOS foreground path
/// ([ActiveListeningController]) so they never hardcode a specific engine.
WakeWordEngine createWakeWordEngine() {
  if (!AppConfig.wakeWordEngineConfigured) {
    return NoOpWakeWordEngine();
  }
  return switch (AppConfig.wakeWordEngine) {
    WakeWordEngineKind.picovoice =>
      PorcupineWakeWordEngine(accessKey: AppConfig.picovoiceAccessKey),
    WakeWordEngineKind.davoice => DaVoiceWakeWordEngine(
        licenseKey: AppConfig.daVoiceLicenseKey,
        threshold: AppConfig.daVoiceWakeWordThreshold,
      ),
  };
}

/// No-op engine for platforms/tests where wake-word detection is unavailable.
class NoOpWakeWordEngine implements WakeWordEngine {
  @override
  bool get isRunning => false;

  @override
  String? get lastError => null;

  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  @override
  set onWakeWord(void Function()? callback) {}

  @override
  set onError(void Function(String message)? callback) {}
}
