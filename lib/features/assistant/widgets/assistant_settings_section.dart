import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../assistant_settings_provider.dart';

class AssistantSettingsSection extends ConsumerStatefulWidget {
  const AssistantSettingsSection({super.key});

  @override
  ConsumerState<AssistantSettingsSection> createState() =>
      _AssistantSettingsSectionState();
}

class _AssistantSettingsSectionState
    extends ConsumerState<AssistantSettingsSection> {
  TextEditingController? _wakeWordController;
  String? _wakeWordError;
  Timer? _debounce;
  String? _lastSyncedWakeWord;

  @override
  void dispose() {
    _debounce?.cancel();
    _wakeWordController?.dispose();
    super.dispose();
  }

  void _syncController(String wakeWord) {
    if (_lastSyncedWakeWord == wakeWord) return;
    _lastSyncedWakeWord = wakeWord;
    _wakeWordController ??= TextEditingController(text: wakeWord);
    if (_wakeWordController!.text != wakeWord) {
      _wakeWordController!.text = wakeWord;
    }
  }

  void _onWakeWordChanged(String value) {
    if (_wakeWordError != null) {
      setState(() => _wakeWordError = null);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _saveWakeWord());
  }

  Future<void> _saveWakeWord() async {
    final l10n = AppLocalizations.of(context);
    final value = _wakeWordController?.text ?? '';
    if (value.trim().isEmpty) {
      setState(() => _wakeWordError = l10n.wakeWordRequired);
      return;
    }

    final ok = await ref.read(assistantSettingsProvider.notifier).setWakeWord(value);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assistantSettingsSaveFailed)),
      );
    }
  }

  Future<void> _onActiveListeningChanged(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final ok =
        await ref.read(assistantSettingsProvider.notifier).setActiveListening(
              enabled,
            );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assistantSettingsSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(assistantSettingsProvider);

    return settingsAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppText.body(error.toString()),
        ),
      ),
      data: (settings) {
        _syncController(settings.wakeWord);
        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: AppTextField(
                  label: l10n.wakeWord,
                  controller: _wakeWordController,
                  prefixIcon: Icons.record_voice_over_outlined,
                  onChanged: _onWakeWordChanged,
                  enabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.wakeWordFixedNotice,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_wakeWordError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    _wakeWordError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const Divider(
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
              AppListTile(
                icon: Icons.hearing_outlined,
                title: l10n.activeListening,
                subtitle: l10n.activeListeningSubtitle,
                showChevron: false,
                trailing: Switch(
                  key: const ValueKey('assistant_active_listening'),
                  value: settings.activeListeningEnabled,
                  onChanged: _onActiveListeningChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
