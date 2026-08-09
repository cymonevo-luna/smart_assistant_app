import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../location/location_service.dart';
import '../../places/data/places_api_repository.dart';
import '../../places/models/nearby_place.dart';
import '../data/location_reminder_repository.dart';
import '../data/reminder_api_repository.dart';
import '../models/location_reminder.dart';
import 'location_monitor_foreground_client.dart';
import 'location_reminder_notification_service.dart';

/// Monitors device location against pending reminders.
abstract class LocationMonitorService {
  Future<void> startMonitoring();
}

/// No-op monitor used in tests that do not exercise proximity logic.
class StubLocationMonitorService implements LocationMonitorService {
  @override
  Future<void> startMonitoring() async {}
}

/// Continuously evaluates pending location reminders against live GPS and
/// fires a local notification when the user is within the configured radius.
class LocationProximityMonitorService implements LocationMonitorService {
  LocationProximityMonitorService({
    required LocationReminderRepository reminderRepository,
    required ReminderApiRepository reminderApiRepository,
    required PlacesApiRepository placesApiRepository,
    required LocationService locationService,
    required LocationReminderNotificationService notificationService,
    LocationMonitorForegroundClient? foregroundClient,
    Duration positionInterval = const Duration(seconds: 30),
    Duration placesCacheTtl = const Duration(seconds: 60),
  })  : _reminderRepository = reminderRepository,
        _reminderApiRepository = reminderApiRepository,
        _placesApiRepository = placesApiRepository,
        _locationService = locationService,
        _notificationService = notificationService,
        _foregroundClient =
            foregroundClient ?? NoOpLocationMonitorForegroundClient(),
        _positionInterval = positionInterval,
        _placesCacheTtl = placesCacheTtl;

  final LocationReminderRepository _reminderRepository;
  final ReminderApiRepository _reminderApiRepository;
  final PlacesApiRepository _placesApiRepository;
  final LocationService _locationService;
  final LocationReminderNotificationService _notificationService;
  final LocationMonitorForegroundClient _foregroundClient;
  final Duration _positionInterval;
  final Duration _placesCacheTtl;

  final Set<String> _triggeredIds = <String>{};
  final Map<String, _PlacesCacheEntry> _placesCache =
      <String, _PlacesCacheEntry>{};

  StreamSubscription<Position>? _subscription;
  bool _starting = false;

  static const _notificationBody = "You're near your reminder location";

  @override
  Future<void> startMonitoring() async {
    final pending = await _reminderRepository.getAllPending();
    if (pending.isEmpty) {
      return;
    }

    if (_subscription != null || _starting) {
      return;
    }

    _starting = true;
    try {
      if (!await _locationService.hasLocationPermission()) {
        debugPrint(
          'LocationMonitorService: paused — location permission not granted',
        );
        return;
      }

      await _notificationService.initialize();
      await _foregroundClient.start();

      _subscription = _locationService
          .positionStream(interval: _positionInterval)
          .listen(
            _onPosition,
            onError: _onStreamError,
          );
    } finally {
      _starting = false;
    }
  }

  Future<void> _onPosition(Position position) async {
    if (!await _locationService.hasLocationPermission()) {
      await _pauseMonitoring('location permission revoked');
      return;
    }

    final pending = await _reminderRepository.getAllPending();
    if (pending.isEmpty) {
      await _stopMonitoring();
      return;
    }

    for (final reminder in pending) {
      if (_triggeredIds.contains(reminder.id)) {
        continue;
      }
      if (reminder.status != ReminderStatus.pending) {
        continue;
      }

      final shouldTrigger = await _shouldTrigger(reminder, position);
      if (shouldTrigger) {
        await _triggerReminder(reminder);
      }
    }
  }

  Future<bool> _shouldTrigger(
    LocationReminder reminder,
    Position position,
  ) async {
    switch (reminder.locationMode) {
      case LocationMode.exact:
        return _isWithinExactRadius(reminder, position);
      case LocationMode.placeKeyword:
        return _isWithinPlaceKeywordRadius(reminder, position);
    }
  }

  bool _isWithinExactRadius(LocationReminder reminder, Position position) {
    final latitude = reminder.latitude;
    final longitude = reminder.longitude;
    if (latitude == null || longitude == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
    return distance <= reminder.radiusMeters;
  }

  Future<bool> _isWithinPlaceKeywordRadius(
    LocationReminder reminder,
    Position position,
  ) async {
    final keyword = reminder.placeKeyword;
    if (keyword == null || keyword.isEmpty) {
      return false;
    }

    final places = await _fetchNearbyPlaces(
      keyword: keyword,
      latitude: position.latitude,
      longitude: position.longitude,
      searchRadiusMeters: reminder.radiusMeters * 5,
    );

    for (final place in places) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.latitude,
        place.longitude,
      );
      if (distance <= reminder.radiusMeters) {
        return true;
      }
    }
    return false;
  }

  Future<List<NearbyPlace>> _fetchNearbyPlaces({
    required String keyword,
    required double latitude,
    required double longitude,
    required int searchRadiusMeters,
  }) async {
    final cacheKey = _placesCacheKey(keyword, latitude, longitude);
    final cached = _placesCache[cacheKey];
    final now = DateTime.now();
    if (cached != null &&
        now.difference(cached.fetchedAt) < _placesCacheTtl) {
      return cached.places;
    }

    try {
      final places = await _placesApiRepository.fetchNearby(
        keyword: keyword,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: searchRadiusMeters,
      );
      _placesCache[cacheKey] = _PlacesCacheEntry(
        places: places,
        fetchedAt: now,
      );
      return places;
    } catch (error, stackTrace) {
      debugPrint(
        'LocationMonitorService: places lookup failed for "$keyword": $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return cached?.places ?? const <NearbyPlace>[];
    }
  }

  String _placesCacheKey(String keyword, double latitude, double longitude) {
    return '$keyword|${latitude.toStringAsFixed(3)}|${longitude.toStringAsFixed(3)}';
  }

  Future<void> _triggerReminder(LocationReminder reminder) async {
    _triggeredIds.add(reminder.id);

    await _notificationService.showReminderNotification(
      id: reminder.id,
      title: reminder.title,
      body: _notificationBody,
    );
    await _reminderRepository.markTriggered(reminder.id);
    unawaited(_reminderApiRepository.markTriggered(reminder.id));

    final pending = await _reminderRepository.getAllPending();
    if (pending.isEmpty) {
      await _stopMonitoring();
    }
  }

  Future<void> _onStreamError(Object error, StackTrace stackTrace) async {
    debugPrint('LocationMonitorService: position stream error: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (!_locationService.isLocationServiceEnabled) {
      await _pauseMonitoring('location services disabled');
    }
  }

  Future<void> _pauseMonitoring(String reason) async {
    debugPrint('LocationMonitorService: paused — $reason');
    await _subscription?.cancel();
    _subscription = null;
    await _foregroundClient.stop();
  }

  Future<void> _stopMonitoring() async {
    await _subscription?.cancel();
    _subscription = null;
    await _foregroundClient.stop();
  }

  /// Visible for tests.
  @visibleForTesting
  bool get isMonitoring => _subscription != null;

  /// Visible for tests.
  @visibleForTesting
  Set<String> get triggeredIds => Set<String>.unmodifiable(_triggeredIds);

  /// Visible for tests.
  @visibleForTesting
  void clearPlacesCache() => _placesCache.clear();
}

class _PlacesCacheEntry {
  const _PlacesCacheEntry({
    required this.places,
    required this.fetchedAt,
  });

  final List<NearbyPlace> places;
  final DateTime fetchedAt;
}
