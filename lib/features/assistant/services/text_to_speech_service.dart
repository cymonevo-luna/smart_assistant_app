import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Abstraction over the platform TTS engine for tests.
abstract class TextToSpeechEngine {
  Future<void> speak(String text);

  Future<void> stop();

  void setCompletionHandler(VoidCallback? handler);
}

class FlutterTtsEngine implements TextToSpeechEngine {
  FlutterTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();

  @override
  void setCompletionHandler(VoidCallback? handler) {
    _tts.setCompletionHandler(handler ?? () {});
  }
}

/// Speaks assistant replies aloud. Web builds skip audio output because TTS is
/// unreliable in browsers.
class TextToSpeechService {
  TextToSpeechService({TextToSpeechEngine? engine})
      : _engine = engine ?? FlutterTtsEngine();

  final TextToSpeechEngine _engine;

  bool get isSupported => !kIsWeb;

  Future<void> speak(String text) async {
    if (!isSupported || text.trim().isEmpty) return;
    await _engine.speak(text);
  }

  Future<void> stop() => _engine.stop();

  void setCompletionHandler(VoidCallback? handler) {
    _engine.setCompletionHandler(handler);
  }
}

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  final service = TextToSpeechService();
  ref.onDispose(service.stop);
  return service;
});
