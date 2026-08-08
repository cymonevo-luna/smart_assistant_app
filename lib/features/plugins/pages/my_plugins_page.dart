import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/auth_controller.dart';
import '../models/installed_plugin.dart';
import '../models/plugin_setup_status.dart';
import '../plugins_provider.dart';

class MyPluginsPage extends ConsumerStatefulWidget {
  const MyPluginsPage({super.key});

  @override
  ConsumerState<MyPluginsPage> createState() => _MyPluginsPageState();
}

class _MyPluginsPageState extends ConsumerState<MyPluginsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAuth());
  }

  void _guardAuth() {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated && mounted) {
      context.goNamed(AppRoute.login.name);
    }
  }

  Future<void> _toggleEnabled(InstalledPlugin plugin, bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(installedPluginsProvider.notifier)
        .setEnabled(plugin.id, enabled);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  Future<void> _confirmUninstall(InstalledPlugin plugin) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.uninstallPlugin),
        content: Text(l10n.uninstallPluginConfirm(plugin.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.uninstall),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(installedPluginsProvider.notifier)
        .uninstall(plugin.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginUninstalled(plugin.name))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  void _onSetupTap(InstalledPlugin plugin) {
    if (plugin.setupStatus == PluginSetupStatus.completed) return;
    context.pushNamed(
      AppRoute.pluginSetup.name,
      pathParameters: {'id': plugin.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final installedAsync = ref.watch(installedPluginsProvider);

    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated && mounted) {
        context.goNamed(AppRoute.login.name);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: AppText.heading(l10n.myPlugins),
        actions: [
          IconButton(
            tooltip: l10n.pluginStore,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => context.pushNamed(AppRoute.pluginStore.name),
          ),
        ],
      ),
      body: installedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.body(l10n.pluginLoadFailed),
              const VGap(AppSpacing.md),
              AppButton(
                l10n.retry,
                expand: false,
                onPressed: () => ref.invalidate(installedPluginsProvider),
              ),
            ],
          ),
        ),
        data: (plugins) {
          if (plugins.isEmpty) {
            return _EmptyState(
              onBrowseStore: () => context.pushNamed(AppRoute.pluginStore.name),
            );
          }
          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: plugins.length,
            separatorBuilder: (_, _) => const VGap(AppSpacing.sm),
            itemBuilder: (context, index) {
              final plugin = plugins[index];
              return _InstalledTile(
                plugin: plugin,
                onToggle: (enabled) => _toggleEnabled(plugin, enabled),
                onUninstall: () => _confirmUninstall(plugin),
                onSetupTap: () => _onSetupTap(plugin),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowseStore});

  final VoidCallback onBrowseStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_off_outlined,
              size: 56,
              color: context.tokens.textSecondary,
            ),
            const VGap(AppSpacing.md),
            AppText.title(l10n.noPluginsInstalled),
            const VGap(AppSpacing.xs),
            AppText.body(l10n.noPluginsInstalledSubtitle, muted: true),
            const VGap(AppSpacing.lg),
            AppButton(l10n.browsePluginStore, onPressed: onBrowseStore),
          ],
        ),
      ),
    );
  }
}

class _InstalledTile extends StatelessWidget {
  const _InstalledTile({
    required this.plugin,
    required this.onToggle,
    required this.onUninstall,
    required this.onSetupTap,
  });

  final InstalledPlugin plugin;
  final ValueChanged<bool> onToggle;
  final VoidCallback onUninstall;
  final VoidCallback onSetupTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setupIncomplete = plugin.setupStatus != PluginSetupStatus.completed;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.title(plugin.name),
                      const VGap(AppSpacing.xs),
                      AppText.body(plugin.description, muted: true),
                    ],
                  ),
                ),
                const HGap(AppSpacing.sm),
                _SetupStatusBadge(
                  status: plugin.setupStatus,
                  onTap: setupIncomplete ? onSetupTap : null,
                ),
              ],
            ),
            const VGap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppText.label(l10n.enabled),
                ),
                Switch(
                  key: ValueKey('plugin_enabled_${plugin.id}'),
                  value: plugin.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const VGap(AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                l10n.uninstall,
                variant: AppButtonVariant.text,
                expand: false,
                size: AppButtonSize.small,
                onPressed: onUninstall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStatusBadge extends StatelessWidget {
  const _SetupStatusBadge({required this.status, this.onTap});

  final PluginSetupStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (label, color) = switch (status) {
      PluginSetupStatus.notStarted => (l10n.setupNotStarted, tokens.warning),
      PluginSetupStatus.inProgress => (l10n.setupInProgress, tokens.info),
      PluginSetupStatus.completed => (l10n.setupCompleted, tokens.success),
    };

    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: AppText.label(
        label,
        color: color,
        weight: FontWeight.w600,
      ),
    );

    if (onTap == null) return badge;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: badge,
    );
  }
}
