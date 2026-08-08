import 'assistant_reply.dart';

/// A single turn in the assistant chat transcript.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.replyType,
  });

  final String text;
  final bool isUser;
  final AssistantReplyType? replyType;
}
