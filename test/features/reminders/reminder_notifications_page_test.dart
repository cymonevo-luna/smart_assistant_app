import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/features/reminders/data/time_reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/models/reminder.dart';
import 'package:smart_assistant_app/features/reminders/pages/reminder_notifications_page.dart';
import 'package:smart_assistant_app/features/reminders/services/local_notifications_client.dart';
import 'package:smart_assistant_app/features/reminders/services/reminder_notification_permission_client.dart';
import 'package:smart_assistant_app/features/reminders/services/reminder_notification_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

class _FakeReminderDataSource implements ReminderDataSource {
  @override
  Future<List<Reminder>> listReminders({String filter = 'all'}) async => [];

  @override
  Future<List<Reminder>> listPendingNotifications() async => [];

  @override
  Future<void> markDelivered(String reminderId) async {}
}

class _FakePermissionClient implements ReminderNotificationPermissionClient {
  @override
  Future<bool> ensureGranted() async => true;
}

class _FakeNotificationsClient implements LocalNotificationsClient {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return [];
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails notificationDetails,
  }) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
  }) async {}
}

Widget _materialApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    locator.registerSingleton<ReminderNotificationService>(
      ReminderNotificationService(
        repository: _FakeReminderDataSource(),
        notificationsClient: _FakeNotificationsClient(),
        permissionClient: _FakePermissionClient(),
        isMobile: true,
        onNotificationTap: () {},
      ),
    );
  });

  testWidgets('renders title, description, and permission button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: _materialApp(const ReminderNotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reminder notifications'), findsOneWidget);
    expect(
      find.textContaining('Reminder notifications are enabled'),
      findsOneWidget,
    );
    expect(find.text('Check notification permission'), findsOneWidget);
  });
}
