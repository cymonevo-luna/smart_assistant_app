// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_plugin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstalledPlugin _$InstalledPluginFromJson(Map<String, dynamic> json) =>
    _InstalledPlugin(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      enabled: json['enabled'] as bool,
      setupStatus: $enumDecode(
        _$PluginSetupStatusEnumMap,
        json['setup_status'],
      ),
    );

Map<String, dynamic> _$InstalledPluginToJson(_InstalledPlugin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'description': instance.description,
      'enabled': instance.enabled,
      'setup_status': _$PluginSetupStatusEnumMap[instance.setupStatus]!,
    };

const _$PluginSetupStatusEnumMap = {
  PluginSetupStatus.notStarted: 'not_started',
  PluginSetupStatus.inProgress: 'in_progress',
  PluginSetupStatus.completed: 'completed',
};
