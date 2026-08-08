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
  Timer? _thresholdDebounce;
  int? _pendingThreshold;

  static const _minThresholdMeters = 10;
  static const _maxThresholdMeters = 500;
  static const _thresholdStepMeters = 10;

  @override
  void dispose() {
    _debounce?.cancel();
    _thresholdDebounce?.cancel();
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

  int _displayedThresholdMeters(int settingsValue) =>
      _pendingThreshold ?? settingsValue;

  void _onThresholdChanged(double value) {
    final meters = value.round();
    setState(() => _pendingThreshold = meters);
    _thresholdDebounce?.cancel();
    _thresholdDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _saveThreshold(meters),
    );
  }

  Future<void> _saveThreshold(int meters) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(assistantSettingsProvider.notifier)
        .setLocationReminderThreshold(meters);
    if (!mounted) return;
    if (ok) {
      setState(() => _pendingThreshold = null);
      return;
    }
    setState(() => _pendingThreshold = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.assistantSettingsSaveFailed)),
    );
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
        final thresholdMeters =
            _displayedThresholdMeters(settings.locationReminderThresholdMeters);
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
              const Divider(
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.locationReminderDistance,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          l10n.locationReminderDistanceMeters(thresholdMeters),
                          key: const ValueKey('location_reminder_threshold_value'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Slider(
                      key: const ValueKey('location_reminder_threshold_slider'),
                      value: thresholdMeters.toDouble(),
                      min: _minThresholdMeters.toDouble(),
                      max: _maxThresholdMeters.toDouble(),
                      divisions: (_maxThresholdMeters - _minThresholdMeters) ~/
                          _thresholdStepMeters,
                      label: l10n.locationReminderDistanceMeters(thresholdMeters),
                      onChanged: _onThresholdChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
