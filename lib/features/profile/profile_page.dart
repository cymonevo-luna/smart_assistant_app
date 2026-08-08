import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((s) => s.user));
    final name = user?.name ?? '';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: AppText.heading(l10n.profile),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.pushNamed(AppRoute.settings.name),
            icon: const Icon(Icons.settings_outlined),
          ),
          const HGap(AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const VGap(AppSpacing.sm),
          Center(
            child: Column(
              children: [
                AppAvatar(name: name.isEmpty ? '?' : name, imageUrl: user?.avatarUrl),
                const VGap(AppSpacing.md),
                if (name.isNotEmpty)
                  AppText(
                    name,
                    variant: AppTextVariant.titleLarge,
                    weight: FontWeight.w700,
                  ),
                if (email.isNotEmpty) ...[
                  if (name.isNotEmpty) const VGap(AppSpacing.xxs),
                  AppText.body(email, muted: true),
                ],
              ],
            ),
          ),
          const VGap(AppSpacing.xl),
          AppButton(
            l10n.logout,
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.goNamed(AppRoute.login.name);
  }
}
