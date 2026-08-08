// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantSession _$AssistantSessionFromJson(Map<String, dynamic> json) =>
    _AssistantSession(
      id: json['id'] as String,
      sessionStatus: $enumDecode(
        _$AssistantSessionStatusEnumMap,
        json['session_status'],
      ),
    );

Map<String, dynamic> _$AssistantSessionToJson(
  _AssistantSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'session_status': _$AssistantSessionStatusEnumMap[instance.sessionStatus]!,
};

const _$AssistantSessionStatusEnumMap = {
  AssistantSessionStatus.active: 'active',
  AssistantSessionStatus.completed: 'completed',
};

_AssistantMessageResponse _$AssistantMessageResponseFromJson(
  Map<String, dynamic> json,
) => _AssistantMessageResponse(
  reply: AssistantReply.fromJson(json['reply'] as Map<String, dynamic>),
  sessionStatus: $enumDecode(
    _$AssistantSessionStatusEnumMap,
    json['session_status'],
  ),
);

Map<String, dynamic> _$AssistantMessageResponseToJson(
  _AssistantMessageResponse instance,
) => <String, dynamic>{
  'reply': instance.reply,
  'session_status': _$AssistantSessionStatusEnumMap[instance.sessionStatus]!,
};
