// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_catalog_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PluginCatalogItem _$PluginCatalogItemFromJson(Map<String, dynamic> json) =>
    _PluginCatalogItem(
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String?,
      iconUrl: json['icon_url'] as String?,
    );

Map<String, dynamic> _$PluginCatalogItemToJson(_PluginCatalogItem instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'icon_url': instance.iconUrl,
    };
