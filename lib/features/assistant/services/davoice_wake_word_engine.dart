import 'dart:async';

import 'package:flutter_wake_word/KeyWordFlutterPC.dart';

import 'wake_word_engine.dart';

/// DaVoice-backed implementation (flutter_wake_word).
///
/// Unlike Porcupine, DaVoice has no free built-in "Jarvis" keyword — it
/// requires a custom-trained `.onnx` model (see
/// assets/wake_word/README.md) plus a license key from
/// https://davoice.io/ (email info@davoice.io; no self-serve trainer as of
/// writing).
///
/// Wired against [KeyWordFlutterPC] rather than the package's top-level
/// `FlutterWakeWord` facade: as of flutter_wake_word 0.0.44 (pre-1.0),
/// `FlutterWakeWord.onKeywordDetectionEvent()` is an unimplemented stub —
/// only the per-instance API actually streams detection events.
class DaVoiceWakeWordEngine implements WakeWordEngine {
  DaVoiceWakeWordEngine({
    required this._licenseKey,
    required this._threshold,
    this.modelAssetPath = 'assets/wake_word/jarvis.onnx',
    this.instanceId = 'active_listening',
  });

  final String _licenseKey;
  final double _threshold;
  final String modelAssetPath;
  final String instanceId;

  KeyWordFlutterPC? _detector;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _running = false;
  String? _lastError;

  @override
  bool get isRunning => _running;

  @override
  String? get lastError => _lastError;

  /// Invoked (on the isolate this engine runs in) when the wake word fires.
  void Function()? onWakeWord;

  /// Invoked when the engine hits a runtime error after starting.
  void Function(String message)? onError;

  Future<KeyWordFlutterPC?> _ensureDetector() async {
    if (_detector != null) return _detector;
    if (_licenseKey.isEmpty) {
      _lastError = 'Wake word is not configured (missing DaVoice license key).';
      return null;
    }

    try {
      final detector = createKeyWordFlutterPCInstance(instanceId);
      await detector.setKeywordDetectionLicense(_licenseKey);
      await detector.createInstance(modelAssetPath, _threshold, 3);
      _detector = detector;
      _lastError = null;
      return detector;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  @override
  Future<bool> start() async {
    if (_running) return true;

    final detector = await _ensureDetector();
    if (detector == null) return false;

    try {
      _subscription = detector.onKeywordDetectionEvent().listen(
        (event) => onWakeWord?.call(),
        onError: (Object error) {
          _lastError = error.toString();
          onError?.call(_lastError!);
        },
      );
      final started = await detector.startKeywordDetection(instanceId, _threshold);
      if (!started) {
        _lastError = 'Could not start wake word detection.';
        await _subscription?.cancel();
        _subscription = null;
        return false;
      }
      _running = true;
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _detector?.stopKeywordDetection(instanceId);
    } catch (e) {
      _lastError = e.toString();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    try {
      await _detector?.destroyInstance();
    } catch (_) {
      // Best-effort cleanup; nothing more to do if the native side is
      // already gone.
    }
    _detector = null;
  }
}
