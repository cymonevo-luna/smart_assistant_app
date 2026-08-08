import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

/// Demonstrates the design system + infrastructure: theming, localization,
/// routing and reusable components assembled into a mockup-style home. Use it
/// as a reference, then delete it once your own screens exist.
class ShowcasePage extends ConsumerWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeProvider);
    final colors = context.colors;
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: AppText.heading(l10n.home),
        actions: [
          IconButton(
            tooltip: l10n.language,
            onPressed: () => _toggleLocale(ref),
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            onPressed: ref.read(themeProvider.notifier).toggleBrightness,
            icon: Icon(
              theme.mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const HGap(AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoute.details.name),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          _GreetingBanner(l10n: l10n),
          const VGap(AppSpacing.lg),
          AppSectionHeader(title: l10n.overview),
          const VGap(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppStatCard(
                  icon: Icons.list_alt_rounded,
                  color: colors.primary,
                  value: '24',
                  label: l10n.tasks,
                  trend: '+12%',
                ),
              ),
              const HGap(AppSpacing.sm),
              Expanded(
                child: AppStatCard(
                  icon: Icons.check_circle_outline,
                  color: tokens.success,
                  value: '16',
                  label: 'Completed',
                  trend: '+8%',
                ),
              ),
              const HGap(AppSpacing.sm),
              Expanded(
                child: AppStatCard(
                  icon: Icons.timelapse_rounded,
                  color: tokens.warning,
                  value: '8',
                  label: 'In Progress',
                  trend: '-4%',
                  trendPositive: false,
                ),
              ),
            ],
          ),
          const VGap(AppSpacing.lg),
          AppSectionHeader(
            title: l10n.recentActivity,
            actionLabel: l10n.viewAll,
            onAction: () {},
          ),
          const VGap(AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.design_services_outlined,
                  iconColor: colors.primary,
                  title: 'Design Review',
                  subtitle: '2h ago',
                  showChevron: false,
                  onTap: () {},
                ),
                Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                AppListTile(
                  icon: Icons.groups_outlined,
                  iconColor: tokens.success,
                  title: 'Project Meeting',
                  subtitle: '4h ago',
                  showChevron: false,
                  onTap: () {},
                ),
                Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                AppListTile(
                  icon: Icons.description_outlined,
                  iconColor: tokens.warning,
                  title: 'Update Documentation',
                  subtitle: '1d ago',
                  showChevron: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const VGap(AppSpacing.lg),
          AppSectionHeader(title: l10n.themeColor),
          const VGap(AppSpacing.sm),
          const AppCard(child: _AccentPicker()),
          const VGap(AppSpacing.lg),
          const AppSectionHeader(title: 'Components'),
          const VGap(AppSpacing.sm),
          const _ComponentsDemo(),
        ],
      ),
    );
  }

  void _toggleLocale(WidgetRef ref) {
    final current = ref.read(localeProvider);
    final next = current?.languageCode == 'id'
        ? const Locale('en')
        : const Locale('id');
    ref.read(localeProvider.notifier).setLocale(next);
  }
}

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, Colors.black, 0.2)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  l10n.greeting('Alex'),
                  variant: AppTextVariant.titleLarge,
                  color: colors.onPrimary,
                ),
                const VGap(AppSpacing.xxs),
                AppText(
                  l10n.haveAGreatDay,
                  variant: AppTextVariant.bodyMedium,
                  color: colors.onPrimary.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
          Icon(Icons.wb_sunny_rounded, color: colors.onPrimary, size: 40),
        ],
      ),
    );
  }
}

class _AccentPicker extends ConsumerWidget {
  const _AccentPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider).accent;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final accent in AppAccent.values)
          GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).setAccent(accent),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: accent.seed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == accent
                      ? context.tokens.textPrimary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: selected == accent
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ComponentsDemo extends StatelessWidget {
  const _ComponentsDemo();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTextField(
            label: 'Email',
            hint: 'example@email.com',
            prefixIcon: Icons.mail_outline,
          ),
          const VGap(AppSpacing.md),
          const AppTextField(
            label: 'Password',
            hint: 'Enter password',
            prefixIcon: Icons.lock_outline,
            obscure: true,
          ),
          const VGap(AppSpacing.lg),
          AppButton('Primary Button', onPressed: () {}),
          const VGap(AppSpacing.sm),
          AppButton('Secondary Button',
              variant: AppButtonVariant.secondary, onPressed: () {}),
          const VGap(AppSpacing.sm),
          AppSocialButton(
            label: 'Continue with Google',
            icon: const Icon(Icons.g_mobiledata, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
