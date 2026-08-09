import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/location_reminder.dart';

/// Fetches location reminders from the backend API.
class ReminderApiRepository {
  ReminderApiRepository(this._api);

  final ApiClient _api;

  static const pendingPath = '/api/v1/reminders';

  Future<List<LocationReminder>> fetchPending() {
    return _api.get<List<LocationReminder>>(
      pendingPath,
      query: {'status': 'pending'},
      decoder: (raw) => _parseList(raw, LocationReminder.fromJson),
    );
  }

  /// Best-effort server sync when a reminder triggers locally.
  Future<void> markTriggered(String id) async {
    try {
      await _api.patch<void>('/api/v1/reminders/$id/triggered');
    } on ApiException {
      // Ignore offline or transient API failures.
    }
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
    if (map.containsKey('data')) {
      return (map['data'] as List).cast<dynamic>();
    }
    return map.values.first as List<dynamic>;
  }
}
