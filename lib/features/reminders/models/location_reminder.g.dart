// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocationReminder _$LocationReminderFromJson(Map<String, dynamic> json) =>
    _LocationReminder(
      id: json['reminder_id'] as String,
      title: json['title'] as String,
      locationMode: $enumDecode(_$LocationModeEnumMap, json['location_mode']),
      placeQuery: json['place_query'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeKeyword: json['place_keyword'] as String?,
      radiusMeters: (json['radius_meters'] as num).toInt(),
      status:
          $enumDecodeNullable(_$ReminderStatusEnumMap, json['status']) ??
          ReminderStatus.pending,
    );

Map<String, dynamic> _$LocationReminderToJson(_LocationReminder instance) =>
    <String, dynamic>{
      'reminder_id': instance.id,
      'title': instance.title,
      'location_mode': _$LocationModeEnumMap[instance.locationMode]!,
      'place_query': instance.placeQuery,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'place_keyword': instance.placeKeyword,
      'radius_meters': instance.radiusMeters,
      'status': _$ReminderStatusEnumMap[instance.status]!,
    };

const _$LocationModeEnumMap = {
  LocationMode.exact: 'exact',
  LocationMode.placeKeyword: 'place_keyword',
};

const _$ReminderStatusEnumMap = {
  ReminderStatus.pending: 'pending',
  ReminderStatus.triggered: 'triggered',
};
