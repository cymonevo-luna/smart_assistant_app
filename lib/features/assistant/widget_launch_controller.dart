import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/locator.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'assistant_controller.dart';
import 'services/widget_launch_service.dart';
import 'widgets/assistant_listening_overlay_host.dart';

class WidgetLaunchController extends Notifier<void> {
  WidgetLaunchEvent? _pendingEvent;

  @override
  void build() {
    final service = locator<WidgetLaunchService>();
    final subscription = service.events.listen((event) {
      unawaited(_handleEvent(event));
    });

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_pendingEvent == null) return;
      if (next.status == AuthStatus.unknown) return;
      final event = _pendingEvent!;
      _pendingEvent = null;
      unawaited(_handleEvent(event));
    });

    ref.listen<AssistantUiState>(assistantControllerProvider, (previous, next) {
      if (!ref.read(assistantListeningOverlayControllerProvider)) return;
      if (next.interactionState == AssistantInteractionState.idle &&
          next.errorMessage == null &&
          !next.expectsFollowUpInput) {
        ref.read(assistantListeningOverlayControllerProvider.notifier).hide();
      }
    });

    ref.onDispose(subscription.cancel);
  }

  Future<void> _handleEvent(WidgetLaunchEvent event) async {
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.unknown) {
      _pendingEvent = event;
      return;
    }

    if (!auth.isAuthenticated) {
      _navigateToLoginWithMessage();
      return;
    }

    final assistantState = ref.read(assistantControllerProvider);
    if (assistantState.interactionState != AssistantInteractionState.idle) {
      return;
    }

    ref.read(assistantListeningOverlayControllerProvider.notifier).show();
    await ref
        .read(assistantControllerProvider.notifier)
        .startManualCommandCapture(source: 'button');
  }

  void _navigateToLoginWithMessage() {
    final context = appRootNavigatorKey.currentContext;
    if (context == null) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.assistantWidgetSignInRequired)),
    );
    context.goNamed(AppRoute.login.name);
  }
}

final widgetLaunchControllerProvider =
    NotifierProvider<WidgetLaunchController, void>(
  WidgetLaunchController.new,
);
