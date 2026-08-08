// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_setup_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PluginSetupStatusResponse _$PluginSetupStatusResponseFromJson(
  Map<String, dynamic> json,
) => _PluginSetupStatusResponse(
  setupStatus: $enumDecode(_$PluginSetupStatusEnumMap, json['setup_status']),
  setupError: json['setup_error'] as String?,
);

Map<String, dynamic> _$PluginSetupStatusResponseToJson(
  _PluginSetupStatusResponse instance,
) => <String, dynamic>{
  'setup_status': _$PluginSetupStatusEnumMap[instance.setupStatus]!,
  'setup_error': instance.setupError,
};

const _$PluginSetupStatusEnumMap = {
  PluginSetupStatus.notStarted: 'not_started',
  PluginSetupStatus.inProgress: 'in_progress',
  PluginSetupStatus.completed: 'completed',
  PluginSetupStatus.failed: 'failed',
};
