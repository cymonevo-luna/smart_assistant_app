import 'package:freezed_annotation/freezed_annotation.dart';

import 'plugin_setup_status.dart';
import 'plugin_setup_type.dart';

part 'installed_plugin.freezed.dart';
part 'installed_plugin.g.dart';

PluginSetupType? _setupTypeFromJson(dynamic value) =>
    value is String ? PluginSetupType.fromApi(value) : null;

String? _setupTypeToJson(PluginSetupType? value) => value?.toApi();

@freezed
abstract class InstalledPlugin with _$InstalledPlugin {
  const factory InstalledPlugin({
    required String id,
    required String slug,
    required String name,
    @Default('') String description,
    required bool enabled,
    @JsonKey(name: 'setup_status') required PluginSetupStatus setupStatus,
    @JsonKey(name: 'required_setup') @Default(false) bool requiredSetup,
    @JsonKey(
      name: 'setup_type',
      fromJson: _setupTypeFromJson,
      toJson: _setupTypeToJson,
    )
    PluginSetupType? setupType,
  }) = _InstalledPlugin;

  factory InstalledPlugin.fromJson(Map<String, dynamic> json) =>
      _$InstalledPluginFromJson(_normalizeInstalledPluginJson(json));
}

extension InstalledPluginSetup on InstalledPlugin {
  bool get needsSetup =>
      requiredSetup && setupStatus != PluginSetupStatus.completed;
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
      'required_setup': nested['required_setup'] ?? json['required_setup'],
      'setup_type': nested['setup_type'] ?? json['setup_type'],
    };
  }

  return {
    ...json,
    'description': json['description'] ?? '',
  };
}
