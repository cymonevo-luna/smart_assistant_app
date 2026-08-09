import 'package:freezed_annotation/freezed_annotation.dart';

import 'plugin_setup_status.dart';

part 'plugin_setup_status_response.freezed.dart';
part 'plugin_setup_status_response.g.dart';

@freezed
abstract class PluginSetupStatusResponse with _$PluginSetupStatusResponse {
  const factory PluginSetupStatusResponse({
    @JsonKey(name: 'setup_status') required PluginSetupStatus setupStatus,
    @JsonKey(name: 'setup_error') String? setupError,
    @JsonKey(name: 'connected_toolkits')
    @Default(<String>[])
    List<String> connectedToolkits,
    @JsonKey(name: 'connected_accounts_count') int? connectedAccountsCount,
  }) = _PluginSetupStatusResponse;

  factory PluginSetupStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$PluginSetupStatusResponseFromJson(json);
}
