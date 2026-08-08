// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantReply _$AssistantReplyFromJson(Map<String, dynamic> json) =>
    _AssistantReply(
      type: $enumDecode(_$AssistantReplyTypeEnumMap, json['type']),
      text: json['text'] as String,
    );

Map<String, dynamic> _$AssistantReplyToJson(_AssistantReply instance) =>
    <String, dynamic>{
      'type': _$AssistantReplyTypeEnumMap[instance.type]!,
      'text': instance.text,
    };

const _$AssistantReplyTypeEnumMap = {
  AssistantReplyType.text: 'text',
  AssistantReplyType.followUp: 'follow_up',
  AssistantReplyType.confirmation: 'confirmation',
  AssistantReplyType.actionResult: 'action_result',
};
