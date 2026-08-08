import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/locator.dart';
import '../../auth/auth_controller.dart';
import '../services/reminder_notification_service.dart';

/// Triggers reminder sync when the app starts and when it returns to foreground.
class ReminderSyncLifecycle extends ConsumerStatefulWidget {
  const ReminderSyncLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderSyncLifecycle> createState() =>
      _ReminderSyncLifecycleState();
}

class _ReminderSyncLifecycleState extends ConsumerState<ReminderSyncLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfAuthenticated());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncIfAuthenticated());
    }
  }

  Future<void> _syncIfAuthenticated() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) return;
    await locator<ReminderNotificationService>().syncReminders();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
