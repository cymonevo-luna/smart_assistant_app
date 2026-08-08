import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'foreground_listening_service_impl.dart';

/// Keeps a foreground notification while the app actively listens for a wake
/// word. Required on Android for sustained microphone access.
abstract class ForegroundListeningService {
  Future<bool> start({required String notificationText});

  Future<void> stop();

  bool get isRunning;
}

class NoOpForegroundListeningService implements ForegroundListeningService {
  @override
  bool get isRunning => false;

  @override
  Future<bool> start({required String notificationText}) async => true;

  @override
  Future<void> stop() async {}
}

final foregroundListeningServiceProvider = Provider<ForegroundListeningService>(
  (ref) => createForegroundListeningService(),
);
