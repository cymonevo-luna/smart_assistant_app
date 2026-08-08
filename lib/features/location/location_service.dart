import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

/// App-level view of device location permission state.
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
}

/// Reads GPS coordinates when the user grants permission.
///
/// Requests when-in-use access by default. Call [requestBackgroundPermission]
/// only when background monitoring is required (e.g. first location reminder).
class LocationService {
  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  bool _locationServiceEnabled = false;

  /// Last known location-service-enabled state from the platform.
  ///
  /// Updated when permission or position APIs run. Defaults to `false` until
  /// the first platform check.
  bool get isLocationServiceEnabled => _locationServiceEnabled;

  /// Requests when-in-use location permission. Does not request background
  /// access; use [requestBackgroundPermission] when needed later.
  Future<LocationPermissionStatus> requestPermission() async {
    await _refreshLocationServiceEnabled();

    if (!_locationServiceEnabled) {
      return LocationPermissionStatus.denied;
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  /// Requests background ("always") location permission after when-in-use is
  /// granted. Intended for proximity monitoring in a follow-up ticket.
  Future<LocationPermissionStatus> requestBackgroundPermission() async {
    await _refreshLocationServiceEnabled();

    if (!_locationServiceEnabled) {
      return LocationPermissionStatus.denied;
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await _geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  /// Returns the current GPS position, or `null` when permission is denied or
  /// location services are disabled.
  Future<Position?> getCurrentPosition() async {
    await _refreshLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      return null;
    }

    final permission = await _geolocator.checkPermission();
    if (!_isPermissionGranted(permission)) {
      return null;
    }

    try {
      return await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } on LocationServiceDisabledException {
      _locationServiceEnabled = false;
      return null;
    } on PermissionDeniedException {
      return null;
    }
  }

  /// Emits throttled position updates for live monitoring.
  Stream<Position> positionStream({Duration interval = const Duration(seconds: 5)}) {
    final settings = _locationSettings(interval);
    final controller = StreamController<Position>();
    DateTime? lastEmit;
    StreamSubscription<Position>? subscription;

    controller.onListen = () {
      subscription = _geolocator.getPositionStream(locationSettings: settings).listen(
        (position) {
          final now = DateTime.now();
          if (lastEmit == null || now.difference(lastEmit!) >= interval) {
            lastEmit = now;
            controller.add(position);
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    };

    controller.onCancel = () async {
      await subscription?.cancel();
    };

    return controller.stream;
  }

  Future<void> _refreshLocationServiceEnabled() async {
    _locationServiceEnabled = await _geolocator.isLocationServiceEnabled();
  }

  LocationSettings _locationSettings(Duration interval) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: interval,
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.high,
    );
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  bool _isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
