import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/network/api_exception.dart';
import 'data/plugin_repository.dart';
import 'models/plugin_setup_status.dart';
import 'plugins_provider.dart';

enum PluginFormSetupPhase {
  idle,
  submitting,
  completed,
  failed,
}

class PluginFormSetupState {
  const PluginFormSetupState({
    this.phase = PluginFormSetupPhase.idle,
    this.errorMessage,
  });

  final PluginFormSetupPhase phase;
  final String? errorMessage;

  PluginFormSetupState copyWith({
    PluginFormSetupPhase? phase,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PluginFormSetupState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PluginFormSetupController extends Notifier<PluginFormSetupState> {
  PluginRepository get _repo => locator<PluginRepository>();

  String? _pluginId;

  @override
  PluginFormSetupState build() => const PluginFormSetupState();

  void bind(String pluginId) {
    if (_pluginId == pluginId) return;
    _pluginId = pluginId;
    state = const PluginFormSetupState();
  }

  Future<void> submitApiKey(String apiKey) async {
    final pluginId = _pluginId;
    if (pluginId == null || state.phase == PluginFormSetupPhase.submitting) {
      return;
    }

    state = state.copyWith(
      phase: PluginFormSetupPhase.submitting,
      clearError: true,
    );

    try {
      final response = await _repo.submitFormSetup(pluginId, {
        'api_key': apiKey,
      });
      if (response.setupStatus == PluginSetupStatus.completed) {
        state = state.copyWith(phase: PluginFormSetupPhase.completed);
        await ref.read(installedPluginsProvider.notifier).refresh();
        return;
      }
      if (response.setupStatus == PluginSetupStatus.failed) {
        state = state.copyWith(
          phase: PluginFormSetupPhase.failed,
          errorMessage:
              response.setupError ?? 'Setup failed. Please try again.',
        );
        await ref.read(installedPluginsProvider.notifier).refresh();
        return;
      }
      state = state.copyWith(phase: PluginFormSetupPhase.completed);
      await ref.read(installedPluginsProvider.notifier).refresh();
    } on ApiException catch (error) {
      state = state.copyWith(
        phase: PluginFormSetupPhase.failed,
        errorMessage: error.message,
      );
    }
  }

  void retry() {
    state = const PluginFormSetupState();
  }
}

final pluginFormSetupControllerProvider =
    NotifierProvider<PluginFormSetupController, PluginFormSetupState>(
  PluginFormSetupController.new,
);
