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
    required String description,
    required bool enabled,
    @JsonKey(name: 'setup_status') required PluginSetupStatus setupStatus,
  }) = _InstalledPlugin;

  factory InstalledPlugin.fromJson(Map<String, dynamic> json) =>
      _$InstalledPluginFromJson(json);
}
