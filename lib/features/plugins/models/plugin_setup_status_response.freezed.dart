// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plugin_setup_status_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PluginSetupStatusResponse {

@JsonKey(name: 'setup_status') PluginSetupStatus get setupStatus;@JsonKey(name: 'setup_error') String? get setupError;
/// Create a copy of PluginSetupStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginSetupStatusResponseCopyWith<PluginSetupStatusResponse> get copyWith => _$PluginSetupStatusResponseCopyWithImpl<PluginSetupStatusResponse>(this as PluginSetupStatusResponse, _$identity);

  /// Serializes this PluginSetupStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginSetupStatusResponse&&(identical(other.setupStatus, setupStatus) || other.setupStatus == setupStatus)&&(identical(other.setupError, setupError) || other.setupError == setupError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setupStatus,setupError);

@override
String toString() {
  return 'PluginSetupStatusResponse(setupStatus: $setupStatus, setupError: $setupError)';
}


}

/// @nodoc
abstract mixin class $PluginSetupStatusResponseCopyWith<$Res>  {
  factory $PluginSetupStatusResponseCopyWith(PluginSetupStatusResponse value, $Res Function(PluginSetupStatusResponse) _then) = _$PluginSetupStatusResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'setup_status') PluginSetupStatus setupStatus,@JsonKey(name: 'setup_error') String? setupError
});




}
/// @nodoc
class _$PluginSetupStatusResponseCopyWithImpl<$Res>
    implements $PluginSetupStatusResponseCopyWith<$Res> {
  _$PluginSetupStatusResponseCopyWithImpl(this._self, this._then);

  final PluginSetupStatusResponse _self;
  final $Res Function(PluginSetupStatusResponse) _then;

/// Create a copy of PluginSetupStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setupStatus = null,Object? setupError = freezed,}) {
  return _then(_self.copyWith(
setupStatus: null == setupStatus ? _self.setupStatus : setupStatus // ignore: cast_nullable_to_non_nullable
as PluginSetupStatus,setupError: freezed == setupError ? _self.setupError : setupError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginSetupStatusResponse].
extension PluginSetupStatusResponsePatterns on PluginSetupStatusResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginSetupStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginSetupStatusResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginSetupStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _PluginSetupStatusResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginSetupStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PluginSetupStatusResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'setup_status')  PluginSetupStatus setupStatus, @JsonKey(name: 'setup_error')  String? setupError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginSetupStatusResponse() when $default != null:
return $default(_that.setupStatus,_that.setupError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'setup_status')  PluginSetupStatus setupStatus, @JsonKey(name: 'setup_error')  String? setupError)  $default,) {final _that = this;
switch (_that) {
case _PluginSetupStatusResponse():
return $default(_that.setupStatus,_that.setupError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'setup_status')  PluginSetupStatus setupStatus, @JsonKey(name: 'setup_error')  String? setupError)?  $default,) {final _that = this;
switch (_that) {
case _PluginSetupStatusResponse() when $default != null:
return $default(_that.setupStatus,_that.setupError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginSetupStatusResponse implements PluginSetupStatusResponse {
  const _PluginSetupStatusResponse({@JsonKey(name: 'setup_status') required this.setupStatus, @JsonKey(name: 'setup_error') this.setupError});
  factory _PluginSetupStatusResponse.fromJson(Map<String, dynamic> json) => _$PluginSetupStatusResponseFromJson(json);

@override@JsonKey(name: 'setup_status') final  PluginSetupStatus setupStatus;
@override@JsonKey(name: 'setup_error') final  String? setupError;

/// Create a copy of PluginSetupStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginSetupStatusResponseCopyWith<_PluginSetupStatusResponse> get copyWith => __$PluginSetupStatusResponseCopyWithImpl<_PluginSetupStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginSetupStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginSetupStatusResponse&&(identical(other.setupStatus, setupStatus) || other.setupStatus == setupStatus)&&(identical(other.setupError, setupError) || other.setupError == setupError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setupStatus,setupError);

@override
String toString() {
  return 'PluginSetupStatusResponse(setupStatus: $setupStatus, setupError: $setupError)';
}


}

/// @nodoc
abstract mixin class _$PluginSetupStatusResponseCopyWith<$Res> implements $PluginSetupStatusResponseCopyWith<$Res> {
  factory _$PluginSetupStatusResponseCopyWith(_PluginSetupStatusResponse value, $Res Function(_PluginSetupStatusResponse) _then) = __$PluginSetupStatusResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'setup_status') PluginSetupStatus setupStatus,@JsonKey(name: 'setup_error') String? setupError
});




}
/// @nodoc
class __$PluginSetupStatusResponseCopyWithImpl<$Res>
    implements _$PluginSetupStatusResponseCopyWith<$Res> {
  __$PluginSetupStatusResponseCopyWithImpl(this._self, this._then);

  final _PluginSetupStatusResponse _self;
  final $Res Function(_PluginSetupStatusResponse) _then;

/// Create a copy of PluginSetupStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setupStatus = null,Object? setupError = freezed,}) {
  return _then(_PluginSetupStatusResponse(
setupStatus: null == setupStatus ? _self.setupStatus : setupStatus // ignore: cast_nullable_to_non_nullable
as PluginSetupStatus,setupError: freezed == setupError ? _self.setupError : setupError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
