import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_app/core/router/app_router.dart';
import 'package:smart_assistant_app/features/assistant/assistant_message_support.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_action_reason.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_reply.dart';

void main() {
  group('assistantReplyDisplayText', () {
    test('returns plain text unchanged', () {
      expect(
        assistantReplyDisplayText(
          text: 'Task completed successfully.',
          action: null,
        ),
        'Task completed successfully.',
      );
    });

    test('extracts message from raw JSON text', () {
      expect(
        assistantReplyDisplayText(
          text: '{"message":"Email sent to Janet."}',
          action: null,
        ),
        'Email sent to Janet.',
      );
    });

    test('prefers payload message over raw JSON text', () {
      expect(
        assistantReplyDisplayText(
          text: '{"status":"ok"}',
          action: AssistantAction(
            pluginSlug: composioAiPluginSlug,
            payload: {'message': 'Email sent to Janet.'},
          ),
        ),
        'Email sent to Janet.',
      );
    });
  });

  group('setupRouteForAction', () {
    test('routes composio-ai setup to composio form screen', () {
      final route = setupRouteForAction(
        AssistantAction(
          pluginSlug: composioAiPluginSlug,
          payload: {
            'reason': AssistantActionReason.setupIncomplete,
            'install_id': 'install-composio-ai',
            'plugin_slug': composioAiPluginSlug,
          },
        ),
      );

      expect(route, AppRoute.composioAiSetup);
    });

    test('routes other plugins to generic setup screen', () {
      final route = setupRouteForAction(
        AssistantAction(
          pluginSlug: 'google-calendar',
          payload: {
            'reason': AssistantActionReason.setupIncomplete,
            'install_id': 'install-calendar',
            'plugin_slug': 'google-calendar',
          },
        ),
      );

      expect(route, AppRoute.pluginSetup);
    });
  });

  group('pluginBadgeLabel', () {
    test('returns metadata plugin name when available', () {
      expect(
        pluginBadgeLabel(
          AssistantAction(
            pluginSlug: composioAiPluginSlug,
            payload: {'plugin_name': 'Composio Automations'},
          ),
        ),
        'Composio Automations',
      );
    });

    test('falls back to Composio AI label', () {
      expect(
        pluginBadgeLabel(
          AssistantAction(pluginSlug: composioAiPluginSlug),
        ),
        'Composio AI',
      );
    });

    test('returns null for non-composio plugins', () {
      expect(
        pluginBadgeLabel(
          AssistantAction(pluginSlug: 'reminder'),
        ),
        isNull,
      );
    });
  });
}
