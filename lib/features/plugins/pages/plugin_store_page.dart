import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/auth_controller.dart';
import '../models/plugin_catalog_item.dart';
import '../plugins_provider.dart';

class PluginStorePage extends ConsumerStatefulWidget {
  const PluginStorePage({super.key});

  @override
  ConsumerState<PluginStorePage> createState() => _PluginStorePageState();
}

class _PluginStorePageState extends ConsumerState<PluginStorePage> {
  final Set<String> _installingSlugs = <String>{};

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

  Future<void> _install(PluginCatalogItem item) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _installingSlugs.add(item.slug));
    final ok = await ref.read(installedPluginsProvider.notifier).install(
          item.slug,
        );
    if (!mounted) return;
    setState(() => _installingSlugs.remove(item.slug));
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginInstalled(item.name))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pluginActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: AppText.heading(l10n.pluginStore),
        actions: [
          IconButton(
            tooltip: l10n.myPlugins,
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.pushNamed(AppRoute.myPlugins.name),
          ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: l10n.pluginLoadFailed,
          onRetry: () => ref.invalidate(pluginCatalogProvider),
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
              final isInstalling = _installingSlugs.contains(plugin.slug);
              return _CatalogTile(
                plugin: plugin,
                isInstalled: isInstalled,
                isInstalling: isInstalling,
                onInstall: () => _install(plugin),
              );
            },
          );
        },
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
