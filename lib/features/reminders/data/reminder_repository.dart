import 'dart:convert';

import '../../../core/storage/preferences_service.dart';
import '../models/location_reminder.dart';

/// Persists [LocationReminder] records on-device for offline proximity checks.
class ReminderRepository {
  ReminderRepository(this._prefs);

  final PreferencesService _prefs;

  Future<void> save(LocationReminder reminder) async {
    final reminders = await _loadAll();
    final index = reminders.indexWhere((item) => item.id == reminder.id);
    if (index >= 0) {
      reminders[index] = reminder;
    } else {
      reminders.add(reminder);
    }
    await _persistAll(reminders);
  }

  Future<List<LocationReminder>> getAllPending() async {
    final reminders = await _loadAll();
    return reminders
        .where((item) => item.status == ReminderStatus.pending)
        .toList();
  }

  Future<LocationReminder?> getById(String id) async {
    final reminders = await _loadAll();
    for (final reminder in reminders) {
      if (reminder.id == id) {
        return reminder;
      }
    }
    return null;
  }

  Future<void> markTriggered(String id) async {
    final reminders = await _loadAll();
    final index = reminders.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }

    reminders[index] = reminders[index].copyWith(
      status: ReminderStatus.triggered,
    );
    await _persistAll(reminders);
  }

  Future<void> delete(String id) async {
    final reminders = await _loadAll();
    reminders.removeWhere((item) => item.id == id);
    await _persistAll(reminders);
  }

  /// Replaces pending reminders with server data while keeping triggered history.
  Future<void> syncFromApi(List<LocationReminder> reminders) async {
    final existing = await _loadAll();
    final triggered = existing
        .where((item) => item.status == ReminderStatus.triggered)
        .toList();
    await _persistAll([...triggered, ...reminders]);
  }

  Future<List<LocationReminder>> _loadAll() async {
    final raw = _prefs.getString(PrefKeys.locationReminders);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .map(
          (item) => LocationReminder.fromJson(
            (item as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<void> _persistAll(List<LocationReminder> reminders) async {
    final encoded = jsonEncode(
      reminders.map((item) => item.toJson()).toList(),
    );
    await _prefs.setString(PrefKeys.locationReminders, encoded);
  }
}
