import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'active_listening_task_handler.dart';

/// Keeps a foreground notification while the app actively listens for a wake
/// word. Required on Android for sustained microphone access.
abstract class ForegroundListeningService {
  Future<void> start({required String notificationText});

  Future<void> stop();

  bool get isRunning;
}

class PlatformForegroundListeningService implements ForegroundListeningService {
  static const _serviceId = 1001;

  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start({required String notificationText}) async {
    if (!Platform.isAndroid) return;
    if (_running) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Active listening',
        notificationText: notificationText,
      );
      return;
    }

    final started = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'Active listening',
      notificationText: notificationText,
      callback: startActiveListeningTask,
    );
    _running = started is ServiceRequestSuccess;
  }

  @override
  Future<void> stop() async {
    if (!Platform.isAndroid || !_running) return;
    await FlutterForegroundTask.stopService();
    _running = false;
  }
}

class NoOpForegroundListeningService implements ForegroundListeningService {
  @override
  bool get isRunning => false;

  @override
  Future<void> start({required String notificationText}) async {}

  @override
  Future<void> stop() async {}
}

final foregroundListeningServiceProvider = Provider<ForegroundListeningService>(
  (ref) {
    if (Platform.isAndroid) {
      return PlatformForegroundListeningService();
    }
    return NoOpForegroundListeningService();
  },
);
