import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/installed_plugin.dart';
import '../models/plugin_setup_status.dart';
import '../plugin_form_setup_provider.dart';

class PluginFormSetupPage extends ConsumerStatefulWidget {
  const PluginFormSetupPage({super.key, required this.plugin});

  final InstalledPlugin plugin;

  @override
  ConsumerState<PluginFormSetupPage> createState() =>
      _PluginFormSetupPageState();
}

class _PluginFormSetupPageState extends ConsumerState<PluginFormSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pluginFormSetupControllerProvider.notifier)
          .bind(widget.plugin.id);
    });
  }

  @override
  void didUpdateWidget(covariant PluginFormSetupPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plugin.id != widget.plugin.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(pluginFormSetupControllerProvider.notifier)
            .bind(widget.plugin.id);
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.clear();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(pluginFormSetupControllerProvider.notifier)
        .submitApiKey(_apiKeyController.text.trim());
    _apiKeyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setupState = ref.watch(pluginFormSetupControllerProvider);
    final tokens = context.tokens;

    if (setupState.phase == PluginFormSetupPhase.loading) {
      if (setupState.isNetworkError) {
        return _ErrorBody(
          message: setupState.errorMessage ?? l10n.pluginLoadFailed,
          onRetry: () =>
              ref.read(pluginFormSetupControllerProvider.notifier).retry(),
          retryLabel: l10n.retry,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (setupState.phase == PluginFormSetupPhase.completed ||
        widget.plugin.setupStatus == PluginSetupStatus.completed) {
      return _CompletedBody(
        pluginName: widget.plugin.name,
        connectedToolkits: setupState.connectedToolkits,
        onDone: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoute.managePlugins.path);
          }
        },
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.title(widget.plugin.name),
                    const VGap(AppSpacing.sm),
                    AppText.body(widget.plugin.description, muted: true),
                    const VGap(AppSpacing.md),
                    AppText.body(l10n.pluginFormSetupInstructions),
                  ],
                ),
              ),
            ),
            const VGap(AppSpacing.lg),
            AppTextField(
              key: const ValueKey('composio_api_key_field'),
              controller: _apiKeyController,
              label: l10n.composioApiKeyLabel,
              obscure: true,
              autocomplete: false,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.composioApiKeyRequired;
                }
                return null;
              },
              onSubmitted: (_) => _submit(),
            ),
            if (setupState.errorMessage != null) ...[
              const VGap(AppSpacing.sm),
              AppText.body(
                setupState.errorMessage!,
                color: tokens.danger,
              ),
              if (setupState.isNetworkError) ...[
                const VGap(AppSpacing.sm),
                AppButton(
                  l10n.retry,
                  key: const ValueKey('composio_setup_retry'),
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: _submit,
                ),
              ],
            ],
            const VGap(AppSpacing.lg),
            AppButton(
              l10n.saveApiKey,
              key: const ValueKey('save_composio_api_key'),
              loading: setupState.phase == PluginFormSetupPhase.submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedBody extends StatelessWidget {
  const _CompletedBody({
    required this.pluginName,
    required this.connectedToolkits,
    required this.onDone,
  });

  final String pluginName;
  final List<String> connectedToolkits;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: tokens.success),
            const VGap(AppSpacing.md),
            AppText.title(l10n.pluginSetupSuccess, align: TextAlign.center),
            const VGap(AppSpacing.sm),
            AppText.body(pluginName, muted: true, align: TextAlign.center),
            const VGap(AppSpacing.lg),
            if (connectedToolkits.isNotEmpty) ...[
              AppText.label(l10n.composioConnectedApps),
              const VGap(AppSpacing.sm),
              Wrap(
                key: const ValueKey('composio_connected_toolkits'),
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: connectedToolkits
                    .map(
                      (toolkit) => Chip(
                        label: Text(toolkit),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              AppText.body(
                l10n.composioNoConnectedApps,
                muted: true,
                align: TextAlign.center,
              ),
              const VGap(AppSpacing.sm),
              TextButton(
                key: const ValueKey('composio_connect_apps_link'),
                onPressed: () {
                  final uri = Uri.parse(l10n.composioDashboardUrl);
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Text(l10n.composioConnectApps),
              ),
            ],
            const VGap(AppSpacing.lg),
            AppButton(
              l10n.done,
              key: const ValueKey('composio_setup_done'),
              onPressed: onDone,
            ),
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
