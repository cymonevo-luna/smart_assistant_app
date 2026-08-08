import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../data/reminder_repository.dart';
import '../models/reminder.dart';
import 'local_notifications_client.dart';
import 'reminder_notification_permission_client.dart';

const _notificationTitle = 'Reminder';
const _androidChannelId = 'reminders';
const _androidChannelName = 'Reminders';
const _androidChannelDescription =
    'Local reminders synced from your Smart Assistant account.';

/// Syncs reminder notifications from the API and schedules local alerts.
class ReminderNotificationService {
  ReminderNotificationService({
    required this._repository,
    LocalNotificationsClient? notificationsClient,
    ReminderNotificationPermissionClient? permissionClient,
    bool? isMobile,
    void Function()? onNotificationTap,
  })  : _notifications =
            notificationsClient ?? FlutterLocalNotificationsClient(),
        _permissionClient = permissionClient ??
            PlatformReminderNotificationPermissionClient(),
        _isMobile = isMobile ?? (Platform.isAndroid || Platform.isIOS),
        _onNotificationTap = onNotificationTap ?? _defaultNotificationTap;

  final ReminderDataSource _repository;
  final LocalNotificationsClient _notifications;
  final ReminderNotificationPermissionClient _permissionClient;
  final bool _isMobile;
  final void Function() _onNotificationTap;

  bool _initialized = false;
  final Set<int> _shownThisSession = <int>{};

  static void _defaultNotificationTap() {
    appRouter.goNamed(AppRoute.assistant.name);
  }

  Future<void> initialize() async {
    if (!_isMobile || _initialized) return;

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _onNotificationTap(),
    );

    if (Platform.isAndroid) {
      final client = _notifications;
      if (client is FlutterLocalNotificationsClient) {
        final androidPlugin = client.plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            description: _androidChannelDescription,
            importance: Importance.high,
          ),
        );
      }
    }

    _initialized = true;
  }

  Future<void> syncReminders() async {
    if (!_isMobile) return;

    await initialize();
    if (!await _permissionClient.ensureGranted()) return;

    try {
      final reminders = await _repository.listReminders();
      await _syncScheduledReminders(reminders);
      await _syncPendingServerNotifications();
    } on ApiException {
      // Ignore sync failures; the next lifecycle event will retry.
    }
  }

  Future<void> _syncScheduledReminders(List<Reminder> reminders) async {
    final now = DateTime.now();
    final pendingReminders = reminders.where(
      (reminder) => reminder.status == ReminderStatus.pending,
    );
    final desiredIds = <int>{};

    for (final reminder in pendingReminders) {
      final notificationId = reminderNotificationId(reminder.id);
      desiredIds.add(notificationId);

      if (!reminder.remindAt.isAfter(now)) {
        continue;
      }

      await _notifications.zonedSchedule(
        id: notificationId,
        title: _notificationTitle,
        body: reminder.message,
        scheduledDate: tz.TZDateTime.from(reminder.remindAt, tz.local),
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final pendingRequests = await _notifications.pendingNotificationRequests();
    for (final request in pendingRequests) {
      if (!desiredIds.contains(request.id)) {
        await _notifications.cancel(request.id);
      }
    }
  }

  Future<void> _syncPendingServerNotifications() async {
    final pending = await _repository.listPendingNotifications();

    for (final reminder in pending) {
      final notificationId = reminderNotificationId(reminder.id);
      if (_shownThisSession.contains(notificationId)) {
        continue;
      }

      await _notifications.show(
        id: notificationId,
        title: _notificationTitle,
        body: reminder.message,
        notificationDetails: _notificationDetails(),
      );
      _shownThisSession.add(notificationId);
      await _repository.markDelivered(reminder.id);
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Visible for tests to reset session-scoped delivery tracking.
  void clearShownThisSession() => _shownThisSession.clear();
}
