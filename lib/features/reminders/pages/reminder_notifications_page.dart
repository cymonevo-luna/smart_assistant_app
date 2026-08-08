import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/locator.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../services/reminder_notification_service.dart';

class ReminderNotificationsPage extends ConsumerStatefulWidget {
  const ReminderNotificationsPage({super.key});

  @override
  ConsumerState<ReminderNotificationsPage> createState() =>
      _ReminderNotificationsPageState();
}

class _ReminderNotificationsPageState
    extends ConsumerState<ReminderNotificationsPage> {
  bool _requestingPermission = false;

  Future<void> _requestPermission() async {
    setState(() => _requestingPermission = true);
    try {
      await locator<ReminderNotificationService>().syncReminders();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reminderNotificationsPermissionRequested)),
      );
    } finally {
      if (mounted) {
        setState(() => _requestingPermission = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: AppText.heading(l10n.notifications),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.title(l10n.reminderNotificationsTitle),
                const VGap(AppSpacing.sm),
                AppText.body(l10n.reminderNotificationsDescription),
                const VGap(AppSpacing.lg),
                AppButton(
                  l10n.reminderNotificationsRequestPermission,
                  loading: _requestingPermission,
                  onPressed: _requestingPermission ? null : _requestPermission,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
