import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../assistant_message_support.dart';
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
    this.onConfirm,
    this.onDeny,
  });

  final String text;
  final bool isUser;
  final AssistantReplyType? replyType;
  final AssistantAction? action;
  final bool showActionCta;
  final VoidCallback? onConfirm;
  final VoidCallback? onDeny;

  Future<void> _onCompleteSetupTap(BuildContext context) async {
    final installId = action?.installId;
    if (installId == null || action == null) return;

    final l10n = AppLocalizations.of(context);
    final route = setupRouteForAction(action!);
    try {
      await context.pushNamed(
        route.name,
        pathParameters: {'id': installId},
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  Future<void> _onManagePluginsTap(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.pushNamed(AppRoute.managePlugins.name);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser ? colors.primary : colors.surfaceContainerHighest;
    final foreground = isUser ? colors.onPrimary : colors.onSurface;
    final displayText = assistantReplyDisplayText(text: text, action: action);
    final cta = resolveAssistantMessageCta(
      action: action,
      showActionCta: showActionCta,
    );
    final badge = shouldShowPluginBadge(replyType: replyType, action: action)
        ? pluginBadgeLabel(action)
        : null;
    final showConfirmationActions = showActionCta &&
        !isUser &&
        replyType == AssistantReplyType.confirmation &&
        onConfirm != null &&
        onDeny != null;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            key: ValueKey('assistant_bubble_${isUser ? 'user' : 'assistant'}_$displayText'),
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
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Chip(
                      key: const ValueKey('assistant_plugin_badge'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: foreground.withValues(alpha: 0.9),
                            ),
                      ),
                      backgroundColor: foreground.withValues(alpha: 0.08),
                      side: BorderSide(color: foreground.withValues(alpha: 0.2)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                      ),
                ),
              ],
            ),
          ),
          if (showConfirmationActions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    key: const ValueKey('assistant_confirm_yes_button'),
                    onPressed: onConfirm,
                    child: Text(l10n.assistantConfirmYes),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    key: const ValueKey('assistant_confirm_no_button'),
                    onPressed: onDeny,
                    child: Text(l10n.assistantConfirmNo),
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
