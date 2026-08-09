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
import '../models/plugin_catalog_item.dart';
import '../models/plugin_setup_status.dart';
import '../models/plugin_setup_type.dart';
import '../plugins_provider.dart';

enum ManagePluginsTab { installed, available }

class ManagePluginsPage extends ConsumerStatefulWidget {
  const ManagePluginsPage({super.key, this.initialTab = ManagePluginsTab.installed});

  final ManagePluginsTab initialTab;

  @override
  ConsumerState<ManagePluginsPage> createState() => _ManagePluginsPageState();
}

class _ManagePluginsPageState extends ConsumerState<ManagePluginsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _installingSlugs = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == ManagePluginsTab.available ? 1 : 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAuth());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _navigateToSetup(InstalledPlugin plugin) {
    final routeName = plugin.setupType == PluginSetupType.form
        ? AppRoute.composioAiSetup.name
        : AppRoute.pluginSetup.name;
    context.pushNamed(
      routeName,
      pathParameters: {'id': plugin.id},
    );
  }

  void _onSetupTap(InstalledPlugin plugin) {
    if (!plugin.needsSetup) return;
    _navigateToSetup(plugin);
  }

  Future<void> _install(PluginCatalogItem item) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _installingSlugs.add(item.slug));
    final installed = await ref.read(installedPluginsProvider.notifier).install(
          item.slug,
        );
    if (!mounted) return;
    setState(() => _installingSlugs.remove(item.slug));
    if (installed != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginInstalled(item.name))),
      );
      _tabController.animateTo(0);
      if (installed.needsSetup) {
        _navigateToSetup(installed);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final installedAsync = ref.watch(installedPluginsProvider);
    final catalogAsync = ref.watch(pluginCatalogProvider);
    final installedSlugs = ref.watch(installedPluginSlugsProvider);

    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated && mounted) {
        context.goNamed(AppRoute.login.name);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: AppText.heading(l10n.managePlugins),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.pluginsInstalledTab),
            Tab(text: l10n.pluginsAvailableTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InstalledTab(
            installedAsync: installedAsync,
            onRetry: () => ref.invalidate(installedPluginsProvider),
            onToggle: _toggleEnabled,
            onUninstall: _confirmUninstall,
            onSetupTap: _onSetupTap,
            onBrowseAvailable: () => _tabController.animateTo(1),
          ),
          _AvailableTab(
            catalogAsync: catalogAsync,
            installedSlugs: installedSlugs,
            installingSlugs: _installingSlugs,
            onRetry: () => ref.invalidate(pluginCatalogProvider),
            onInstall: _install,
          ),
        ],
      ),
    );
  }
}

class _InstalledTab extends StatelessWidget {
  const _InstalledTab({
    required this.installedAsync,
    required this.onRetry,
    required this.onToggle,
    required this.onUninstall,
    required this.onSetupTap,
    required this.onBrowseAvailable,
  });

  final AsyncValue<List<InstalledPlugin>> installedAsync;
  final VoidCallback onRetry;
  final Future<void> Function(InstalledPlugin plugin, bool enabled) onToggle;
  final Future<void> Function(InstalledPlugin plugin) onUninstall;
  final void Function(InstalledPlugin plugin) onSetupTap;
  final VoidCallback onBrowseAvailable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return installedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _PluginErrorState(
        message: l10n.pluginLoadFailed,
        onRetry: onRetry,
      ),
      data: (plugins) {
        final incompletePlugins = plugins
            .where((plugin) => plugin.needsSetup)
            .toList();

        return Column(
          children: [
            if (incompletePlugins.isNotEmpty)
              MaterialBanner(
                content: Text(l10n.pluginsSetupIncompleteBanner),
                leading: const Icon(Icons.info_outline),
                actions: [
                  TextButton(
                    onPressed: () => onSetupTap(incompletePlugins.first),
                    child: Text(l10n.pluginSetup),
                  ),
                ],
              ),
            Expanded(
              child: plugins.isEmpty
                  ? _InstalledEmptyState(onBrowseAvailable: onBrowseAvailable)
                  : ListView.separated(
                      padding: AppSpacing.screenPadding,
                      itemCount: plugins.length,
                      separatorBuilder: (_, _) => const VGap(AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final plugin = plugins[index];
                        return _InstalledTile(
                          plugin: plugin,
                          onToggle: (enabled) => onToggle(plugin, enabled),
                          onUninstall: () => onUninstall(plugin),
                          onSetupTap: () => onSetupTap(plugin),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AvailableTab extends StatelessWidget {
  const _AvailableTab({
    required this.catalogAsync,
    required this.installedSlugs,
    required this.installingSlugs,
    required this.onRetry,
    required this.onInstall,
  });

  final AsyncValue<List<PluginCatalogItem>> catalogAsync;
  final Set<String> installedSlugs;
  final Set<String> installingSlugs;
  final VoidCallback onRetry;
  final Future<void> Function(PluginCatalogItem item) onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _PluginErrorState(
        message: l10n.pluginLoadFailed,
        onRetry: onRetry,
      ),
      data: (plugins) {
        if (plugins.isEmpty) {
          return Center(child: AppText.body(l10n.pluginStoreEmpty));
        }
        return ListView.separated(
          padding: AppSpacing.screenPadding,
          itemCount: plugins.length,
          separatorBuilder: (_, _) => const VGap(AppSpacing.sm),
          itemBuilder: (context, index) {
            final plugin = plugins[index];
            final isInstalled = installedSlugs.contains(plugin.slug);
            final isInstalling = installingSlugs.contains(plugin.slug);
            return _CatalogTile(
              plugin: plugin,
              isInstalled: isInstalled,
              isInstalling: isInstalling,
              onInstall: () => onInstall(plugin),
            );
          },
        );
      },
    );
  }
}

class _InstalledEmptyState extends StatelessWidget {
  const _InstalledEmptyState({required this.onBrowseAvailable});

  final VoidCallback onBrowseAvailable;

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
            AppButton(l10n.browsePluginStore, onPressed: onBrowseAvailable),
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
    final needsSetup = plugin.needsSetup;

    return AppCard(
      child: InkWell(
        onTap: needsSetup ? onSetupTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.md),
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
                        if (plugin.setupType == PluginSetupType.form) ...[
                          const VGap(AppSpacing.xs),
                          _SetupTypeIndicator(setupType: plugin.setupType!),
                        ],
                      ],
                    ),
                  ),
                  if (plugin.requiredSetup) ...[
                    const HGap(AppSpacing.sm),
                    _SetupStatusBadge(
                      status: plugin.setupStatus,
                      onTap: needsSetup ? onSetupTap : null,
                    ),
                  ],
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
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.plugin,
    required this.isInstalled,
    required this.isInstalling,
    required this.onInstall,
  });

  final PluginCatalogItem plugin;
  final bool isInstalled;
  final bool isInstalling;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.title(plugin.name),
            const VGap(AppSpacing.xs),
            AppText.body(plugin.description, muted: true),
            if (plugin.requiredSetup &&
                plugin.setupType == PluginSetupType.form) ...[
              const VGap(AppSpacing.xs),
              _SetupTypeIndicator(setupType: plugin.setupType!),
            ],
            const VGap(AppSpacing.md),
            AppButton(
              l10n.install,
              expand: false,
              size: AppButtonSize.small,
              loading: isInstalling,
              onPressed: isInstalled || isInstalling ? null : onInstall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupTypeIndicator extends StatelessWidget {
  const _SetupTypeIndicator({required this.setupType});

  final PluginSetupType setupType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final label = switch (setupType) {
      PluginSetupType.form => l10n.pluginSetupApiKeyRequired,
      PluginSetupType.oauthGoogle => l10n.pluginSetupOAuthRequired,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: AppText.label(
        label,
        color: tokens.info,
        weight: FontWeight.w600,
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
      PluginSetupStatus.failed => (l10n.setupFailed, tokens.danger),
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

class _PluginErrorState extends StatelessWidget {
  const _PluginErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.body(message),
            const VGap(AppSpacing.md),
            AppButton(
              l10n.retry,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
