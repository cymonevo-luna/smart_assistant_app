import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/location/location_service.dart';
import 'package:smart_assistant_app/features/places/data/places_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/data/location_reminder_repository.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/models/location_reminder.dart';
import 'package:smart_assistant_app/features/reminders/services/location_monitor_foreground_client.dart';
import 'package:smart_assistant_app/features/reminders/services/location_monitor_service.dart';
import 'package:smart_assistant_app/features/reminders/services/location_reminder_notification_service.dart';

import '../location/location_service_test.dart';

class _TrackingGeolocatorPlatform extends FakeGeolocatorPlatform {
  _TrackingGeolocatorPlatform({
    super.checkPermissionResult,
    super.positionStream,
  });

  int positionStreamCallCount = 0;

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    positionStreamCallCount++;
    return super.getPositionStream(locationSettings: locationSettings);
  }
}

class _RecordingNotificationService extends LocationReminderNotificationService {
  _RecordingNotificationService()
      : super(ensureNotificationPermission: () async => true);

  final List<({String id, String title, String body})> shown = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showReminderNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    shown.add((id: id, title: title, body: body));
  }
}

Position _positionAt({
  required double latitude,
  required double longitude,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026, 1, 1),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

const _baseLat = -6.1751;
const _baseLng = 106.8650;

double _offsetLatitudeMeters(double meters) => _baseLat + (meters / 111320);

void main() {
  late PreferencesService prefs;
  late LocationReminderRepository reminderRepository;
  late _RecordingNotificationService notificationService;
  late StreamController<Position> positionController;
  late _TrackingGeolocatorPlatform geolocator;
  late LocationService locationService;
  late ApiClient apiClient;
  late DioAdapter apiAdapter;
  late ReminderApiRepository reminderApiRepository;
  late PlacesApiRepository placesApiRepository;
  late LocationProximityMonitorService monitor;

  Future<void> pumpPosition(Position position) async {
    positionController.add(position);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
    reminderRepository = LocationReminderRepository(prefs);
    notificationService = _RecordingNotificationService();
    positionController = StreamController<Position>.broadcast();
    geolocator = _TrackingGeolocatorPlatform(
      checkPermissionResult: LocationPermission.whileInUse,
      positionStream: positionController.stream,
    );
    locationService = LocationService(geolocator: geolocator);
    apiClient = ApiClient(baseUrl: 'https://api.test');
    apiAdapter = DioAdapter(dio: apiClient.raw);
    reminderApiRepository = ReminderApiRepository(apiClient);
    placesApiRepository = PlacesApiRepository(apiClient);
    monitor = LocationProximityMonitorService(
      reminderRepository: reminderRepository,
      reminderApiRepository: reminderApiRepository,
      placesApiRepository: placesApiRepository,
      locationService: locationService,
      notificationService: notificationService,
      foregroundClient: NoOpLocationMonitorForegroundClient(),
      positionInterval: const Duration(milliseconds: 1),
      placesCacheTtl: const Duration(seconds: 60),
    );
  });

  tearDown(() async {
    await positionController.close();
  });

  Future<void> saveExactReminder({
    String id = 'rem-exact',
    int radiusMeters = 100,
  }) async {
    await reminderRepository.save(
      LocationReminder(
        id: id,
        title: 'Buy groceries',
        locationMode: LocationMode.exact,
        latitude: _baseLat,
        longitude: _baseLng,
        radiusMeters: radiusMeters,
      ),
    );
  }

  group('LocationProximityMonitorService', () {
    test('exact mode triggers within radius', () async {
      apiAdapter.onPatch(
        '/api/v1/reminders/rem-exact/triggered',
        (server) => server.reply(200, {'data': null}),
      );

      await saveExactReminder();
      await monitor.startMonitoring();

      expect(monitor.isMonitoring, isTrue);
      await pumpPosition(
        _positionAt(
          latitude: _offsetLatitudeMeters(50),
          longitude: _baseLng,
        ),
      );

      expect(notificationService.shown, hasLength(1));
      expect(notificationService.shown.first.title, 'Buy groceries');
      expect(notificationService.shown.first.body,
          "You're near your reminder location");

      final stored = await reminderRepository.getById('rem-exact');
      expect(stored?.status, ReminderStatus.triggered);
    });

    test('exact mode does not trigger outside radius', () async {
      await saveExactReminder();
      await monitor.startMonitoring();

      await pumpPosition(
        _positionAt(
          latitude: _offsetLatitudeMeters(500),
          longitude: _baseLng,
        ),
      );

      expect(notificationService.shown, isEmpty);
      final stored = await reminderRepository.getById('rem-exact');
      expect(stored?.status, ReminderStatus.pending);
    });

    test('place keyword mode triggers on nearby match', () async {
      const userLat = _baseLat;
      const userLng = _baseLng;
      final storeLat = _offsetLatitudeMeters(30);
      const storeLng = _baseLng;

      await reminderRepository.save(
        const LocationReminder(
          id: 'rem-place',
          title: 'Stop at Alfamart',
          locationMode: LocationMode.placeKeyword,
          placeKeyword: 'Alfamart',
          radiusMeters: 50,
        ),
      );

      apiAdapter.onGet(
        PlacesApiRepository.nearbyPath,
        (server) => server.reply(200, {
          'data': [
            {
              'name': 'Alfamart',
              'latitude': storeLat,
              'longitude': storeLng,
            },
          ],
        }),
        queryParameters: {
          'keyword': 'Alfamart',
          'latitude': userLat,
          'longitude': userLng,
          'radius_meters': 250,
        },
      );
      apiAdapter.onPatch(
        '/api/v1/reminders/rem-place/triggered',
        (server) => server.reply(200, {'data': null}),
      );

      await monitor.startMonitoring();
      await pumpPosition(
        _positionAt(latitude: userLat, longitude: userLng),
      );

      expect(notificationService.shown, hasLength(1));
      expect(notificationService.shown.first.title, 'Stop at Alfamart');
    });

    test('does not fire duplicate notifications', () async {
      apiAdapter.onPatch(
        '/api/v1/reminders/rem-exact/triggered',
        (server) => server.reply(200, {'data': null}),
      );

      await saveExactReminder();
      await monitor.startMonitoring();

      final inside = _positionAt(
        latitude: _offsetLatitudeMeters(50),
        longitude: _baseLng,
      );
      await pumpPosition(inside);
      await pumpPosition(inside);
      await pumpPosition(inside);

      expect(notificationService.shown, hasLength(1));
    });

    test('monitor idle with no reminders', () async {
      await monitor.startMonitoring();

      expect(monitor.isMonitoring, isFalse);
      expect(geolocator.positionStreamCallCount, 0);
    });

    test('already-triggered reminders are not re-fired', () async {
      await saveExactReminder();
      await reminderRepository.markTriggered('rem-exact');

      await monitor.startMonitoring();

      expect(monitor.isMonitoring, isFalse);
      expect(geolocator.positionStreamCallCount, 0);

      await pumpPosition(
        _positionAt(
          latitude: _offsetLatitudeMeters(10),
          longitude: _baseLng,
        ),
      );

      expect(notificationService.shown, isEmpty);
    });

    test('uses per-reminder radius_meters not a live settings override', () async {
      apiAdapter.onPatch(
        '/api/v1/reminders/rem-tight/triggered',
        (server) => server.reply(200, {'data': null}),
      );

      await reminderRepository.save(
        LocationReminder(
          id: 'rem-tight',
          title: 'Tight radius',
          locationMode: LocationMode.exact,
          latitude: _baseLat,
          longitude: _baseLng,
          radiusMeters: 30,
        ),
      );

      await monitor.startMonitoring();

      await pumpPosition(
        _positionAt(
          latitude: _offsetLatitudeMeters(40),
          longitude: _baseLng,
        ),
      );
      expect(notificationService.shown, isEmpty);

      await pumpPosition(
        _positionAt(
          latitude: _offsetLatitudeMeters(20),
          longitude: _baseLng,
        ),
      );
      expect(notificationService.shown, hasLength(1));
    });
  });
}
