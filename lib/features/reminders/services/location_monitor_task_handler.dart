import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point for the Android foreground service that keeps location
/// monitoring alive while the app is backgrounded.
@pragma('vm:entry-point')
void startLocationMonitorTask() {
  FlutterForegroundTask.setTaskHandler(LocationMonitorTaskHandler());
}

/// No-op handler: location updates are driven by [LocationService] in the
/// main isolate; this task only satisfies Android foreground-service rules.
class LocationMonitorTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
