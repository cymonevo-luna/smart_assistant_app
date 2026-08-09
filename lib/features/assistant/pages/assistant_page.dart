import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../assistant_controller.dart';
import '../active_listening_controller.dart';
import '../models/assistant_reply.dart';
import '../models/chat_message.dart';
import '../widgets/assistant_message_bubble.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _scrollController = ScrollController();
  ProviderSubscription<AssistantUiState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = ref.listenManual<AssistantUiState>(
      assistantControllerProvider,
      (previous, next) {
        if (next.errorMessage != null &&
            next.errorMessage != previous?.errorMessage) {
          _showErrorSnackBar(next.errorMessage!, next.pendingRetryText != null);
        }
        _scrollToBottom();
      },
    );
  }

  @override
  void dispose() {
    _stateSub?.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showErrorSnackBar(String message, bool canRetry) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  ref.read(assistantControllerProvider.notifier).retryLastMessage();
                },
              )
            : null,
      ),
    );
    ref.read(assistantControllerProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(assistantControllerProvider);
    final activeListening = ref.watch(activeListeningControllerProvider);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assistant),
      ),
      body: Column(
        children: [
          if (activeListening.isMonitoring)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Chip(
                  key: const ValueKey('assistant_active_listening_chip'),
                  avatar: Icon(
                    Icons.hearing,
                    size: 18,
                    color: colors.secondary,
                  ),
                  label: Text(
                    l10n.listeningForWakeWord(activeListening.wakeWord),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                  ),
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: colors.secondary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: AppSpacing.screenPadding,
              itemCount: state.messages.length +
                  (state.partialTranscript != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < state.messages.length) {
                  final message = state.messages[index];
                  final latestAssistantIndex = _latestAssistantMessageIndex(
                    state.messages,
                  );
                  final isLatestAssistant = index == latestAssistantIndex;
                  return AssistantMessageBubble(
                    key: ValueKey('chat_message_$index'),
                    text: message.text,
                    isUser: message.isUser,
                    replyType: message.replyType,
                    action: message.action,
                    showActionCta: isLatestAssistant,
                    onConfirm: isLatestAssistant &&
                            message.replyType ==
                                AssistantReplyType.confirmation
                        ? () => ref
                            .read(assistantControllerProvider.notifier)
                            .sendConfirmationResponse(confirmed: true)
                        : null,
                    onDeny: isLatestAssistant &&
                            message.replyType ==
                                AssistantReplyType.confirmation
                        ? () => ref
                            .read(assistantControllerProvider.notifier)
                            .sendConfirmationResponse(confirmed: false)
                        : null,
                  );
                }
                return _ListeningBubble(text: state.partialTranscript!);
              },
            ),
          ),
          if (state.interactionState == AssistantInteractionState.processing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.assistantProcessing,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          if (state.interactionState == AssistantInteractionState.speaking)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                l10n.assistantSpeaking,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                    ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Center(
              child: _MicButton(
                enabled: state.isMicEnabled,
                isListening:
                    state.interactionState == AssistantInteractionState.listening,
                onPressed: () =>
                    ref.read(assistantControllerProvider.notifier).onMicPressed(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int? _latestAssistantMessageIndex(List<ChatMessage> messages) {
  for (var index = messages.length - 1; index >= 0; index--) {
    if (!messages[index].isUser) {
      return index;
    }
  }
  return null;
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.enabled,
    required this.isListening,
    required this.onPressed,
  });

  final bool enabled;
  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.primary,
      elevation: 6,
      shadowColor: colors.primary.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('assistant_mic_button'),
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
        splashColor: colors.secondary.withValues(alpha: 0.35),
        highlightColor: colors.secondary.withValues(alpha: 0.2),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: colors.onPrimary,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _ListeningBubble extends StatelessWidget {
  const _ListeningBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        key: const ValueKey('assistant_listening_bubble'),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.primary),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.primary,
                fontStyle: FontStyle.italic,
              ),
        ),
      ),
    );
  }
}
