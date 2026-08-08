import 'package:freezed_annotation/freezed_annotation.dart';

enum PluginSetupStatus {
  @JsonValue('not_started')
  notStarted,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}
