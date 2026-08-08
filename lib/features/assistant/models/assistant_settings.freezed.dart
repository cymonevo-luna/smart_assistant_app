// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssistantSettings {

@JsonKey(name: 'wake_word') String get wakeWord;@JsonKey(name: 'active_listening_enabled') bool get activeListeningEnabled;@JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100) int get locationReminderThresholdMeters;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of AssistantSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantSettingsCopyWith<AssistantSettings> get copyWith => _$AssistantSettingsCopyWithImpl<AssistantSettings>(this as AssistantSettings, _$identity);

  /// Serializes this AssistantSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantSettings&&(identical(other.wakeWord, wakeWord) || other.wakeWord == wakeWord)&&(identical(other.activeListeningEnabled, activeListeningEnabled) || other.activeListeningEnabled == activeListeningEnabled)&&(identical(other.locationReminderThresholdMeters, locationReminderThresholdMeters) || other.locationReminderThresholdMeters == locationReminderThresholdMeters)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wakeWord,activeListeningEnabled,locationReminderThresholdMeters,updatedAt);

@override
String toString() {
  return 'AssistantSettings(wakeWord: $wakeWord, activeListeningEnabled: $activeListeningEnabled, locationReminderThresholdMeters: $locationReminderThresholdMeters, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AssistantSettingsCopyWith<$Res>  {
  factory $AssistantSettingsCopyWith(AssistantSettings value, $Res Function(AssistantSettings) _then) = _$AssistantSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'wake_word') String wakeWord,@JsonKey(name: 'active_listening_enabled') bool activeListeningEnabled,@JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100) int locationReminderThresholdMeters,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$AssistantSettingsCopyWithImpl<$Res>
    implements $AssistantSettingsCopyWith<$Res> {
  _$AssistantSettingsCopyWithImpl(this._self, this._then);

  final AssistantSettings _self;
  final $Res Function(AssistantSettings) _then;

/// Create a copy of AssistantSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wakeWord = null,Object? activeListeningEnabled = null,Object? locationReminderThresholdMeters = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
wakeWord: null == wakeWord ? _self.wakeWord : wakeWord // ignore: cast_nullable_to_non_nullable
as String,activeListeningEnabled: null == activeListeningEnabled ? _self.activeListeningEnabled : activeListeningEnabled // ignore: cast_nullable_to_non_nullable
as bool,locationReminderThresholdMeters: null == locationReminderThresholdMeters ? _self.locationReminderThresholdMeters : locationReminderThresholdMeters // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantSettings].
extension AssistantSettingsPatterns on AssistantSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantSettings value)  $default,){
final _that = this;
switch (_that) {
case _AssistantSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'wake_word')  String wakeWord, @JsonKey(name: 'active_listening_enabled')  bool activeListeningEnabled, @JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100)  int locationReminderThresholdMeters, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantSettings() when $default != null:
return $default(_that.wakeWord,_that.activeListeningEnabled,_that.locationReminderThresholdMeters,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'wake_word')  String wakeWord, @JsonKey(name: 'active_listening_enabled')  bool activeListeningEnabled, @JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100)  int locationReminderThresholdMeters, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AssistantSettings():
return $default(_that.wakeWord,_that.activeListeningEnabled,_that.locationReminderThresholdMeters,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'wake_word')  String wakeWord, @JsonKey(name: 'active_listening_enabled')  bool activeListeningEnabled, @JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100)  int locationReminderThresholdMeters, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AssistantSettings() when $default != null:
return $default(_that.wakeWord,_that.activeListeningEnabled,_that.locationReminderThresholdMeters,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantSettings implements AssistantSettings {
  const _AssistantSettings({@JsonKey(name: 'wake_word') required this.wakeWord, @JsonKey(name: 'active_listening_enabled') required this.activeListeningEnabled, @JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100) this.locationReminderThresholdMeters = 100, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _AssistantSettings.fromJson(Map<String, dynamic> json) => _$AssistantSettingsFromJson(json);

@override@JsonKey(name: 'wake_word') final  String wakeWord;
@override@JsonKey(name: 'active_listening_enabled') final  bool activeListeningEnabled;
@override@JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100) final  int locationReminderThresholdMeters;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of AssistantSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantSettingsCopyWith<_AssistantSettings> get copyWith => __$AssistantSettingsCopyWithImpl<_AssistantSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantSettings&&(identical(other.wakeWord, wakeWord) || other.wakeWord == wakeWord)&&(identical(other.activeListeningEnabled, activeListeningEnabled) || other.activeListeningEnabled == activeListeningEnabled)&&(identical(other.locationReminderThresholdMeters, locationReminderThresholdMeters) || other.locationReminderThresholdMeters == locationReminderThresholdMeters)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wakeWord,activeListeningEnabled,locationReminderThresholdMeters,updatedAt);

@override
String toString() {
  return 'AssistantSettings(wakeWord: $wakeWord, activeListeningEnabled: $activeListeningEnabled, locationReminderThresholdMeters: $locationReminderThresholdMeters, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AssistantSettingsCopyWith<$Res> implements $AssistantSettingsCopyWith<$Res> {
  factory _$AssistantSettingsCopyWith(_AssistantSettings value, $Res Function(_AssistantSettings) _then) = __$AssistantSettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'wake_word') String wakeWord,@JsonKey(name: 'active_listening_enabled') bool activeListeningEnabled,@JsonKey(name: 'location_reminder_threshold_meters', defaultValue: 100) int locationReminderThresholdMeters,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$AssistantSettingsCopyWithImpl<$Res>
    implements _$AssistantSettingsCopyWith<$Res> {
  __$AssistantSettingsCopyWithImpl(this._self, this._then);

  final _AssistantSettings _self;
  final $Res Function(_AssistantSettings) _then;

/// Create a copy of AssistantSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wakeWord = null,Object? activeListeningEnabled = null,Object? locationReminderThresholdMeters = null,Object? updatedAt = freezed,}) {
  return _then(_AssistantSettings(
wakeWord: null == wakeWord ? _self.wakeWord : wakeWord // ignore: cast_nullable_to_non_nullable
as String,activeListeningEnabled: null == activeListeningEnabled ? _self.activeListeningEnabled : activeListeningEnabled // ignore: cast_nullable_to_non_nullable
as bool,locationReminderThresholdMeters: null == locationReminderThresholdMeters ? _self.locationReminderThresholdMeters : locationReminderThresholdMeters // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
