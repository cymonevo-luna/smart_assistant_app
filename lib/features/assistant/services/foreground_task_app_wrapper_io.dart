import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Widget wrapWithForegroundTask({required Widget child}) {
  return WithForegroundTask(child: child);
}
