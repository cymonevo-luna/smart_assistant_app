import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../assistant_controller.dart';
import 'assistant_listening_overlay.dart';

/// Manages a full-screen [OverlayEntry] for [AssistantListeningOverlay].
class AssistantListeningOverlayController extends Notifier<bool> {
  OverlayState? _overlayState;
  OverlayEntry? _entry;

  @override
  bool build() => false;

  bool get isVisible => state;

  void attach(OverlayState overlayState) {
    _overlayState = overlayState;
  }

  void detach() {
    hide();
    _overlayState = null;
  }

  void show() {
    if (state || _overlayState == null) return;

    _entry = OverlayEntry(
      builder: (context) => const _AssistantListeningOverlayEntry(),
    );
    _overlayState!.insert(_entry!);
    state = true;
  }

  void hide() {
    if (!state) return;

    _entry?.remove();
    _entry = null;
    state = false;
  }

  void rebuild() {
    _entry?.markNeedsBuild();
  }
}

final assistantListeningOverlayControllerProvider =
    NotifierProvider<AssistantListeningOverlayController, bool>(
  AssistantListeningOverlayController.new,
);

class AssistantListeningOverlayHost extends ConsumerStatefulWidget {
  const AssistantListeningOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AssistantListeningOverlayHost> createState() =>
      _AssistantListeningOverlayHostState();
}

class _AssistantListeningOverlayHostState
    extends ConsumerState<AssistantListeningOverlayHost> {
  AssistantListeningOverlayController? _overlayController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachOverlay());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachOverlay();
  }

  @override
  void dispose() {
    _overlayController?.detach();
    super.dispose();
  }

  void _attachOverlay() {
    final overlay = Overlay.maybeOf(context) ??
        appRootNavigatorKey.currentState?.overlay;
    if (overlay != null) {
      _overlayController ??=
          ref.read(assistantListeningOverlayControllerProvider.notifier);
      _overlayController!.attach(overlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AssistantUiState>(assistantControllerProvider, (previous, next) {
      if (!ref.read(assistantListeningOverlayControllerProvider)) return;
      ref.read(assistantListeningOverlayControllerProvider.notifier).rebuild();
    });

    return widget.child;
  }
}

class _AssistantListeningOverlayEntry extends ConsumerWidget {
  const _AssistantListeningOverlayEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantControllerProvider);
    final overlayController =
        ref.read(assistantListeningOverlayControllerProvider.notifier);

    return AssistantListeningOverlay(
      state: state,
      onCancel: () => _handleCancel(ref, overlayController),
    );
  }

  void _handleCancel(
    WidgetRef ref,
    AssistantListeningOverlayController overlayController,
  ) {
    final assistantState = ref.read(assistantControllerProvider);
    final assistant = ref.read(assistantControllerProvider.notifier);

    if (assistantState.interactionState ==
        AssistantInteractionState.listening) {
      assistant.onMicPressed();
    } else if (assistantState.errorMessage != null) {
      assistant.clearError();
    }

    overlayController.hide();
  }
}
