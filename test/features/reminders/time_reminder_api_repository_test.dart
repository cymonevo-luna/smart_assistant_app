import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/reminders/data/time_reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/models/reminder.dart';

import '../../helpers/auth_harness.dart';

void main() {
  late DioAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<TimeReminderApiRepository>(
        TimeReminderApiRepository(mocked.client),
      );
  });

  test('listReminders parses reminder JSON with remind_at DateTime', () async {
    adapter.onGet(
      TimeReminderApiRepository.remindersPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [
          {
            'id': 'rem-1',
            'message': 'Take medicine',
            'remind_at': '2026-08-08T15:30:00.000Z',
            'status': 'pending',
          },
        ],
      }),
      queryParameters: {'filter': 'all'},
    );

    final reminders = await locator<TimeReminderApiRepository>().listReminders();

    expect(reminders, hasLength(1));
    expect(reminders.first.id, 'rem-1');
    expect(reminders.first.message, 'Take medicine');
    expect(reminders.first.status, ReminderStatus.pending);
    expect(reminders.first.remindAt.toUtc(), DateTime.utc(2026, 8, 8, 15, 30));
  });

  test('reminderNotificationId is stable for the same UUID', () {
    const id = '550e8400-e29b-41d4-a716-446655440000';

    expect(reminderNotificationId(id), reminderNotificationId(id));
    expect(reminderNotificationId(id), isPositive);
  });

  test('markDelivered posts to delivered endpoint', () async {
    adapter.onPost(
      '${TimeReminderApiRepository.remindersPath}/rem-1/delivered',
      (server) => server.reply(200, {'success': true}),
    );

    await locator<TimeReminderApiRepository>().markDelivered('rem-1');

    expect(adapter.history.where((h) => h.request.method?.name == 'POST'), isNotEmpty);
  });
}
