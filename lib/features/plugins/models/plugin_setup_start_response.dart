import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_setup_start_response.freezed.dart';
part 'plugin_setup_start_response.g.dart';

@freezed
abstract class PluginSetupStartResponse with _$PluginSetupStartResponse {
  const factory PluginSetupStartResponse({
    @JsonKey(name: 'authorization_url') required String authorizationUrl,
  }) = _PluginSetupStartResponse;

  factory PluginSetupStartResponse.fromJson(Map<String, dynamic> json) =>
      _$PluginSetupStartResponseFromJson(json);
}
