import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/assistant/services/wake_word_detector.dart';

void main() {
  final detector = WakeWordDetector();

  test('detects wake word and strips command', () {
    final result = detector.detect(
      'jarvis what time is it',
      wakeWord: 'Jarvis',
    );

    expect(result.detected, isTrue);
    expect(result.command, 'what time is it');
  });

  test('detects wake word in Hey Jarvis phrase', () {
    final result = detector.detect(
      'Hey Jarvis turn on lights',
      wakeWord: 'Jarvis',
    );

    expect(result.detected, isTrue);
    expect(result.command, 'turn on lights');
  });

  test('detects wake word with trailing command', () {
    final result = detector.detect(
      'jarvis schedule meeting',
      wakeWord: 'Jarvis',
    );

    expect(result.detected, isTrue);
    expect(result.command, 'schedule meeting');
  });

  test('does not match similar words without word boundary', () {
    final result = detector.detect(
      'jarvisian hello',
      wakeWord: 'Jarvis',
    );

    expect(result.detected, isFalse);
    expect(result.command, '');
  });

  test('wake word only yields empty command', () {
    final result = detector.detect(
      'Jarvis',
      wakeWord: 'Jarvis',
    );

    expect(result.detected, isTrue);
    expect(result.command, '');
  });

  test('empty wake word never matches', () {
    final result = detector.detect(
      'Jarvis hello',
      wakeWord: '',
    );

    expect(result.detected, isFalse);
  });
}
