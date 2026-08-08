import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Abstraction over [FlutterForegroundTask] for foreground listening startup.
abstract class ForegroundTaskClient {
  Future<NotificationPermission> checkNotificationPermission();

  Future<NotificationPermission> requestNotificationPermission();

  Future<ServiceRequestResult> startService({
    required int serviceId,
    required String notificationTitle,
    required String notificationText,
    required Function callback,
  });

  Future<ServiceRequestResult> updateService({
    required String notificationTitle,
    required String notificationText,
  });

  Future<ServiceRequestResult> stopService();
}

class FlutterForegroundTaskClient implements ForegroundTaskClient {
  @override
  Future<NotificationPermission> checkNotificationPermission() =>
      FlutterForegroundTask.checkNotificationPermission();

  @override
  Future<NotificationPermission> requestNotificationPermission() =>
      FlutterForegroundTask.requestNotificationPermission();

  @override
  Future<ServiceRequestResult> startService({
    required int serviceId,
    required String notificationTitle,
    required String notificationText,
    required Function callback,
  }) =>
      FlutterForegroundTask.startService(
        serviceId: serviceId,
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        callback: callback,
      );

  @override
  Future<ServiceRequestResult> updateService({
    required String notificationTitle,
    required String notificationText,
  }) =>
      FlutterForegroundTask.updateService(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
      );

  @override
  Future<ServiceRequestResult> stopService() =>
      FlutterForegroundTask.stopService();
}
