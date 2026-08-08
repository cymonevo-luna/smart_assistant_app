import 'package:freezed_annotation/freezed_annotation.dart';

import 'assistant_reply.dart';

part 'assistant_session.freezed.dart';
part 'assistant_session.g.dart';

@JsonEnum(alwaysCreate: true)
enum AssistantSessionStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
}

@freezed
abstract class AssistantSession with _$AssistantSession {
  const factory AssistantSession({
    @JsonKey(name: 'session_id') required String id,
    @JsonKey(name: 'session_status')
    @Default(AssistantSessionStatus.active)
    AssistantSessionStatus sessionStatus,
  }) = _AssistantSession;

  factory AssistantSession.fromJson(Map<String, dynamic> json) =>
      _$AssistantSessionFromJson(json);
}

@freezed
abstract class AssistantMessageResponse with _$AssistantMessageResponse {
  const factory AssistantMessageResponse({
    required AssistantReply reply,
    @JsonKey(name: 'session_status')
    required AssistantSessionStatus sessionStatus,
  }) = _AssistantMessageResponse;

  factory AssistantMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$AssistantMessageResponseFromJson(json);
}
