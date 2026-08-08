// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssistantSession {

 String get id;@JsonKey(name: 'session_status') AssistantSessionStatus get sessionStatus;
/// Create a copy of AssistantSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantSessionCopyWith<AssistantSession> get copyWith => _$AssistantSessionCopyWithImpl<AssistantSession>(this as AssistantSession, _$identity);

  /// Serializes this AssistantSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantSession&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionStatus, sessionStatus) || other.sessionStatus == sessionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionStatus);

@override
String toString() {
  return 'AssistantSession(id: $id, sessionStatus: $sessionStatus)';
}


}

/// @nodoc
abstract mixin class $AssistantSessionCopyWith<$Res>  {
  factory $AssistantSessionCopyWith(AssistantSession value, $Res Function(AssistantSession) _then) = _$AssistantSessionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'session_status') AssistantSessionStatus sessionStatus
});




}
/// @nodoc
class _$AssistantSessionCopyWithImpl<$Res>
    implements $AssistantSessionCopyWith<$Res> {
  _$AssistantSessionCopyWithImpl(this._self, this._then);

  final AssistantSession _self;
  final $Res Function(AssistantSession) _then;

/// Create a copy of AssistantSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionStatus: null == sessionStatus ? _self.sessionStatus : sessionStatus // ignore: cast_nullable_to_non_nullable
as AssistantSessionStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantSession].
extension AssistantSessionPatterns on AssistantSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantSession value)  $default,){
final _that = this;
switch (_that) {
case _AssistantSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantSession value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_status')  AssistantSessionStatus sessionStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantSession() when $default != null:
return $default(_that.id,_that.sessionStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_status')  AssistantSessionStatus sessionStatus)  $default,) {final _that = this;
switch (_that) {
case _AssistantSession():
return $default(_that.id,_that.sessionStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'session_status')  AssistantSessionStatus sessionStatus)?  $default,) {final _that = this;
switch (_that) {
case _AssistantSession() when $default != null:
return $default(_that.id,_that.sessionStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantSession implements AssistantSession {
  const _AssistantSession({required this.id, @JsonKey(name: 'session_status') required this.sessionStatus});
  factory _AssistantSession.fromJson(Map<String, dynamic> json) => _$AssistantSessionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'session_status') final  AssistantSessionStatus sessionStatus;

/// Create a copy of AssistantSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantSessionCopyWith<_AssistantSession> get copyWith => __$AssistantSessionCopyWithImpl<_AssistantSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantSession&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionStatus, sessionStatus) || other.sessionStatus == sessionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionStatus);

@override
String toString() {
  return 'AssistantSession(id: $id, sessionStatus: $sessionStatus)';
}


}

/// @nodoc
abstract mixin class _$AssistantSessionCopyWith<$Res> implements $AssistantSessionCopyWith<$Res> {
  factory _$AssistantSessionCopyWith(_AssistantSession value, $Res Function(_AssistantSession) _then) = __$AssistantSessionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'session_status') AssistantSessionStatus sessionStatus
});




}
/// @nodoc
class __$AssistantSessionCopyWithImpl<$Res>
    implements _$AssistantSessionCopyWith<$Res> {
  __$AssistantSessionCopyWithImpl(this._self, this._then);

  final _AssistantSession _self;
  final $Res Function(_AssistantSession) _then;

/// Create a copy of AssistantSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionStatus = null,}) {
  return _then(_AssistantSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionStatus: null == sessionStatus ? _self.sessionStatus : sessionStatus // ignore: cast_nullable_to_non_nullable
as AssistantSessionStatus,
  ));
}


}


/// @nodoc
mixin _$AssistantMessageResponse {

 AssistantReply get reply;@JsonKey(name: 'session_status') AssistantSessionStatus get sessionStatus;
/// Create a copy of AssistantMessageResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantMessageResponseCopyWith<AssistantMessageResponse> get copyWith => _$AssistantMessageResponseCopyWithImpl<AssistantMessageResponse>(this as AssistantMessageResponse, _$identity);

  /// Serializes this AssistantMessageResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantMessageResponse&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.sessionStatus, sessionStatus) || other.sessionStatus == sessionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,sessionStatus);

@override
String toString() {
  return 'AssistantMessageResponse(reply: $reply, sessionStatus: $sessionStatus)';
}


}

/// @nodoc
abstract mixin class $AssistantMessageResponseCopyWith<$Res>  {
  factory $AssistantMessageResponseCopyWith(AssistantMessageResponse value, $Res Function(AssistantMessageResponse) _then) = _$AssistantMessageResponseCopyWithImpl;
@useResult
$Res call({
 AssistantReply reply,@JsonKey(name: 'session_status') AssistantSessionStatus sessionStatus
});


$AssistantReplyCopyWith<$Res> get reply;

}
/// @nodoc
class _$AssistantMessageResponseCopyWithImpl<$Res>
    implements $AssistantMessageResponseCopyWith<$Res> {
  _$AssistantMessageResponseCopyWithImpl(this._self, this._then);

  final AssistantMessageResponse _self;
  final $Res Function(AssistantMessageResponse) _then;

/// Create a copy of AssistantMessageResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reply = null,Object? sessionStatus = null,}) {
  return _then(_self.copyWith(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as AssistantReply,sessionStatus: null == sessionStatus ? _self.sessionStatus : sessionStatus // ignore: cast_nullable_to_non_nullable
as AssistantSessionStatus,
  ));
}
/// Create a copy of AssistantMessageResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantReplyCopyWith<$Res> get reply {
  
  return $AssistantReplyCopyWith<$Res>(_self.reply, (value) {
    return _then(_self.copyWith(reply: value));
  });
}
}


/// Adds pattern-matching-related methods to [AssistantMessageResponse].
extension AssistantMessageResponsePatterns on AssistantMessageResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantMessageResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantMessageResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantMessageResponse value)  $default,){
final _that = this;
switch (_that) {
case _AssistantMessageResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantMessageResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantMessageResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AssistantReply reply, @JsonKey(name: 'session_status')  AssistantSessionStatus sessionStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantMessageResponse() when $default != null:
return $default(_that.reply,_that.sessionStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AssistantReply reply, @JsonKey(name: 'session_status')  AssistantSessionStatus sessionStatus)  $default,) {final _that = this;
switch (_that) {
case _AssistantMessageResponse():
return $default(_that.reply,_that.sessionStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AssistantReply reply, @JsonKey(name: 'session_status')  AssistantSessionStatus sessionStatus)?  $default,) {final _that = this;
switch (_that) {
case _AssistantMessageResponse() when $default != null:
return $default(_that.reply,_that.sessionStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantMessageResponse implements AssistantMessageResponse {
  const _AssistantMessageResponse({required this.reply, @JsonKey(name: 'session_status') required this.sessionStatus});
  factory _AssistantMessageResponse.fromJson(Map<String, dynamic> json) => _$AssistantMessageResponseFromJson(json);

@override final  AssistantReply reply;
@override@JsonKey(name: 'session_status') final  AssistantSessionStatus sessionStatus;

/// Create a copy of AssistantMessageResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantMessageResponseCopyWith<_AssistantMessageResponse> get copyWith => __$AssistantMessageResponseCopyWithImpl<_AssistantMessageResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantMessageResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantMessageResponse&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.sessionStatus, sessionStatus) || other.sessionStatus == sessionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,sessionStatus);

@override
String toString() {
  return 'AssistantMessageResponse(reply: $reply, sessionStatus: $sessionStatus)';
}


}

/// @nodoc
abstract mixin class _$AssistantMessageResponseCopyWith<$Res> implements $AssistantMessageResponseCopyWith<$Res> {
  factory _$AssistantMessageResponseCopyWith(_AssistantMessageResponse value, $Res Function(_AssistantMessageResponse) _then) = __$AssistantMessageResponseCopyWithImpl;
@override @useResult
$Res call({
 AssistantReply reply,@JsonKey(name: 'session_status') AssistantSessionStatus sessionStatus
});


@override $AssistantReplyCopyWith<$Res> get reply;

}
/// @nodoc
class __$AssistantMessageResponseCopyWithImpl<$Res>
    implements _$AssistantMessageResponseCopyWith<$Res> {
  __$AssistantMessageResponseCopyWithImpl(this._self, this._then);

  final _AssistantMessageResponse _self;
  final $Res Function(_AssistantMessageResponse) _then;

/// Create a copy of AssistantMessageResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reply = null,Object? sessionStatus = null,}) {
  return _then(_AssistantMessageResponse(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as AssistantReply,sessionStatus: null == sessionStatus ? _self.sessionStatus : sessionStatus // ignore: cast_nullable_to_non_nullable
as AssistantSessionStatus,
  ));
}

/// Create a copy of AssistantMessageResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantReplyCopyWith<$Res> get reply {
  
  return $AssistantReplyCopyWith<$Res>(_self.reply, (value) {
    return _then(_self.copyWith(reply: value));
  });
}
}

// dart format on
