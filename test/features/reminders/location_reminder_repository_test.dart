import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_repository.dart';
import 'package:smart_assistant_app/features/reminders/models/location_reminder.dart';

void main() {
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
  });

  LocationReminder pendingReminder({
    String id = 'test-1',
    String title = 'Buy milk',
    int radiusMeters = 150,
  }) {
    return LocationReminder(
      id: id,
      title: title,
      locationMode: LocationMode.exact,
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: radiusMeters,
    );
  }

  test('save and load pending reminder', () async {
    final repo = ReminderRepository(prefs);
    await repo.save(
      pendingReminder(
        id: 'test-1',
        title: 'Buy milk',
        radiusMeters: 150,
      ),
    );

    final pending = await repo.getAllPending();

    expect(pending, hasLength(1));
    expect(pending.first.id, 'test-1');
    expect(pending.first.title, 'Buy milk');
    expect(pending.first.radiusMeters, 150);
  });

  test('mark triggered removes from pending', () async {
    final repo = ReminderRepository(prefs);
    await repo.save(pendingReminder(id: 'test-1'));

    await repo.markTriggered('test-1');

    final pending = await repo.getAllPending();
    expect(pending, isEmpty);

    final stored = await repo.getById('test-1');
    expect(stored?.status, ReminderStatus.triggered);
  });

  test('persistence across repository re-instantiation', () async {
    final repo = ReminderRepository(prefs);
    await repo.save(pendingReminder(id: 'test-1', title: 'Buy milk'));

    final relaunched = ReminderRepository(prefs);
    final pending = await relaunched.getAllPending();

    expect(pending, hasLength(1));
    expect(pending.first.id, 'test-1');
    expect(pending.first.title, 'Buy milk');
  });
}
