// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantSettings _$AssistantSettingsFromJson(Map<String, dynamic> json) =>
    _AssistantSettings(
      wakeWord: json['wake_word'] as String,
      activeListeningEnabled: json['active_listening_enabled'] as bool,
      locationReminderThresholdMeters:
          (json['location_reminder_threshold_meters'] as num?)?.toInt() ?? 100,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AssistantSettingsToJson(_AssistantSettings instance) =>
    <String, dynamic>{
      'wake_word': instance.wakeWord,
      'active_listening_enabled': instance.activeListeningEnabled,
      'location_reminder_threshold_meters':
          instance.locationReminderThresholdMeters,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
