import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'active_listening_task_handler.dart';
import 'foreground_listening_service.dart';
import 'foreground_task_client.dart';

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

ForegroundListeningService createForegroundListeningService() {
  if (Platform.isAndroid) {
    return PlatformForegroundListeningService();
  }
  return NoOpForegroundListeningService();
}
