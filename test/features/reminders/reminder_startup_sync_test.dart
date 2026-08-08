import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/location/location_service.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/data/location_reminder_repository.dart';
import 'package:smart_assistant_app/features/reminders/location_monitor_service.dart';
import 'package:smart_assistant_app/features/reminders/reminder_registration_service.dart';

import '../../helpers/auth_harness.dart';

void main() {
  late DioAdapter adapter;
  late LocationReminderRepository reminderRepository;
  late ReminderRegistrationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    reminderRepository = LocationReminderRepository(prefs);

    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<LocationService>(LocationService())
      ..registerSingleton<LocationReminderRepository>(reminderRepository)
      ..registerSingleton<ReminderApiRepository>(
        ReminderApiRepository(mocked.client),
      )
      ..registerSingleton<LocationMonitorService>(StubLocationMonitorService())
      ..registerSingleton<ReminderRegistrationService>(
        ReminderRegistrationService(
          reminderRepository: reminderRepository,
          reminderApiRepository: ReminderApiRepository(mocked.client),
          locationService: locator(),
          locationMonitorService: locator(),
        ),
      );

    service = locator<ReminderRegistrationService>();
  });

  test('syncPendingFromApi stores pending reminders locally', () async {
    adapter.onGet(
      '/api/v1/reminders',
      (server) => server.reply(200, {
        'success': true,
        'data': [
          {
            'reminder_id': 'api-rem-1',
            'title': 'Pick up dry cleaning',
            'location_mode': 'exact',
            'latitude': 40.7128,
            'longitude': -74.0060,
            'radius_meters': 100,
            'status': 'pending',
          },
        ],
      }),
      queryParameters: {'status': 'pending'},
    );

    await service.syncPendingFromApi();

    final pending = await reminderRepository.getAllPending();
    expect(pending, hasLength(1));
    expect(pending.first.id, 'api-rem-1');
    expect(pending.first.title, 'Pick up dry cleaning');
    expect(pending.first.latitude, 40.7128);
    expect(pending.first.longitude, -74.0060);
  });
}
