import '../../../core/network/api_client.dart';
import '../models/installed_plugin.dart';
import '../models/plugin_catalog_item.dart';
import '../models/plugin_setup_start_response.dart';
import '../models/plugin_setup_status_response.dart';

class PluginRepository {
  PluginRepository(this._api);

  final ApiClient _api;

  static const catalogPath = '/api/v1/plugins';
  static const installedPath = '/api/v1/users/me/plugins';

  Future<List<PluginCatalogItem>> listCatalog() {
    return _api.get<List<PluginCatalogItem>>(
      catalogPath,
      decoder: (raw) => _parseList(raw, PluginCatalogItem.fromJson),
    );
  }

  Future<List<InstalledPlugin>> listInstalled() {
    return _api.get<List<InstalledPlugin>>(
      installedPath,
      decoder: (raw) => _parseList(raw, InstalledPlugin.fromJson),
    );
  }

  Future<InstalledPlugin> install(String slug) {
    return _api.post<InstalledPlugin>(
      installedPath,
      body: {'slug': slug},
      decoder: (raw) => InstalledPlugin.fromJson(_unwrap(raw)),
    );
  }

  Future<void> uninstall(String pluginId) {
    return _api.delete<void>(
      '$installedPath/$pluginId',
      decoder: (_) {},
    );
  }

  Future<InstalledPlugin> setEnabled(String pluginId, bool enabled) {
    return _api.patch<InstalledPlugin>(
      '$installedPath/$pluginId',
      body: {'enabled': enabled},
      decoder: (raw) => InstalledPlugin.fromJson(_unwrap(raw)),
    );
  }

  static String setupPath(String pluginId) => '$installedPath/$pluginId/setup';

  Future<PluginSetupStartResponse> startSetup(String pluginId) {
    return _api.post<PluginSetupStartResponse>(
      setupPath(pluginId),
      decoder: (raw) => PluginSetupStartResponse.fromJson(_unwrap(raw)),
    );
  }

  Future<PluginSetupStatusResponse> getSetupStatus(String pluginId) {
    return _api.get<PluginSetupStatusResponse>(
      '${setupPath(pluginId)}/status',
      decoder: (raw) => PluginSetupStatusResponse.fromJson(_unwrap(raw)),
    );
  }

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = _unwrapList(raw);
    return items
        .map((item) => fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    final map = (raw as Map).cast<String, dynamic>();
    return (map['data'] as List).cast<dynamic>();
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('data')) {
      return (raw['data'] as Map).cast<String, dynamic>();
    }
    return (raw as Map).cast<String, dynamic>();
  }
}
