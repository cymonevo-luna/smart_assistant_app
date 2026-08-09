import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/network/api_exception.dart';
import 'data/plugin_repository.dart';
import 'models/plugin_setup_status.dart';
import 'plugins_provider.dart';

enum PluginFormSetupPhase {
  loading,
  idle,
  submitting,
  completed,
}

class PluginFormSetupState {
  const PluginFormSetupState({
    this.phase = PluginFormSetupPhase.loading,
    this.errorMessage,
    this.connectedToolkits = const [],
    this.connectedAccountsCount,
    this.isNetworkError = false,
  });

  final PluginFormSetupPhase phase;
  final String? errorMessage;
  final List<String> connectedToolkits;
  final int? connectedAccountsCount;
  final bool isNetworkError;

  PluginFormSetupState copyWith({
    PluginFormSetupPhase? phase,
    String? errorMessage,
    List<String>? connectedToolkits,
    int? connectedAccountsCount,
    bool? isNetworkError,
    bool clearError = false,
  }) {
    return PluginFormSetupState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      connectedToolkits: connectedToolkits ?? this.connectedToolkits,
      connectedAccountsCount:
          connectedAccountsCount ?? this.connectedAccountsCount,
      isNetworkError: isNetworkError ?? this.isNetworkError,
    );
  }
}

class PluginFormSetupController extends Notifier<PluginFormSetupState> {
  PluginRepository get _repo => locator<PluginRepository>();

  String? _pluginId;

  @override
  PluginFormSetupState build() => const PluginFormSetupState();

  void bind(String pluginId) {
    if (_pluginId == pluginId && state.phase != PluginFormSetupPhase.loading) {
      return;
    }
    _pluginId = pluginId;
    state = const PluginFormSetupState();
    loadStatus();
  }

  Future<void> loadStatus() async {
    final pluginId = _pluginId;
    if (pluginId == null) return;

    state = state.copyWith(
      phase: PluginFormSetupPhase.loading,
      clearError: true,
      isNetworkError: false,
    );

    try {
      final response = await _repo.getSetupStatus(pluginId);
      if (response.setupStatus == PluginSetupStatus.completed) {
        state = PluginFormSetupState(
          phase: PluginFormSetupPhase.completed,
          connectedToolkits: response.connectedToolkits,
          connectedAccountsCount: response.connectedAccountsCount,
        );
        return;
      }
      state = PluginFormSetupState(
        phase: PluginFormSetupPhase.idle,
        connectedToolkits: response.connectedToolkits,
        connectedAccountsCount: response.connectedAccountsCount,
        errorMessage: response.setupStatus == PluginSetupStatus.failed
            ? response.setupError ?? 'Setup failed. Please try again.'
            : null,
      );
    } on ApiException catch (error) {
      state = PluginFormSetupState(
        phase: PluginFormSetupPhase.loading,
        errorMessage: error.message,
        isNetworkError: true,
      );
    }
  }

  Future<void> submitApiKey(String apiKey) async {
    final pluginId = _pluginId;
    if (pluginId == null || state.phase == PluginFormSetupPhase.submitting) {
      return;
    }

    state = state.copyWith(
      phase: PluginFormSetupPhase.submitting,
      clearError: true,
      isNetworkError: false,
    );

    try {
      final response = await _repo.submitFormSetup(pluginId, {
        'api_key': apiKey,
      });
      if (response.setupStatus == PluginSetupStatus.completed) {
        state = PluginFormSetupState(
          phase: PluginFormSetupPhase.completed,
          connectedToolkits: response.connectedToolkits,
          connectedAccountsCount: response.connectedAccountsCount,
        );
        await ref.read(installedPluginsProvider.notifier).refresh();
        return;
      }
      if (response.setupStatus == PluginSetupStatus.failed) {
        state = PluginFormSetupState(
          phase: PluginFormSetupPhase.idle,
          errorMessage:
              response.setupError ?? 'Setup failed. Please try again.',
          connectedToolkits: response.connectedToolkits,
          connectedAccountsCount: response.connectedAccountsCount,
        );
        await ref.read(installedPluginsProvider.notifier).refresh();
        return;
      }
      state = PluginFormSetupState(
        phase: PluginFormSetupPhase.completed,
        connectedToolkits: response.connectedToolkits,
        connectedAccountsCount: response.connectedAccountsCount,
      );
      await ref.read(installedPluginsProvider.notifier).refresh();
    } on ApiException catch (error) {
      state = PluginFormSetupState(
        phase: PluginFormSetupPhase.idle,
        errorMessage: error.message,
        isNetworkError: error.type == ApiErrorType.network ||
            error.type == ApiErrorType.timeout,
        connectedToolkits: state.connectedToolkits,
        connectedAccountsCount: state.connectedAccountsCount,
      );
    }
  }

  void retry() {
    loadStatus();
  }
}

final pluginFormSetupControllerProvider =
    NotifierProvider<PluginFormSetupController, PluginFormSetupState>(
  PluginFormSetupController.new,
);
