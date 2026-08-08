import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistant_settings.freezed.dart';
part 'assistant_settings.g.dart';

@freezed
abstract class AssistantSettings with _$AssistantSettings {
  const factory AssistantSettings({
    @JsonKey(name: 'wake_word') required String wakeWord,
    @JsonKey(name: 'active_listening_enabled')
    required bool activeListeningEnabled,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AssistantSettings;

  factory AssistantSettings.fromJson(Map<String, dynamic> json) =>
      _$AssistantSettingsFromJson(json);
}
