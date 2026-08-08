import '../../../core/network/api_client.dart';
import '../models/reminder.dart';

abstract class ReminderDataSource {
  Future<List<Reminder>> listReminders({String filter = 'all'});

  Future<List<Reminder>> listPendingNotifications();

  Future<void> markDelivered(String reminderId);
}

/// Fetches time reminders and notification delivery state from the API.
class TimeReminderApiRepository implements ReminderDataSource {
  TimeReminderApiRepository(this._api);

  final ApiClient _api;

  static const remindersPath = '/api/v1/users/me/reminders';

  @override
  Future<List<Reminder>> listReminders({String filter = 'all'}) {
    return _api.get<List<Reminder>>(
      remindersPath,
      query: {'filter': filter},
      decoder: (raw) => _parseList(raw, Reminder.fromJson),
    );
  }

  @override
  Future<List<Reminder>> listPendingNotifications() {
    return _api.get<List<Reminder>>(
      '$remindersPath/notifications/pending',
      decoder: (raw) => _parseList(raw, Reminder.fromJson),
    );
  }

  @override
  Future<void> markDelivered(String reminderId) {
    return _api.post<void>(
      '$remindersPath/$reminderId/delivered',
      decoder: (_) {},
    );
  }

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = _unwrapList(raw);
    return items
        .map((item) => fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    final map = (raw as Map).cast<String, dynamic>();
    return (map['data'] as List).cast<dynamic>();
  }
}
