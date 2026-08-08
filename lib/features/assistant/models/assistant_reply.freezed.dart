// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_reply.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssistantAction {

@JsonKey(name: 'plugin_slug') String? get pluginSlug; String? get status; Map<String, dynamic>? get payload;
/// Create a copy of AssistantAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantActionCopyWith<AssistantAction> get copyWith => _$AssistantActionCopyWithImpl<AssistantAction>(this as AssistantAction, _$identity);

  /// Serializes this AssistantAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantAction&&(identical(other.pluginSlug, pluginSlug) || other.pluginSlug == pluginSlug)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.payload, payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pluginSlug,status,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'AssistantAction(pluginSlug: $pluginSlug, status: $status, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $AssistantActionCopyWith<$Res>  {
  factory $AssistantActionCopyWith(AssistantAction value, $Res Function(AssistantAction) _then) = _$AssistantActionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'plugin_slug') String? pluginSlug, String? status, Map<String, dynamic>? payload
});




}
/// @nodoc
class _$AssistantActionCopyWithImpl<$Res>
    implements $AssistantActionCopyWith<$Res> {
  _$AssistantActionCopyWithImpl(this._self, this._then);

  final AssistantAction _self;
  final $Res Function(AssistantAction) _then;

/// Create a copy of AssistantAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pluginSlug = freezed,Object? status = freezed,Object? payload = freezed,}) {
  return _then(_self.copyWith(
pluginSlug: freezed == pluginSlug ? _self.pluginSlug : pluginSlug // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantAction].
extension AssistantActionPatterns on AssistantAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantAction value)  $default,){
final _that = this;
switch (_that) {
case _AssistantAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantAction value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'plugin_slug')  String? pluginSlug,  String? status,  Map<String, dynamic>? payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantAction() when $default != null:
return $default(_that.pluginSlug,_that.status,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'plugin_slug')  String? pluginSlug,  String? status,  Map<String, dynamic>? payload)  $default,) {final _that = this;
switch (_that) {
case _AssistantAction():
return $default(_that.pluginSlug,_that.status,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'plugin_slug')  String? pluginSlug,  String? status,  Map<String, dynamic>? payload)?  $default,) {final _that = this;
switch (_that) {
case _AssistantAction() when $default != null:
return $default(_that.pluginSlug,_that.status,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantAction implements AssistantAction {
  const _AssistantAction({@JsonKey(name: 'plugin_slug') this.pluginSlug, this.status, final  Map<String, dynamic>? payload}): _payload = payload;
  factory _AssistantAction.fromJson(Map<String, dynamic> json) => _$AssistantActionFromJson(json);

@override@JsonKey(name: 'plugin_slug') final  String? pluginSlug;
@override final  String? status;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AssistantAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantActionCopyWith<_AssistantAction> get copyWith => __$AssistantActionCopyWithImpl<_AssistantAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantAction&&(identical(other.pluginSlug, pluginSlug) || other.pluginSlug == pluginSlug)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pluginSlug,status,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'AssistantAction(pluginSlug: $pluginSlug, status: $status, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$AssistantActionCopyWith<$Res> implements $AssistantActionCopyWith<$Res> {
  factory _$AssistantActionCopyWith(_AssistantAction value, $Res Function(_AssistantAction) _then) = __$AssistantActionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'plugin_slug') String? pluginSlug, String? status, Map<String, dynamic>? payload
});




}
/// @nodoc
class __$AssistantActionCopyWithImpl<$Res>
    implements _$AssistantActionCopyWith<$Res> {
  __$AssistantActionCopyWithImpl(this._self, this._then);

  final _AssistantAction _self;
  final $Res Function(_AssistantAction) _then;

/// Create a copy of AssistantAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pluginSlug = freezed,Object? status = freezed,Object? payload = freezed,}) {
  return _then(_AssistantAction(
pluginSlug: freezed == pluginSlug ? _self.pluginSlug : pluginSlug // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$AssistantReply {

 AssistantReplyType get type; String get text; AssistantAction? get action;
/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantReplyCopyWith<AssistantReply> get copyWith => _$AssistantReplyCopyWithImpl<AssistantReply>(this as AssistantReply, _$identity);

  /// Serializes this AssistantReply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantReply&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text,action);

@override
String toString() {
  return 'AssistantReply(type: $type, text: $text, action: $action)';
}


}

/// @nodoc
abstract mixin class $AssistantReplyCopyWith<$Res>  {
  factory $AssistantReplyCopyWith(AssistantReply value, $Res Function(AssistantReply) _then) = _$AssistantReplyCopyWithImpl;
@useResult
$Res call({
 AssistantReplyType type, String text, AssistantAction? action
});


$AssistantActionCopyWith<$Res>? get action;

}
/// @nodoc
class _$AssistantReplyCopyWithImpl<$Res>
    implements $AssistantReplyCopyWith<$Res> {
  _$AssistantReplyCopyWithImpl(this._self, this._then);

  final AssistantReply _self;
  final $Res Function(AssistantReply) _then;

/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = null,Object? action = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AssistantReplyType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as AssistantAction?,
  ));
}
/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantActionCopyWith<$Res>? get action {
    if (_self.action == null) {
    return null;
  }

  return $AssistantActionCopyWith<$Res>(_self.action!, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// Adds pattern-matching-related methods to [AssistantReply].
extension AssistantReplyPatterns on AssistantReply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantReply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantReply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantReply value)  $default,){
final _that = this;
switch (_that) {
case _AssistantReply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantReply value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantReply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AssistantReplyType type,  String text,  AssistantAction? action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantReply() when $default != null:
return $default(_that.type,_that.text,_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AssistantReplyType type,  String text,  AssistantAction? action)  $default,) {final _that = this;
switch (_that) {
case _AssistantReply():
return $default(_that.type,_that.text,_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AssistantReplyType type,  String text,  AssistantAction? action)?  $default,) {final _that = this;
switch (_that) {
case _AssistantReply() when $default != null:
return $default(_that.type,_that.text,_that.action);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantReply implements AssistantReply {
  const _AssistantReply({required this.type, required this.text, this.action});
  factory _AssistantReply.fromJson(Map<String, dynamic> json) => _$AssistantReplyFromJson(json);

@override final  AssistantReplyType type;
@override final  String text;
@override final  AssistantAction? action;

/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantReplyCopyWith<_AssistantReply> get copyWith => __$AssistantReplyCopyWithImpl<_AssistantReply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantReply&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text,action);

@override
String toString() {
  return 'AssistantReply(type: $type, text: $text, action: $action)';
}


}

/// @nodoc
abstract mixin class _$AssistantReplyCopyWith<$Res> implements $AssistantReplyCopyWith<$Res> {
  factory _$AssistantReplyCopyWith(_AssistantReply value, $Res Function(_AssistantReply) _then) = __$AssistantReplyCopyWithImpl;
@override @useResult
$Res call({
 AssistantReplyType type, String text, AssistantAction? action
});


@override $AssistantActionCopyWith<$Res>? get action;

}
/// @nodoc
class __$AssistantReplyCopyWithImpl<$Res>
    implements _$AssistantReplyCopyWith<$Res> {
  __$AssistantReplyCopyWithImpl(this._self, this._then);

  final _AssistantReply _self;
  final $Res Function(_AssistantReply) _then;

/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,Object? action = freezed,}) {
  return _then(_AssistantReply(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AssistantReplyType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as AssistantAction?,
  ));
}

/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantActionCopyWith<$Res>? get action {
    if (_self.action == null) {
    return null;
  }

  return $AssistantActionCopyWith<$Res>(_self.action!, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

// dart format on
