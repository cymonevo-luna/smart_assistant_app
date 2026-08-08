import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_reminder.freezed.dart';
part 'location_reminder.g.dart';

@JsonEnum(alwaysCreate: true)
enum LocationMode {
  @JsonValue('exact')
  exact,
  @JsonValue('place_keyword')
  placeKeyword,
}

@JsonEnum(alwaysCreate: true)
enum ReminderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('triggered')
  triggered,
}

@freezed
abstract class LocationReminder with _$LocationReminder {
  const factory LocationReminder({
    @JsonKey(name: 'reminder_id') required String id,
    required String title,
    @JsonKey(name: 'location_mode') required LocationMode locationMode,
    @JsonKey(name: 'place_query') String? placeQuery,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'place_keyword') String? placeKeyword,
    @JsonKey(name: 'radius_meters') required int radiusMeters,
    @Default(ReminderStatus.pending) ReminderStatus status,
  }) = _LocationReminder;

  factory LocationReminder.fromJson(Map<String, dynamic> json) =>
      _$LocationReminderFromJson(_normalizeLocationReminderJson(json));
}

Map<String, dynamic> _normalizeLocationReminderJson(Map<String, dynamic> json) {
  return {
    ...json,
    'reminder_id': json['reminder_id'] ?? json['id'],
  };
}
