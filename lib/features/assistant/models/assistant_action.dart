import 'assistant_session.dart';

class AssistantAction {
  const AssistantAction({
    required this.pluginSlug,
    required this.status,
  });

  final String pluginSlug;
  final String status;

  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    return AssistantAction(
      pluginSlug: json['plugin_slug'] as String,
      status: json['status'] as String,
    );
  }
}

class AssistantMessageResult {
  const AssistantMessageResult({
    required this.response,
    this.action,
  });

  final AssistantMessageResponse response;
  final AssistantAction? action;
}
