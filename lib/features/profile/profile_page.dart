import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import '../auth/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((s) => s.user));
    final name = user?.name ?? 'Alex Johnson';
    final email = user?.email ?? 'alex@example.com';

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
                AppAvatar(name: name, imageUrl: user?.avatarUrl),
                const VGap(AppSpacing.md),
                AppText(
                  name,
                  variant: AppTextVariant.titleLarge,
                  weight: FontWeight.w700,
                ),
                const VGap(AppSpacing.xxs),
                AppText.body(email, muted: true),
              ],
            ),
          ),
          const VGap(AppSpacing.lg),
          _StatsCard(l10n: l10n),
          const VGap(AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.person_outline,
                  title: l10n.myProfile,
                  onTap: () {},
                ),
                _divider(),
                AppListTile(
                  icon: Icons.emoji_events_outlined,
                  title: l10n.achievements,
                  onTap: () {},
                ),
                _divider(),
                AppListTile(
                  icon: Icons.history,
                  title: l10n.activityHistory,
                  onTap: () {},
                ),
                _divider(),
                AppListTile(
                  icon: Icons.bookmark_border,
                  title: l10n.savedItems,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const VGap(AppSpacing.lg),
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

  Widget _divider() => const Divider(
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
      );

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.goNamed(AppRoute.login.name);
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          _Stat(value: '12', label: l10n.projects),
          _StatDivider(),
          _Stat(value: '48', label: l10n.tasks),
          _StatDivider(),
          _Stat(value: '85%', label: l10n.completed),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AppText(
            value,
            variant: AppTextVariant.headlineSmall,
            weight: FontWeight.w700,
            color: context.colors.primary,
          ),
          const VGap(AppSpacing.xxs),
          AppText.caption(label, maxLines: 1),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: context.tokens.border,
    );
  }
}
