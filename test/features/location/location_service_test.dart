import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_assistant_app/features/location/location_service.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.checkPermissionResult = LocationPermission.whileInUse,
    this.requestPermissionResult = LocationPermission.whileInUse,
    this.currentPosition,
    this.positionStream,
  });

  bool serviceEnabled;
  LocationPermission checkPermissionResult;
  LocationPermission requestPermissionResult;
  Position? currentPosition;
  Stream<Position>? positionStream;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkPermissionResult;

  @override
  Future<LocationPermission> requestPermission() async =>
      requestPermissionResult;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (currentPosition == null) {
      throw const PermissionDeniedException('Location permission denied.');
    }
    return currentPosition!;
  }

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return positionStream ?? const Stream.empty();
  }
}

Position _testPosition() {
  return Position(
    latitude: 37.7749,
    longitude: -122.4194,
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

void main() {
  group('LocationService', () {
    test('getCurrentPosition returns coordinates when permission granted', () async {
      final geolocator = FakeGeolocatorPlatform(
        checkPermissionResult: LocationPermission.whileInUse,
        currentPosition: _testPosition(),
      );
      final service = LocationService(geolocator: geolocator);

      final position = await service.getCurrentPosition();

      expect(position, isNotNull);
      expect(position!.latitude, 37.7749);
      expect(position.longitude, -122.4194);
    });

    test('getCurrentPosition returns null when permission denied', () async {
      final geolocator = FakeGeolocatorPlatform(
        checkPermissionResult: LocationPermission.denied,
      );
      final service = LocationService(geolocator: geolocator);

      final position = await service.getCurrentPosition();

      expect(position, isNull);
    });

    test('getCurrentPosition returns null when location services disabled', () async {
      final geolocator = FakeGeolocatorPlatform(
        serviceEnabled: false,
        checkPermissionResult: LocationPermission.whileInUse,
        currentPosition: _testPosition(),
      );
      final service = LocationService(geolocator: geolocator);

      final position = await service.getCurrentPosition();

      expect(position, isNull);
      expect(service.isLocationServiceEnabled, isFalse);
    });

    test('requestPermission returns whileInUse when granted', () async {
      final geolocator = FakeGeolocatorPlatform(
        checkPermissionResult: LocationPermission.denied,
        requestPermissionResult: LocationPermission.whileInUse,
      );
      final service = LocationService(geolocator: geolocator);

      final status = await service.requestPermission();

      expect(status, LocationPermissionStatus.whileInUse);
    });

    test('positionStream emits throttled position updates', () async {
      final positions = [
        _testPosition(),
        Position(
          latitude: 38.0,
          longitude: -123.0,
          timestamp: DateTime.utc(2026, 1, 1, 0, 0, 1),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      ];
      final geolocator = FakeGeolocatorPlatform(
        positionStream: Stream.fromIterable(positions),
      );
      final service = LocationService(geolocator: geolocator);

      final emitted = await service
          .positionStream(interval: const Duration(seconds: 1))
          .take(1)
          .toList();

      expect(emitted, hasLength(1));
      expect(emitted.first.latitude, 37.7749);
    });
  });
}
