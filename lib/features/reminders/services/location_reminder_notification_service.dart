import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows on-device notifications when a location reminder triggers.
///
/// Uses the `location_reminders` channel, distinct from the `reminders`
/// channel used by [ReminderNotificationService] for time-based reminders.
class LocationReminderNotificationService {
  LocationReminderNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    Future<bool> Function()? ensureNotificationPermission,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _ensureNotificationPermission = ensureNotificationPermission ??
            _defaultEnsureNotificationPermission;

  static const channelId = 'location_reminders';
  static const channelName = 'Location Reminders';
  static const channelDescription =
      'Shown when a location reminder triggers.';

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<bool> Function() _ensureNotificationPermission;
  void Function(String reminderId)? _onNotificationTapped;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  /// Registers a callback invoked when the user taps a reminder notification.
  /// The payload is the reminder id passed to [showReminderNotification].
  void registerTapHandler(void Function(String reminderId) handler) {
    _onNotificationTapped = handler;
  }

  Future<void> showReminderNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    await _ensureNotificationPermission();

    final notificationId = id.hashCode & 0x7FFFFFFF;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: id,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _onNotificationTapped?.call(payload);
  }

  static Future<bool> _defaultEnsureNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    var permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission == NotificationPermission.granted) {
      return true;
    }

    permission = await FlutterForegroundTask.requestNotificationPermission();
    return permission == NotificationPermission.granted;
  }
}
