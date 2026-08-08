import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'active_listening_task_handler.dart';
import 'foreground_task_client.dart';

/// Keeps a foreground notification while the app actively listens for a wake
/// word. Required on Android for sustained microphone access.
abstract class ForegroundListeningService {
  Future<bool> start({required String notificationText});

  Future<void> stop();

  bool get isRunning;
}

class PlatformForegroundListeningService implements ForegroundListeningService {
  PlatformForegroundListeningService({
    ForegroundTaskClient? taskClient,
    bool? isAndroid,
  })  : _taskClient = taskClient ?? FlutterForegroundTaskClient(),
        _isAndroid = isAndroid ?? Platform.isAndroid;

  static const _serviceId = 1001;

  final ForegroundTaskClient _taskClient;
  final bool _isAndroid;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<bool> start({required String notificationText}) async {
    if (!_isAndroid) return false;

    if (_running) {
      final updated = await _taskClient.updateService(
        notificationTitle: 'Active listening',
        notificationText: notificationText,
      );
      return updated is ServiceRequestSuccess;
    }

    if (!await _ensureNotificationPermission()) {
      _running = false;
      return false;
    }

    final started = await _taskClient.startService(
      serviceId: _serviceId,
      notificationTitle: 'Active listening',
      notificationText: notificationText,
      callback: startActiveListeningTask,
    );

    _running = started is ServiceRequestSuccess;
    return _running;
  }

  Future<bool> _ensureNotificationPermission() async {
    var permission = await _taskClient.checkNotificationPermission();
    if (permission == NotificationPermission.granted) {
      return true;
    }

    permission = await _taskClient.requestNotificationPermission();
    return permission == NotificationPermission.granted;
  }

  @override
  Future<void> stop() async {
    if (!_isAndroid || !_running) return;
    await _taskClient.stopService();
    _running = false;
  }
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
  (ref) {
    if (Platform.isAndroid) {
      return PlatformForegroundListeningService();
    }
    return NoOpForegroundListeningService();
  },
);
