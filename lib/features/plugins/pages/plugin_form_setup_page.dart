import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    if (setupState.phase == PluginFormSetupPhase.completed ||
        widget.plugin.setupStatus == PluginSetupStatus.completed) {
      return _StatusPanel(
        icon: Icons.check_circle_outline,
        color: tokens.success,
        title: l10n.pluginSetupSuccess,
        subtitle: widget.plugin.name,
      );
    }

    if (setupState.phase == PluginFormSetupPhase.failed) {
      return _StatusPanel(
        icon: Icons.error_outline,
        color: tokens.danger,
        title: l10n.pluginSetupFailed,
        subtitle: setupState.errorMessage,
        actionLabel: l10n.pluginSetupRetry,
        onAction: () =>
            ref.read(pluginFormSetupControllerProvider.notifier).retry(),
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
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.composioApiKeyRequired;
                }
                return null;
              },
              onSubmitted: (_) => _submit(),
            ),
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
