/// Result of scanning a transcript for a configured wake word.
class WakeWordDetectionResult {
  const WakeWordDetectionResult({
    required this.detected,
    required this.command,
  });

  final bool detected;
  final String command;
}

/// Emitted when the wake word is recognized in a transcript.
class WakeWordDetected {
  const WakeWordDetected(this.command);

  /// Command text after the wake word, empty when only the wake word was spoken.
  final String command;
}

/// Transcript-based wake word detection with case-insensitive word-boundary
/// matching.
class WakeWordDetector {
  WakeWordDetectionResult detect(
    String transcript, {
    required String wakeWord,
  }) {
    final keyword = wakeWord.trim();
    if (keyword.isEmpty || transcript.trim().isEmpty) {
      return const WakeWordDetectionResult(detected: false, command: '');
    }

    final pattern = RegExp(
      '\\b${RegExp.escape(keyword)}\\b',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(transcript);
    if (match == null) {
      return const WakeWordDetectionResult(detected: false, command: '');
    }

    final command = transcript.substring(match.end).trim();
    return WakeWordDetectionResult(detected: true, command: command);
  }
}
