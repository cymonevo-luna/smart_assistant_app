import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/features/reminders/models/location_reminder.dart';

void main() {
  group('LocationReminder.fromJson', () {
    test('parses API payload JSON including place_keyword mode', () {
      final json = {
        'reminder_id': 'rem-42',
        'title': 'Remind me at the gym',
        'location_mode': 'place_keyword',
        'place_query': 'gym near downtown',
        'place_keyword': 'gym',
        'radius_meters': 200,
        'status': 'pending',
      };

      final reminder = LocationReminder.fromJson(json);

      expect(reminder.id, 'rem-42');
      expect(reminder.title, 'Remind me at the gym');
      expect(reminder.locationMode, LocationMode.placeKeyword);
      expect(reminder.placeQuery, 'gym near downtown');
      expect(reminder.placeKeyword, 'gym');
      expect(reminder.radiusMeters, 200);
      expect(reminder.status, ReminderStatus.pending);
      expect(reminder.latitude, isNull);
      expect(reminder.longitude, isNull);
    });

    test('parses exact mode coordinates from API payload', () {
      final json = {
        'reminder_id': 'rem-1',
        'title': 'Home',
        'location_mode': 'exact',
        'latitude': 40.7128,
        'longitude': -74.0060,
        'radius_meters': 100,
      };

      final reminder = LocationReminder.fromJson(json);

      expect(reminder.locationMode, LocationMode.exact);
      expect(reminder.latitude, 40.7128);
      expect(reminder.longitude, -74.0060);
      expect(reminder.status, ReminderStatus.pending);
    });
  });
}
