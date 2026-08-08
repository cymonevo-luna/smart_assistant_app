import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstraction for requesting notification permission before scheduling.
abstract class ReminderNotificationPermissionClient {
  Future<bool> ensureGranted();
}

class PlatformReminderNotificationPermissionClient
    implements ReminderNotificationPermissionClient {
  PlatformReminderNotificationPermissionClient({
    bool? isAndroid,
    bool? isIOS,
  })  : _isAndroid = isAndroid ?? Platform.isAndroid,
        _isIOS = isIOS ?? Platform.isIOS;

  final bool _isAndroid;
  final bool _isIOS;

  @override
  Future<bool> ensureGranted() async {
    if (_isAndroid) {
      var permission = await FlutterForegroundTask.checkNotificationPermission();
      if (permission == NotificationPermission.granted) {
        return true;
      }
      permission = await FlutterForegroundTask.requestNotificationPermission();
      return permission == NotificationPermission.granted;
    }

    if (_isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted || status.isLimited;
    }

    return true;
  }
}
