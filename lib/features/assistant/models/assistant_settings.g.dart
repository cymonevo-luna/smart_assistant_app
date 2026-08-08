// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantSettings _$AssistantSettingsFromJson(Map<String, dynamic> json) =>
    _AssistantSettings(
      wakeWord: json['wake_word'] as String,
      activeListeningEnabled: json['active_listening_enabled'] as bool,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AssistantSettingsToJson(_AssistantSettings instance) =>
    <String, dynamic>{
      'wake_word': instance.wakeWord,
      'active_listening_enabled': instance.activeListeningEnabled,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
