import 'package:freezed_annotation/freezed_annotation.dart';

import 'plugin_setup_status.dart';

part 'installed_plugin.freezed.dart';
part 'installed_plugin.g.dart';

@freezed
abstract class InstalledPlugin with _$InstalledPlugin {
  const factory InstalledPlugin({
    required String id,
    required String slug,
    required String name,
    @Default('') String description,
    required bool enabled,
    @JsonKey(name: 'setup_status') required PluginSetupStatus setupStatus,
  }) = _InstalledPlugin;

  factory InstalledPlugin.fromJson(Map<String, dynamic> json) =>
      _$InstalledPluginFromJson(_normalizeInstalledPluginJson(json));
}

Map<String, dynamic> _normalizeInstalledPluginJson(Map<String, dynamic> json) {
  final plugin = json['plugin'];
  if (plugin is Map) {
    final nested = plugin.cast<String, dynamic>();
    return {
      'id': json['id'],
      'slug': nested['slug'],
      'name': nested['name'],
      'description': nested['description'] ?? json['description'] ?? '',
      'enabled': json['enabled'],
      'setup_status': json['setup_status'],
    };
  }

  return {
    ...json,
    'description': json['description'] ?? '',
  };
}
