import 'assistant_reply.dart';

/// A single turn in the assistant chat transcript.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.replyType,
    this.action,
  });

  final String text;
  final bool isUser;
  final AssistantReplyType? replyType;
  final AssistantAction? action;
}
