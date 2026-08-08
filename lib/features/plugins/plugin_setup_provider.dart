import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/network/api_exception.dart';
import 'data/plugin_repository.dart';
import 'models/installed_plugin.dart';
import 'models/plugin_setup_status.dart';
import 'models/plugin_setup_status_response.dart';
import 'plugins_provider.dart';
import 'services/plugin_auth_url_launcher.dart';
import 'services/plugin_setup_deep_link_service.dart';

enum PluginSetupPhase {
  idle,
  starting,
  awaitingAuthorization,
  polling,
  completed,
  failed,
}

class PluginSetupState {
  const PluginSetupState({
    this.phase = PluginSetupPhase.idle,
    this.setupError,
    this.authorizationUrl,
    this.useWebView = false,
  });

  final PluginSetupPhase phase;
  final String? setupError;
  final String? authorizationUrl;
  final bool useWebView;

  PluginSetupState copyWith({
    PluginSetupPhase? phase,
    String? setupError,
    String? authorizationUrl,
    bool? useWebView,
    bool clearError = false,
  }) {
    return PluginSetupState(
      phase: phase ?? this.phase,
      setupError: clearError ? null : setupError ?? this.setupError,
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      useWebView: useWebView ?? this.useWebView,
    );
  }
}

class PluginSetupController extends Notifier<PluginSetupState> {
  static const pollInterval = Duration(seconds: 2);
  static const pollTimeout = Duration(seconds: 30);

  PluginRepository get _repo => locator<PluginRepository>();
  PluginAuthUrlLauncher get _urlLauncher =>
      locator<PluginAuthUrlLauncher>();
  PluginSetupDeepLinkService get _deepLinks =>
      locator<PluginSetupDeepLinkService>();

  String? _pluginId;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  StreamSubscription<PluginSetupDeepLinkEvent>? _deepLinkSubscription;

  @override
  PluginSetupState build() {
    ref.onDispose(_dispose);
    return const PluginSetupState();
  }

  void bind(String pluginId) {
    if (_pluginId == pluginId) return;
    _pluginId = pluginId;
    _listenForDeepLinks();
  }

  InstalledPlugin? pluginFor(String pluginId) {
    final installed = ref.read(installedPluginsProvider);
    return installed.maybeWhen(
      data: (plugins) {
        for (final plugin in plugins) {
          if (plugin.id == pluginId) return plugin;
        }
        return null;
      },
      orElse: () => null,
    );
  }

  Future<void> connectGoogleAccount() async {
    final pluginId = _pluginId;
    if (pluginId == null || state.phase == PluginSetupPhase.starting) return;

    state = state.copyWith(
      phase: PluginSetupPhase.starting,
      clearError: true,
    );

    try {
      final response = await _repo.startSetup(pluginId);
      final launched = await _urlLauncher.launchAuthorizationUrl(
        response.authorizationUrl,
      );

      state = state.copyWith(
        phase: PluginSetupPhase.awaitingAuthorization,
        authorizationUrl: response.authorizationUrl,
        useWebView: !launched,
        clearError: true,
      );

      if (launched) {
        await _startPolling();
      }
    } on ApiException catch (error) {
      state = state.copyWith(
        phase: PluginSetupPhase.failed,
        setupError: error.message,
      );
    }
  }

  void onWebViewAuthorizationComplete() {
    unawaited(_startPolling());
  }

  Future<void> handleDeepLink(PluginSetupDeepLinkEvent event) async {
    if (_pluginId == null) {
      final pluginId = await _resolveInProgressPluginId();
      if (pluginId == null) {
        await ref.read(installedPluginsProvider.notifier).refresh();
        if (event.status == PluginSetupDeepLinkStatus.failed) {
          state = state.copyWith(
            phase: PluginSetupPhase.failed,
            setupError: state.setupError ?? 'Setup was not completed.',
          );
        }
        return;
      }
      _pluginId = pluginId;
      _listenForDeepLinks();
    }

    if (event.status == PluginSetupDeepLinkStatus.failed) {
      _stopPolling();
      state = state.copyWith(
        phase: PluginSetupPhase.failed,
        setupError: state.setupError ?? 'Setup was not completed.',
      );
      await ref.read(installedPluginsProvider.notifier).refresh();
      return;
    }

    await _pollOnce();
    if (state.phase != PluginSetupPhase.completed &&
        state.phase != PluginSetupPhase.failed) {
      await _startPolling();
    }
  }

  void retry() {
    _stopPolling();
    state = const PluginSetupState();
  }

  void _listenForDeepLinks() {
    _deepLinkSubscription ??= _deepLinks.events.listen((event) {
      unawaited(handleDeepLink(event));
    });
  }

  Future<String?> _resolveInProgressPluginId() async {
    final plugins = await ref.read(installedPluginsProvider.future);
    for (final plugin in plugins) {
      if (plugin.setupStatus == PluginSetupStatus.inProgress) {
        return plugin.id;
      }
    }
    return null;
  }

  Future<void> _startPolling() async {
    if (_pluginId == null) return;
    _stopPolling();
    _pollStartedAt = DateTime.now();
    state = state.copyWith(phase: PluginSetupPhase.polling, clearError: true);
    await _pollOnce();
    if (state.phase == PluginSetupPhase.completed ||
        state.phase == PluginSetupPhase.failed) {
      return;
    }
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
  }

  Future<void> _pollOnce() async {
    final pluginId = _pluginId;
    if (pluginId == null) return;

    if (_pollStartedAt != null &&
        DateTime.now().difference(_pollStartedAt!) > pollTimeout) {
      _stopPolling();
      state = state.copyWith(
        phase: PluginSetupPhase.failed,
        setupError: 'Setup timed out. Please try again.',
      );
      return;
    }

    try {
      final status = await _repo.getSetupStatus(pluginId);
      await _applyStatus(status);
    } on ApiException catch (error) {
      _stopPolling();
      state = state.copyWith(
        phase: PluginSetupPhase.failed,
        setupError: error.message,
      );
    }
  }

  Future<void> _applyStatus(PluginSetupStatusResponse status) async {
    switch (status.setupStatus) {
      case PluginSetupStatus.completed:
        _stopPolling();
        state = state.copyWith(phase: PluginSetupPhase.completed, clearError: true);
        await ref.read(installedPluginsProvider.notifier).refresh();
      case PluginSetupStatus.failed:
        _stopPolling();
        state = state.copyWith(
          phase: PluginSetupPhase.failed,
          setupError: status.setupError ?? 'Setup failed. Please try again.',
        );
        await ref.read(installedPluginsProvider.notifier).refresh();
      case PluginSetupStatus.inProgress:
      case PluginSetupStatus.notStarted:
        return;
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollStartedAt = null;
  }

  void _dispose() {
    _stopPolling();
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
  }
}

final pluginSetupControllerProvider =
    NotifierProvider<PluginSetupController, PluginSetupState>(
  PluginSetupController.new,
);
