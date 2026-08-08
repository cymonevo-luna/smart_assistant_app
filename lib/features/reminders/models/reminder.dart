enum ReminderStatus {
  pending,
  completed,
  cancelled,
  notified,
}

class Reminder {
  const Reminder({
    required this.id,
    required this.message,
    required this.remindAt,
    required this.status,
  });

  final String id;
  final String message;
  final DateTime remindAt;
  final ReminderStatus status;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      message: json['message'] as String,
      remindAt: DateTime.parse(json['remind_at'] as String),
      status: _parseStatus(json['status'] as String),
    );
  }
}

ReminderStatus _parseStatus(String value) {
  return switch (value) {
    'pending' => ReminderStatus.pending,
    'completed' => ReminderStatus.completed,
    'cancelled' => ReminderStatus.cancelled,
    'notified' => ReminderStatus.notified,
    _ => ReminderStatus.pending,
  };
}

/// Stable notification id derived from a reminder UUID.
int reminderNotificationId(String reminderId) {
  var hash = 0x811c9dc5;
  for (final unit in reminderId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
