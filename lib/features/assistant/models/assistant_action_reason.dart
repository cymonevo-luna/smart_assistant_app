import 'assistant_reply.dart';

/// Known `reply.action.payload.reason` values from the assistant API.
abstract final class AssistantActionReason {
  static const setupIncomplete = 'setup_incomplete';
  static const pluginDisabled = 'plugin_disabled';
}

extension AssistantActionPayload on AssistantAction {
  String? get payloadReason => payload?['reason'] as String?;

  String? get installId {
    final value = payload?['install_id'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  String? get payloadPluginSlug {
    final fromPayload = payload?['plugin_slug'];
    if (fromPayload is String && fromPayload.isNotEmpty) {
      return fromPayload;
    }
    return pluginSlug;
  }
}
