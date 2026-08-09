import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/installed_plugin.dart';
import '../models/plugin_setup_status.dart';
import '../models/plugin_setup_type.dart';
import '../plugin_setup_provider.dart';
import '../plugins_provider.dart';
import 'plugin_form_setup_page.dart';

class PluginSetupPage extends ConsumerStatefulWidget {
  const PluginSetupPage({super.key, required this.pluginId});

  final String pluginId;

  @override
  ConsumerState<PluginSetupPage> createState() => _PluginSetupPageState();
}

class _PluginSetupPageState extends ConsumerState<PluginSetupPage> {
  @override
  Widget build(BuildContext context) {
    ref.read(pluginSetupControllerProvider.notifier).bind(widget.pluginId);
    final l10n = AppLocalizations.of(context);
    final setupState = ref.watch(pluginSetupControllerProvider);
    final installedAsync = ref.watch(installedPluginsProvider);
    final plugin = installedAsync.maybeWhen(
      data: (plugins) {
        for (final item in plugins) {
          if (item.id == widget.pluginId) return item;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: AppText.heading(l10n.pluginSetup),
      ),
      body: installedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorBody(
          message: l10n.pluginLoadFailed,
          onRetry: () => ref.invalidate(installedPluginsProvider),
          retryLabel: l10n.retry,
        ),
        data: (_) {
          if (plugin == null) {
            return _ErrorBody(
              message: l10n.pluginLoadFailed,
              onRetry: () => ref.invalidate(installedPluginsProvider),
              retryLabel: l10n.retry,
            );
          }

          if (plugin.setupType == PluginSetupType.form) {
            return PluginFormSetupPage(plugin: plugin);
          }

          return _OAuthSetupBody(
            plugin: plugin,
            setupState: setupState,
            onConnect: () => ref
                .read(pluginSetupControllerProvider.notifier)
                .connectGoogleAccount(),
            onRetry: () =>
                ref.read(pluginSetupControllerProvider.notifier).retry(),
            onWebViewComplete: () => ref
                .read(pluginSetupControllerProvider.notifier)
                .onWebViewAuthorizationComplete(),
          );
        },
      ),
    );
  }
}

class _OAuthSetupBody extends StatelessWidget {
  const _OAuthSetupBody({
    required this.plugin,
    required this.setupState,
    required this.onConnect,
    required this.onRetry,
    required this.onWebViewComplete,
  });

  final InstalledPlugin plugin;
  final PluginSetupState setupState;
  final VoidCallback onConnect;
  final VoidCallback onRetry;
  final VoidCallback onWebViewComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;

    if (setupState.phase == PluginSetupPhase.completed ||
        plugin.setupStatus == PluginSetupStatus.completed) {
      return _StatusPanel(
        icon: Icons.check_circle_outline,
        color: tokens.success,
        title: l10n.pluginSetupSuccess,
        subtitle: plugin.name,
      );
    }

    if (setupState.phase == PluginSetupPhase.failed) {
      return _StatusPanel(
        icon: Icons.error_outline,
        color: tokens.danger,
        title: l10n.pluginSetupFailed,
        subtitle: setupState.setupError,
        actionLabel: l10n.pluginSetupRetry,
        onAction: onRetry,
      );
    }

    if (setupState.useWebView && setupState.authorizationUrl != null) {
      return Column(
        children: [
          Expanded(
            child: _AuthorizationWebView(
              url: setupState.authorizationUrl!,
              onComplete: onWebViewComplete,
            ),
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: AppButton(
              l10n.openInBrowser,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                final uri = Uri.tryParse(setupState.authorizationUrl!);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.title(plugin.name),
                  const VGap(AppSpacing.sm),
                  AppText.body(plugin.description, muted: true),
                  const VGap(AppSpacing.md),
                  AppText.body(l10n.pluginOAuthSetupInstructions),
                ],
              ),
            ),
          ),
          const VGap(AppSpacing.lg),
          if (setupState.phase == PluginSetupPhase.polling ||
              setupState.phase == PluginSetupPhase.awaitingAuthorization)
            _StatusPanel(
              icon: Icons.hourglass_top_outlined,
              color: tokens.info,
              title: l10n.pluginSetupWaiting,
              subtitle: plugin.name,
            )
          else
            AppButton(
              l10n.connectGoogleAccount,
              key: const ValueKey('connect_google_account'),
              loading: setupState.phase == PluginSetupPhase.starting,
              onPressed: onConnect,
            ),
        ],
      ),
    );
  }
}

class _AuthorizationWebView extends StatefulWidget {
  const _AuthorizationWebView({
    required this.url,
    required this.onComplete,
  });

  final String url;
  final VoidCallback onComplete;

  @override
  State<_AuthorizationWebView> createState() => _AuthorizationWebViewState();
}

class _AuthorizationWebViewState extends State<_AuthorizationWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.scheme == 'smartassistant' &&
                uri.host == 'plugin-setup' &&
                uri.path == '/complete') {
              widget.onComplete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const VGap(AppSpacing.md),
            AppText.title(title, align: TextAlign.center),
            if (subtitle != null) ...[
              const VGap(AppSpacing.sm),
              AppText.body(subtitle!, muted: true, align: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const VGap(AppSpacing.lg),
              AppButton(actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.body(message, align: TextAlign.center),
            const VGap(AppSpacing.md),
            AppButton(retryLabel, expand: false, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
