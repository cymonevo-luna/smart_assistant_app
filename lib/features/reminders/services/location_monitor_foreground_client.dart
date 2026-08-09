import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../assistant/services/foreground_task_client.dart';
import 'location_monitor_task_handler.dart';

/// Keeps a location foreground service alive on Android while proximity
/// monitoring runs in the background.
abstract class LocationMonitorForegroundClient {
  Future<void> start();

  Future<void> stop();
}

class NoOpLocationMonitorForegroundClient
    implements LocationMonitorForegroundClient {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class AndroidLocationMonitorForegroundClient
    implements LocationMonitorForegroundClient {
  AndroidLocationMonitorForegroundClient({
    ForegroundTaskClient? taskClient,
    Future<bool> Function()? isServiceRunning,
  })  : _taskClient = taskClient ?? FlutterForegroundTaskClient(),
        _isServiceRunning = isServiceRunning ?? _defaultIsServiceRunning;

  static const _serviceId = 1002;

  final ForegroundTaskClient _taskClient;
  final Future<bool> Function() _isServiceRunning;
  bool _weStartedForeground = false;

  static Future<bool> _defaultIsServiceRunning() {
    return FlutterForegroundTask.isRunningService;
  }

  @override
  Future<void> start() async {
    if (await _isServiceRunning()) {
      return;
    }

    if (!await _ensureNotificationPermission()) {
      return;
    }

    final started = await _taskClient.startService(
      serviceId: _serviceId,
      notificationTitle: 'Location reminders',
      notificationText: 'Monitoring your location for reminders',
      callback: startLocationMonitorTask,
    );

    _weStartedForeground = started is ServiceRequestSuccess;
  }

  @override
  Future<void> stop() async {
    if (!_weStartedForeground) {
      return;
    }

    await _taskClient.stopService();
    _weStartedForeground = false;
  }

  Future<bool> _ensureNotificationPermission() async {
    var permission = await _taskClient.checkNotificationPermission();
    if (permission == NotificationPermission.granted) {
      return true;
    }

    permission = await _taskClient.requestNotificationPermission();
    return permission == NotificationPermission.granted;
  }
}
