import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/assistant_action_reason.dart';
import '../models/assistant_reply.dart';

enum AssistantMessageCta {
  none,
  completeSetup,
  managePlugins,
}

AssistantMessageCta resolveAssistantMessageCta({
  required AssistantAction? action,
  required bool showActionCta,
}) {
  if (!showActionCta || action == null) {
    return AssistantMessageCta.none;
  }

  final reason = action.payloadReason;
  if (reason == AssistantActionReason.setupIncomplete &&
      action.installId != null) {
    return AssistantMessageCta.completeSetup;
  }
  if (reason == AssistantActionReason.pluginDisabled) {
    return AssistantMessageCta.managePlugins;
  }
  return AssistantMessageCta.none;
}

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.replyType,
    this.action,
    this.showActionCta = false,
  });

  final String text;
  final bool isUser;
  final AssistantReplyType? replyType;
  final AssistantAction? action;
  final bool showActionCta;

  Future<void> _onCompleteSetupTap(BuildContext context) async {
    final installId = action?.installId;
    if (installId == null) return;

    final l10n = AppLocalizations.of(context);
    try {
      await context.pushNamed(
        AppRoute.pluginSetup.name,
        pathParameters: {'id': installId},
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  void _onManagePluginsTap(BuildContext context) {
    context.goNamed(AppRoute.managePlugins.name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser ? colors.primary : colors.surfaceContainerHighest;
    final foreground = isUser ? colors.onPrimary : colors.onSurface;
    final cta = resolveAssistantMessageCta(
      action: action,
      showActionCta: showActionCta,
    );

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            key: ValueKey('assistant_bubble_${isUser ? 'user' : 'assistant'}_$text'),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser && replyType == AssistantReplyType.followUp)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: foreground.withValues(alpha: 0.8),
                    ),
                  ),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                      ),
                ),
              ],
            ),
          ),
          if (cta == AssistantMessageCta.completeSetup)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: FilledButton(
                key: const ValueKey('assistant_complete_setup_button'),
                onPressed: () => _onCompleteSetupTap(context),
                child: Text(l10n.assistantCompleteSetup),
              ),
            )
          else if (cta == AssistantMessageCta.managePlugins)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: FilledButton(
                key: const ValueKey('assistant_manage_plugins_button'),
                onPressed: () => _onManagePluginsTap(context),
                child: Text(l10n.assistantManagePlugins),
              ),
            ),
        ],
      ),
    );
  }
}
