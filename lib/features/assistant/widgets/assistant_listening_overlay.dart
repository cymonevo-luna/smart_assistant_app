import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../assistant_controller.dart';

/// Full-screen listening overlay shown above any route (Google Assistant style).
class AssistantListeningOverlay extends StatelessWidget {
  const AssistantListeningOverlay({
    super.key,
    required this.state,
    required this.onCancel,
  });

  final AssistantUiState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Material(
      key: const ValueKey('assistant_listening_overlay'),
      color: colors.scrim.withValues(alpha: 0.54),
      child: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: const ValueKey('assistant_listening_overlay_cancel'),
                icon: Icon(Icons.close, color: colors.onSurface),
                tooltip: l10n.cancel,
                onPressed: onCancel,
              ),
            ),
            Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _OverlayContent(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayContent extends StatelessWidget {
  const _OverlayContent({required this.state});

  final AssistantUiState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    if (state.errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const VGap(AppSpacing.md),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.interactionState == AssistantInteractionState.listening)
          const _MicPulseIndicator()
        else if (state.interactionState == AssistantInteractionState.processing)
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          )
        else
          Icon(
            Icons.volume_up,
            size: 48,
            color: colors.primary,
          ),
        const VGap(AppSpacing.lg),
        Text(
          _statusLabel(l10n),
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (state.interactionState == AssistantInteractionState.listening &&
            state.partialTranscript != null &&
            state.partialTranscript!.isNotEmpty) ...[
          const VGap(AppSpacing.sm),
          Text(
            state.partialTranscript!,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else if (state.interactionState ==
                AssistantInteractionState.listening &&
            (state.partialTranscript == null ||
                state.partialTranscript!.isEmpty)) ...[
          const VGap(AppSpacing.xs),
          Text(
            l10n.assistantTapToSpeak,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (state.interactionState) {
      case AssistantInteractionState.listening:
        return l10n.assistantListening;
      case AssistantInteractionState.processing:
        return l10n.assistantProcessing;
      case AssistantInteractionState.speaking:
        return l10n.assistantSpeaking;
      case AssistantInteractionState.idle:
        return l10n.assistantListening;
    }
  }
}

class _MicPulseIndicator extends StatefulWidget {
  const _MicPulseIndicator();

  @override
  State<_MicPulseIndicator> createState() => _MicPulseIndicatorState();
}

class _MicPulseIndicatorState extends State<_MicPulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      key: const ValueKey('assistant_listening_mic_animation'),
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.35);
        final opacity = 0.45 * (1.0 - _controller.value);

        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: opacity),
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
                  size: 36,
                  color: colors.onPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
