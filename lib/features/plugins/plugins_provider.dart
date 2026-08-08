import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_controller.dart';
import 'data/plugin_repository.dart';
import 'models/installed_plugin.dart';
import 'models/plugin_catalog_item.dart';

class PluginCatalogNotifier extends AsyncNotifier<List<PluginCatalogItem>> {
  PluginRepository get _repo => locator<PluginRepository>();

  @override
  Future<List<PluginCatalogItem>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];
    return _repo.listCatalog();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listCatalog());
  }
}

class InstalledPluginsNotifier extends AsyncNotifier<List<InstalledPlugin>> {
  PluginRepository get _repo => locator<PluginRepository>();

  @override
  Future<List<InstalledPlugin>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];
    return _repo.listInstalled();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listInstalled());
  }

  Future<bool> install(String slug) async {
    try {
      final installed = await _repo.install(slug);
      final current = state.asData?.value ?? [];
      state = AsyncData([...current, installed]);
      ref.invalidate(pluginCatalogProvider);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> uninstall(String pluginId) async {
    try {
      await _repo.uninstall(pluginId);
      final current = state.asData?.value ?? [];
      state = AsyncData(
        current.where((plugin) => plugin.id != pluginId).toList(),
      );
      ref.invalidate(pluginCatalogProvider);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> setEnabled(String pluginId, bool enabled) async {
    final previous = state.asData?.value;
    if (previous == null) return false;

    state = AsyncData(
      previous
          .map(
            (plugin) => plugin.id == pluginId
                ? plugin.copyWith(enabled: enabled)
                : plugin,
          )
          .toList(),
    );

    try {
      final updated = await _repo.setEnabled(pluginId, enabled);
      state = AsyncData(
        previous
            .map((plugin) => plugin.id == pluginId ? updated : plugin)
            .toList(),
      );
      return true;
    } on ApiException {
      state = AsyncData(previous);
      return false;
    }
  }
}

final pluginCatalogProvider =
    AsyncNotifierProvider<PluginCatalogNotifier, List<PluginCatalogItem>>(
  PluginCatalogNotifier.new,
);

final installedPluginsProvider =
    AsyncNotifierProvider<InstalledPluginsNotifier, List<InstalledPlugin>>(
  InstalledPluginsNotifier.new,
);

final installedPluginSlugsProvider = Provider<Set<String>>((ref) {
  final installed = ref.watch(installedPluginsProvider);
  return installed.maybeWhen(
    data: (plugins) => plugins.map((plugin) => plugin.slug).toSet(),
    orElse: () => {},
  );
});
