import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:smart_assistant_app/features/reminders/data/time_reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/models/reminder.dart';
import 'package:smart_assistant_app/features/reminders/services/local_notifications_client.dart';
import 'package:smart_assistant_app/features/reminders/services/reminder_notification_permission_client.dart';
import 'package:smart_assistant_app/features/reminders/services/reminder_notification_service.dart';

class FakeReminderDataSource implements ReminderDataSource {
  List<Reminder> reminders = const [];
  List<Reminder> pendingNotifications = const [];
  final List<String> deliveredIds = [];

  @override
  Future<List<Reminder>> listReminders({String filter = 'all'}) async {
    return reminders;
  }

  @override
  Future<List<Reminder>> listPendingNotifications() async {
    return pendingNotifications;
  }

  @override
  Future<void> markDelivered(String reminderId) async {
    deliveredIds.add(reminderId);
  }
}

class FakeReminderNotificationPermissionClient
    implements ReminderNotificationPermissionClient {
  FakeReminderNotificationPermissionClient({this.granted = true});

  final bool granted;

  @override
  Future<bool> ensureGranted() async => granted;
}

class FakeLocalNotificationsClient implements LocalNotificationsClient {
  final List<Map<String, Object?>> zonedScheduleCalls = [];
  final List<Map<String, Object?>> showCalls = [];
  final List<int> cancelCalls = [];
  List<PendingNotificationRequest> pendingRequests = const [];

  @override
  Future<void> cancel(int id) async {
    cancelCalls.add(id);
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pendingRequests;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails notificationDetails,
  }) async {
    showCalls.add({
      'id': id,
      'title': title,
      'body': body,
    });
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    zonedScheduleCalls.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'androidScheduleMode': androidScheduleMode,
    });
  }
}

void main() {
  late FakeReminderDataSource repository;
  late FakeLocalNotificationsClient notifications;
  late ReminderNotificationService service;

  setUp(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    repository = FakeReminderDataSource();
    notifications = FakeLocalNotificationsClient();
    service = ReminderNotificationService(
      repository: repository,
      notificationsClient: notifications,
      permissionClient: FakeReminderNotificationPermissionClient(),
      isMobile: true,
      onNotificationTap: () {},
    );
  });

  test('syncReminders schedules one future pending reminder', () async {
    final remindAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
    repository.reminders = [
      Reminder(
        id: '550e8400-e29b-41d4-a716-446655440000',
        message: 'Water the plants',
        remindAt: remindAt,
        status: ReminderStatus.pending,
      ),
    ];

    await service.syncReminders();

    expect(notifications.zonedScheduleCalls, hasLength(1));
    final call = notifications.zonedScheduleCalls.single;
    expect(call['id'], reminderNotificationId(repository.reminders.first.id));
    expect(call['title'], 'Reminder');
    expect(call['body'], 'Water the plants');
    expect(
      call['androidScheduleMode'],
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  });

  test('syncReminders shows and acknowledges pending server notification',
      () async {
    repository.reminders = const [];
    repository.pendingNotifications = [
      Reminder(
        id: 'rem-due-1',
        message: 'Server reminder',
        remindAt: DateTime.utc(2026, 8, 8, 12, 0),
        status: ReminderStatus.notified,
      ),
    ];

    await service.syncReminders();

    expect(notifications.showCalls, hasLength(1));
    expect(notifications.showCalls.single['body'], 'Server reminder');
    expect(repository.deliveredIds, ['rem-due-1']);
  });

  test('syncReminders does not schedule past pending reminder', () async {
    repository.reminders = [
      Reminder(
        id: 'past-rem',
        message: 'Already due',
        remindAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        status: ReminderStatus.pending,
      ),
    ];

    await service.syncReminders();

    expect(notifications.zonedScheduleCalls, isEmpty);
  });

  test('syncReminders does not schedule cancelled reminder', () async {
    repository.reminders = [
      Reminder(
        id: 'cancelled-rem',
        message: 'No longer needed',
        remindAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        status: ReminderStatus.cancelled,
      ),
    ];

    await service.syncReminders();

    expect(notifications.zonedScheduleCalls, isEmpty);
  });

  test('syncReminders cancels stale pending notification request', () async {
    const reminderId = 'stale-rem';
    final notificationId = reminderNotificationId(reminderId);
    notifications.pendingRequests = [
      PendingNotificationRequest(notificationId, 'Reminder', 'Stale body', null),
    ];
    repository.reminders = [
      Reminder(
        id: reminderId,
        message: 'No longer needed',
        remindAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        status: ReminderStatus.cancelled,
      ),
    ];

    await service.syncReminders();

    expect(notifications.cancelCalls, [notificationId]);
    expect(notifications.zonedScheduleCalls, isEmpty);
  });

  test('syncReminders skips sync when permission denied', () async {
    service = ReminderNotificationService(
      repository: repository,
      notificationsClient: notifications,
      permissionClient: FakeReminderNotificationPermissionClient(granted: false),
      isMobile: true,
      onNotificationTap: () {},
    );
    repository.reminders = [
      Reminder(
        id: 'future-rem',
        message: 'Should not schedule',
        remindAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        status: ReminderStatus.pending,
      ),
    ];

    await service.syncReminders();

    expect(notifications.zonedScheduleCalls, isEmpty);
    expect(notifications.showCalls, isEmpty);
  });

  test('scheduleTestNotification schedules a future local notification',
      () async {
    await service.scheduleTestNotification(
      message: 'E2E reminder notification',
      delay: const Duration(seconds: 10),
    );

    expect(notifications.zonedScheduleCalls, hasLength(1));
    final call = notifications.zonedScheduleCalls.single;
    expect(call['title'], 'Reminder');
    expect(call['body'], 'E2E reminder notification');
    expect(
      call['androidScheduleMode'],
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  });
}
