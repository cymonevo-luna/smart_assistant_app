import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void attachForegroundTaskDataCallback(void Function(Object) callback) {
  FlutterForegroundTask.addTaskDataCallback(callback);
}

void detachForegroundTaskDataCallback(void Function(Object) callback) {
  FlutterForegroundTask.removeTaskDataCallback(callback);
}

void launchAppFromForegroundTask() {
  FlutterForegroundTask.launchApp();
}
