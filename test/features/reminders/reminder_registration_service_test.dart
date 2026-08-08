import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_reply.dart';
import 'package:smart_assistant_app/features/location/location_service.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/data/location_reminder_repository.dart';
import 'package:smart_assistant_app/features/reminders/location_monitor_service.dart';
import 'package:smart_assistant_app/features/reminders/reminder_registration_service.dart';

import '../../helpers/auth_harness.dart';
import '../location/location_service_test.dart';

class _TrackingLocationMonitorService implements LocationMonitorService {
  int startMonitoringCalls = 0;

  @override
  Future<void> startMonitoring() async {
    startMonitoringCalls++;
  }
}

void main() {
  late PreferencesService prefs;
  late LocationReminderRepository reminderRepository;
  late _TrackingLocationMonitorService monitorService;
  late ReminderRegistrationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
    reminderRepository = LocationReminderRepository(prefs);
    monitorService = _TrackingLocationMonitorService();
    service = ReminderRegistrationService(
      reminderRepository: reminderRepository,
      reminderApiRepository: ReminderApiRepository(
        buildMockedApiClient().client,
      ),
      locationService: LocationService(
        geolocator: FakeGeolocatorPlatform(
          checkPermissionResult: LocationPermission.whileInUse,
        ),
      ),
      locationMonitorService: monitorService,
    );
  });

  Map<String, dynamic> locationReminderPayload({
    String id = 'rem-1',
    String title = 'Buy milk',
    double latitude = 37.7749,
    double longitude = -122.4194,
    int radiusMeters = 150,
  }) {
    return {
      'reminder_id': id,
      'title': title,
      'location_mode': 'exact',
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'status': 'pending',
    };
  }

  test('handleActionResult with success payload creates local reminder', () async {
    await service.handleActionResult(
      AssistantAction(
        pluginSlug: 'set-reminder',
        status: 'success',
        payload: locationReminderPayload(),
      ),
    );

    final pending = await reminderRepository.getAllPending();

    expect(pending, hasLength(1));
    expect(pending.first.id, 'rem-1');
    expect(pending.first.title, 'Buy milk');
    expect(pending.first.latitude, 37.7749);
    expect(pending.first.longitude, -122.4194);
    expect(monitorService.startMonitoringCalls, 1);
  });

  test('calendar action result is ignored', () async {
    await service.handleActionResult(
      AssistantAction(
        pluginSlug: 'google-calendar-meet',
        status: 'success',
        payload: locationReminderPayload(),
      ),
    );

    final pending = await reminderRepository.getAllPending();
    expect(pending, isEmpty);
    expect(monitorService.startMonitoringCalls, 0);
  });

  test('failed action result is ignored', () async {
    await service.handleActionResult(
      AssistantAction(
        pluginSlug: 'set-reminder',
        status: 'failed',
        payload: locationReminderPayload(),
      ),
    );

    final pending = await reminderRepository.getAllPending();
    expect(pending, isEmpty);
    expect(monitorService.startMonitoringCalls, 0);
  });

  test('location-reminder plugin slug is accepted', () async {
    await service.handleActionResult(
      AssistantAction(
        pluginSlug: 'location-reminder',
        status: 'success',
        payload: locationReminderPayload(id: 'rem-2'),
      ),
    );

    final pending = await reminderRepository.getAllPending();
    expect(pending, hasLength(1));
    expect(pending.first.id, 'rem-2');
  });

  test('duplicate reminder_id updates existing row idempotently', () async {
    final action = AssistantAction(
      pluginSlug: 'set-reminder',
      status: 'success',
      payload: locationReminderPayload(title: 'First title'),
    );

    await service.handleActionResult(action);
    await service.handleActionResult(
      action.copyWith(
        payload: locationReminderPayload(title: 'Updated title'),
      ),
    );

    final pending = await reminderRepository.getAllPending();
    expect(pending, hasLength(1));
    expect(pending.first.title, 'Updated title');
  });

  test('permission explanation shown before requesting location access', () async {
    String? explanation;
    final permissionService = ReminderRegistrationService(
      reminderRepository: reminderRepository,
      reminderApiRepository: ReminderApiRepository(
        buildMockedApiClient().client,
      ),
      locationService: LocationService(
        geolocator: FakeGeolocatorPlatform(
          checkPermissionResult: LocationPermission.denied,
          requestPermissionResult: LocationPermission.whileInUse,
        ),
      ),
      locationMonitorService: monitorService,
      onPermissionExplanationNeeded: (message) => explanation = message,
    );

    await permissionService.handleActionResult(
      AssistantAction(
        pluginSlug: 'set-reminder',
        status: 'success',
        payload: locationReminderPayload(),
      ),
    );

    expect(explanation, ReminderRegistrationService.locationPermissionExplanation);
    final pending = await reminderRepository.getAllPending();
    expect(pending, hasLength(1));
  });
}
