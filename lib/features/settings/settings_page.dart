import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = theme.mode == ThemeMode.dark;
    final isIndonesian = locale?.languageCode == 'id';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: AppText.heading(l10n.settings),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          AppSectionHeader(title: l10n.account),
          const VGap(AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.person_outline,
                  title: l10n.personalInformation,
                  onTap: () {},
                ),
                _divider(),
                AppListTile(
                  icon: Icons.shield_outlined,
                  title: l10n.security,
                  onTap: () {},
                ),
                _divider(),
                AppListTile(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  onTap: () {},
                ),
                _divider(),
                AppListTile(
                  icon: Icons.lock_outline,
                  title: l10n.privacy,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const VGap(AppSpacing.lg),
          AppSectionHeader(title: l10n.preferences),
          const VGap(AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                AppListTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.darkMode,
                  showChevron: false,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (on) => ref
                        .read(themeProvider.notifier)
                        .setThemeMode(on ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
                _divider(),
                AppListTile(
                  icon: Icons.palette_outlined,
                  title: l10n.appearance,
                  onTap: () => _showAccentPicker(context, ref),
                  trailing: _AccentDot(color: theme.accent.seed),
                ),
                _divider(),
                AppListTile(
                  icon: Icons.translate,
                  title: l10n.language,
                  trailingText: isIndonesian ? 'Bahasa Indonesia' : l10n.english,
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(isIndonesian ? 'en' : 'id')),
                ),
                _divider(),
                AppListTile(
                  icon: Icons.info_outline,
                  title: l10n.about,
                  onTap: () => _showAbout(context, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
      );

  void _showAccentPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final selected = ref.read(themeProvider).accent;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.title(l10n.themeColor),
              const VGap(AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final accent in AppAccent.values)
                    GestureDetector(
                      onTap: () {
                        ref.read(themeProvider.notifier).setAccent(accent);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 44,
                        width: 44,
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
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: '1.0.0',
      applicationLegalese: l10n.appTagline,
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
