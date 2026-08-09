import 'package:freezed_annotation/freezed_annotation.dart';

import 'plugin_setup_type.dart';

part 'plugin_catalog_item.freezed.dart';
part 'plugin_catalog_item.g.dart';

PluginSetupType? _setupTypeFromJson(dynamic value) =>
    value is String ? PluginSetupType.fromApi(value) : null;

String? _setupTypeToJson(PluginSetupType? value) => value?.toApi();

@freezed
abstract class PluginCatalogItem with _$PluginCatalogItem {
  const factory PluginCatalogItem({
    required String slug,
    required String name,
    required String description,
    String? version,
    @JsonKey(name: 'icon_url') String? iconUrl,
    @JsonKey(name: 'required_setup') @Default(false) bool requiredSetup,
    @JsonKey(
      name: 'setup_type',
      fromJson: _setupTypeFromJson,
      toJson: _setupTypeToJson,
    )
    PluginSetupType? setupType,
  }) = _PluginCatalogItem;

  factory PluginCatalogItem.fromJson(Map<String, dynamic> json) =>
      _$PluginCatalogItemFromJson(json);
}
