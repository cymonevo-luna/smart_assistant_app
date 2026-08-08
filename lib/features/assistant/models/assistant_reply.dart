import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistant_reply.freezed.dart';
part 'assistant_reply.g.dart';

@JsonEnum(alwaysCreate: true)
enum AssistantReplyType {
  @JsonValue('text')
  text,
  @JsonValue('follow_up')
  followUp,
  @JsonValue('confirmation')
  confirmation,
  @JsonValue('action_result')
  actionResult,
}

@freezed
abstract class AssistantReply with _$AssistantReply {
  const factory AssistantReply({
    required AssistantReplyType type,
    required String text,
  }) = _AssistantReply;

  factory AssistantReply.fromJson(Map<String, dynamic> json) =>
      _$AssistantReplyFromJson(json);
}
