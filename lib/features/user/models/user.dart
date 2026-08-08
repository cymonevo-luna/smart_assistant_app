import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Example immutable model generated with freezed + json_serializable.
///
/// Run codegen after changing this file:
/// `dart run build_runner build --delete-conflicting-outputs`
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
