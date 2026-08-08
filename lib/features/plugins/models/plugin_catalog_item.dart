import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_catalog_item.freezed.dart';
part 'plugin_catalog_item.g.dart';

@freezed
abstract class PluginCatalogItem with _$PluginCatalogItem {
  const factory PluginCatalogItem({
    required String slug,
    required String name,
    required String description,
    String? version,
    @JsonKey(name: 'icon_url') String? iconUrl,
  }) = _PluginCatalogItem;

  factory PluginCatalogItem.fromJson(Map<String, dynamic> json) =>
      _$PluginCatalogItemFromJson(json);
}
