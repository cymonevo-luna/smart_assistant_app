import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Structured error surfaced to the UI when speech capture cannot proceed.
class SpeechToTextError {
  const SpeechToTextError({
    required this.code,
    required this.message,
  });

  final SpeechToTextErrorCode code;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeechToTextError &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}

enum SpeechToTextErrorCode {
  permissionDenied,
  notAvailable,
  initializationFailed,
  listenFailed,
}

/// Abstraction over [Permission.microphone] so tests can stub permission flow.
abstract class MicrophonePermissionClient {
  Future<PermissionStatus> request();
}

class PlatformMicrophonePermissionClient implements MicrophonePermissionClient {
  @override
  Future<PermissionStatus> request() => Permission.microphone.request();
}

/// Abstraction over the device speech recognizer for unit tests.
abstract class SpeechRecognizer {
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  });

  bool get isAvailable;

  bool get isListening;

  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
  });

  Future<void> stop();
}

class PlatformSpeechRecognizer implements SpeechRecognizer {
  PlatformSpeechRecognizer({SpeechToText? speechToText})
      : _speech = speechToText ?? SpeechToText();

  final SpeechToText _speech;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) {
    return _speech.initialize(
      onStatus: onStatus,
      onError: onError,
    );
  }

  @override
  bool get isAvailable => _speech.isAvailable;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
  }) {
    return _speech.listen(
      onResult: onResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}

/// On-device speech capture and transcription. Sends text only to callers;
/// no network I/O is performed in this module.
class SpeechToTextService {
  SpeechToTextService({
    SpeechRecognizer? recognizer,
    MicrophonePermissionClient? permissionClient,
  })  : _recognizer = recognizer ?? PlatformSpeechRecognizer(),
        _permissionClient =
            permissionClient ?? PlatformMicrophonePermissionClient();

  final SpeechRecognizer _recognizer;
  final MicrophonePermissionClient _permissionClient;

  Future<void>? _initialization;
  bool _initialized = false;
  SpeechToTextError? _error;

  /// Last structured error, if any. Cleared on successful operations.
  SpeechToTextError? get error => _error;

  /// Whether the device speech recognizer reports availability.
  bool get isAvailable => _recognizer.isAvailable;

  /// Lazily initializes the STT engine on first use.
  Future<void> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _error = null;
    final ready = await _recognizer.initialize(
      onError: (error) {
        _error = SpeechToTextError(
          code: SpeechToTextErrorCode.listenFailed,
          message: error.toString(),
        );
      },
    );
    _initialized = ready;
    if (!ready) {
      _error = const SpeechToTextError(
        code: SpeechToTextErrorCode.initializationFailed,
        message: 'Speech recognition is not available on this device.',
      );
    }
  }

  /// Requests microphone permission. Returns `true` when granted.
  Future<bool> requestMicPermission() async {
    _error = null;
    final status = await _permissionClient.request();
    if (status.isGranted) return true;

    _error = const SpeechToTextError(
      code: SpeechToTextErrorCode.permissionDenied,
      message: 'Microphone permission is required for voice input.',
    );
    return false;
  }

  /// Starts listening and forwards partial then final transcript strings.
  Future<bool> startListening({
    required void Function(String transcript) onPartial,
    required void Function(String transcript) onFinal,
  }) async {
    _error = null;

    if (!_initialized) {
      await ensureInitialized();
    }
    if (!_initialized) {
      return false;
    }
    if (!_recognizer.isAvailable) {
      _error = const SpeechToTextError(
        code: SpeechToTextErrorCode.notAvailable,
        message: 'Speech recognition is not available on this device.',
      );
      return false;
    }

    final granted = await requestMicPermission();
    if (!granted) return false;

    try {
      await _recognizer.listen(
        onResult: (result) {
          if (result.finalResult) {
            onFinal(result.recognizedWords);
          } else {
            onPartial(result.recognizedWords);
          }
        },
      );
      return true;
    } catch (e) {
      _error = SpeechToTextError(
        code: SpeechToTextErrorCode.listenFailed,
        message: e.toString(),
      );
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_recognizer.isListening) {
      await _recognizer.stop();
    }
  }
}

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  final service = SpeechToTextService();
  ref.onDispose(service.stopListening);
  return service;
});

/// Lazily warms up the on-device STT engine when the app starts.
final speechToTextInitializationProvider = FutureProvider<void>((ref) {
  return ref.read(speechToTextServiceProvider).ensureInitialized();
});
