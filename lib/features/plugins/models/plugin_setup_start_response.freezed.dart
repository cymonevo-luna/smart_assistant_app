// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plugin_setup_start_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PluginSetupStartResponse {

@JsonKey(name: 'authorization_url') String get authorizationUrl;
/// Create a copy of PluginSetupStartResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginSetupStartResponseCopyWith<PluginSetupStartResponse> get copyWith => _$PluginSetupStartResponseCopyWithImpl<PluginSetupStartResponse>(this as PluginSetupStartResponse, _$identity);

  /// Serializes this PluginSetupStartResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginSetupStartResponse&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authorizationUrl);

@override
String toString() {
  return 'PluginSetupStartResponse(authorizationUrl: $authorizationUrl)';
}


}

/// @nodoc
abstract mixin class $PluginSetupStartResponseCopyWith<$Res>  {
  factory $PluginSetupStartResponseCopyWith(PluginSetupStartResponse value, $Res Function(PluginSetupStartResponse) _then) = _$PluginSetupStartResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'authorization_url') String authorizationUrl
});




}
/// @nodoc
class _$PluginSetupStartResponseCopyWithImpl<$Res>
    implements $PluginSetupStartResponseCopyWith<$Res> {
  _$PluginSetupStartResponseCopyWithImpl(this._self, this._then);

  final PluginSetupStartResponse _self;
  final $Res Function(PluginSetupStartResponse) _then;

/// Create a copy of PluginSetupStartResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authorizationUrl = null,}) {
  return _then(_self.copyWith(
authorizationUrl: null == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginSetupStartResponse].
extension PluginSetupStartResponsePatterns on PluginSetupStartResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginSetupStartResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginSetupStartResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginSetupStartResponse value)  $default,){
final _that = this;
switch (_that) {
case _PluginSetupStartResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginSetupStartResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PluginSetupStartResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'authorization_url')  String authorizationUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginSetupStartResponse() when $default != null:
return $default(_that.authorizationUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'authorization_url')  String authorizationUrl)  $default,) {final _that = this;
switch (_that) {
case _PluginSetupStartResponse():
return $default(_that.authorizationUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'authorization_url')  String authorizationUrl)?  $default,) {final _that = this;
switch (_that) {
case _PluginSetupStartResponse() when $default != null:
return $default(_that.authorizationUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginSetupStartResponse implements PluginSetupStartResponse {
  const _PluginSetupStartResponse({@JsonKey(name: 'authorization_url') required this.authorizationUrl});
  factory _PluginSetupStartResponse.fromJson(Map<String, dynamic> json) => _$PluginSetupStartResponseFromJson(json);

@override@JsonKey(name: 'authorization_url') final  String authorizationUrl;

/// Create a copy of PluginSetupStartResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginSetupStartResponseCopyWith<_PluginSetupStartResponse> get copyWith => __$PluginSetupStartResponseCopyWithImpl<_PluginSetupStartResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginSetupStartResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginSetupStartResponse&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authorizationUrl);

@override
String toString() {
  return 'PluginSetupStartResponse(authorizationUrl: $authorizationUrl)';
}


}

/// @nodoc
abstract mixin class _$PluginSetupStartResponseCopyWith<$Res> implements $PluginSetupStartResponseCopyWith<$Res> {
  factory _$PluginSetupStartResponseCopyWith(_PluginSetupStartResponse value, $Res Function(_PluginSetupStartResponse) _then) = __$PluginSetupStartResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'authorization_url') String authorizationUrl
});




}
/// @nodoc
class __$PluginSetupStartResponseCopyWithImpl<$Res>
    implements _$PluginSetupStartResponseCopyWith<$Res> {
  __$PluginSetupStartResponseCopyWithImpl(this._self, this._then);

  final _PluginSetupStartResponse _self;
  final $Res Function(_PluginSetupStartResponse) _then;

/// Create a copy of PluginSetupStartResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authorizationUrl = null,}) {
  return _then(_PluginSetupStartResponse(
authorizationUrl: null == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
