import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';

class FakeSpeechRecognizer implements SpeechRecognizer {
  FakeSpeechRecognizer({this.available = true});

  bool available;
  bool listening = false;
  void Function(SpeechRecognitionResult result)? onResult;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    return available;
  }

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => listening;

  @override
  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
    ListenMode listenMode = ListenMode.confirmation,
  }) async {
    this.onResult = onResult;
    listening = true;
  }

  @override
  Future<void> stop() async {
    listening = false;
  }

  void emitPartial(String words) {
    onResult?.call(_result(words, finalResult: false));
  }

  void emitFinal(String words) {
    onResult?.call(_result(words, finalResult: true));
  }

  SpeechRecognitionResult _result(String words, {required bool finalResult}) {
    return SpeechRecognitionResult.init(
      [
        SpeechRecognitionWords(
          words,
          null,
          SpeechRecognitionWords.missingConfidence,
        ),
      ],
      finalResult ? ResultType.finalResult : ResultType.partial,
    );
  }
}

class FakeMicrophonePermissionClient implements MicrophonePermissionClient {
  FakeMicrophonePermissionClient(this.status);

  PermissionStatus status;

  @override
  Future<PermissionStatus> request() async => status;
}

void main() {
  group('SpeechToTextService', () {
    test('fake emits partial then final callbacks in order', () async {
      final recognizer = FakeSpeechRecognizer();
      final service = SpeechToTextService(
        recognizer: recognizer,
        permissionClient:
            FakeMicrophonePermissionClient(PermissionStatus.granted),
      );

      final transcripts = <String>[];
      final finals = <String>[];

      final started = await service.startListening(
        onPartial: transcripts.add,
        onFinal: finals.add,
      );
      expect(started, isTrue);

      recognizer.emitPartial('Jar');
      recognizer.emitFinal('Jarvis');

      expect(transcripts, ['Jar']);
      expect(finals, ['Jarvis']);
      expect(service.error, isNull);
    });

    test('permission denied returns false and exposes error state', () async {
      final service = SpeechToTextService(
        recognizer: FakeSpeechRecognizer(),
        permissionClient:
            FakeMicrophonePermissionClient(PermissionStatus.denied),
      );

      final granted = await service.requestMicPermission();

      expect(granted, isFalse);
      expect(service.error, isNotNull);
      expect(service.error!.code, SpeechToTextErrorCode.permissionDenied);
      expect(service.error!.message, isNotEmpty);
    });

    test('unavailable recognizer exposes notAvailable error', () async {
      final service = SpeechToTextService(
        recognizer: FakeSpeechRecognizer(available: false),
        permissionClient:
            FakeMicrophonePermissionClient(PermissionStatus.granted),
      );

      final started = await service.startListening(
        onPartial: (_) {},
        onFinal: (_) {},
      );

      expect(started, isFalse);
      expect(
        service.error?.code,
        anyOf(
          SpeechToTextErrorCode.notAvailable,
          SpeechToTextErrorCode.initializationFailed,
        ),
      );
    });
  });

  test('Android manifest declares microphone permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android.permission.RECORD_AUDIO'));
  });
}
