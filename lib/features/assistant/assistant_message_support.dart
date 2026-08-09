import 'dart:convert';

import '../../core/router/app_router.dart';
import 'models/assistant_action_reason.dart';
import 'models/assistant_reply.dart';

/// Slug for the Composio AI plugin in assistant action payloads.
const composioAiPluginSlug = 'composio-ai';

/// Resolves the setup route for a plugin install referenced by an action.
AppRoute setupRouteForAction(AssistantAction action) {
  final slug = action.payloadPluginSlug;
  if (slug == composioAiPluginSlug) {
    return AppRoute.composioAiSetup;
  }
  return AppRoute.pluginSetup;
}

/// User-visible assistant reply text. Avoids showing raw Composio JSON blobs.
String assistantReplyDisplayText({
  required String text,
  AssistantAction? action,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return _payloadMessage(action) ?? trimmed;
  }
  if (!_looksLikeJson(trimmed)) {
    return trimmed;
  }

  final fromPayload = _payloadMessage(action);
  if (fromPayload != null && fromPayload.isNotEmpty) {
    return fromPayload;
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      for (final key in ['message', 'result', 'summary', 'text']) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
  } catch (_) {
    // Fall through to trimmed text.
  }

  return trimmed;
}

String? pluginBadgeLabel(AssistantAction? action) {
  if (action == null) return null;

  final slug = action.payloadPluginSlug;
  if (slug != composioAiPluginSlug) return null;

  final name = action.payload?['plugin_name'];
  if (name is String && name.trim().isNotEmpty) {
    return name.trim();
  }
  return 'Composio AI';
}

bool shouldShowPluginBadge({
  required AssistantReplyType? replyType,
  required AssistantAction? action,
}) {
  if (replyType != AssistantReplyType.actionResult) return false;
  return pluginBadgeLabel(action) != null;
}

String? _payloadMessage(AssistantAction? action) {
  final payload = action?.payload;
  if (payload == null) return null;

  for (final key in ['message', 'result', 'summary', 'text']) {
    final value = payload[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool _looksLikeJson(String text) {
  final value = text.trim();
  return (value.startsWith('{') && value.endsWith('}')) ||
      (value.startsWith('[') && value.endsWith(']'));
}
