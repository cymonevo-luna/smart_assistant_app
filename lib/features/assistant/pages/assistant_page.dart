import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../assistant_controller.dart';
import '../active_listening_controller.dart';
import '../models/assistant_reply.dart';

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
                    color: colors.primary,
                  ),
                  label: Text(
                    l10n.listeningForWakeWord(activeListening.wakeWord),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                        ),
                  ),
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
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
                  return _ChatBubble(
                    key: ValueKey('chat_message_$index'),
                    text: message.text,
                    isUser: message.isUser,
                    replyType: message.replyType,
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
      color: isListening ? colors.error : colors.primary,
      elevation: 6,
      shadowColor: colors.primary.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('assistant_mic_button'),
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.replyType,
  });

  final String text;
  final bool isUser;
  final AssistantReplyType? replyType;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser ? colors.primary : colors.surfaceContainerHighest;
    final foreground = isUser ? colors.onPrimary : colors.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
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
