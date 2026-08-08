// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantAction _$AssistantActionFromJson(Map<String, dynamic> json) =>
    _AssistantAction(
      pluginSlug: json['plugin_slug'] as String?,
      status: json['status'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AssistantActionToJson(_AssistantAction instance) =>
    <String, dynamic>{
      'plugin_slug': instance.pluginSlug,
      'status': instance.status,
      'payload': instance.payload,
    };

_AssistantReply _$AssistantReplyFromJson(Map<String, dynamic> json) =>
    _AssistantReply(
      type: $enumDecode(_$AssistantReplyTypeEnumMap, json['type']),
      text: json['text'] as String,
      action: json['action'] == null
          ? null
          : AssistantAction.fromJson(json['action'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AssistantReplyToJson(_AssistantReply instance) =>
    <String, dynamic>{
      'type': _$AssistantReplyTypeEnumMap[instance.type]!,
      'text': instance.text,
      'action': instance.action,
    };

const _$AssistantReplyTypeEnumMap = {
  AssistantReplyType.text: 'text',
  AssistantReplyType.followUp: 'follow_up',
  AssistantReplyType.confirmation: 'confirmation',
  AssistantReplyType.actionResult: 'action_result',
};
