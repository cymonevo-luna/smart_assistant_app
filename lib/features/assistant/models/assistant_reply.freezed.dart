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
mixin _$AssistantReply {

 AssistantReplyType get type; String get text;
/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantReplyCopyWith<AssistantReply> get copyWith => _$AssistantReplyCopyWithImpl<AssistantReply>(this as AssistantReply, _$identity);

  /// Serializes this AssistantReply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantReply&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text);

@override
String toString() {
  return 'AssistantReply(type: $type, text: $text)';
}


}

/// @nodoc
abstract mixin class $AssistantReplyCopyWith<$Res>  {
  factory $AssistantReplyCopyWith(AssistantReply value, $Res Function(AssistantReply) _then) = _$AssistantReplyCopyWithImpl;
@useResult
$Res call({
 AssistantReplyType type, String text
});




}
/// @nodoc
class _$AssistantReplyCopyWithImpl<$Res>
    implements $AssistantReplyCopyWith<$Res> {
  _$AssistantReplyCopyWithImpl(this._self, this._then);

  final AssistantReply _self;
  final $Res Function(AssistantReply) _then;

/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AssistantReplyType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AssistantReplyType type,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantReply() when $default != null:
return $default(_that.type,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AssistantReplyType type,  String text)  $default,) {final _that = this;
switch (_that) {
case _AssistantReply():
return $default(_that.type,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AssistantReplyType type,  String text)?  $default,) {final _that = this;
switch (_that) {
case _AssistantReply() when $default != null:
return $default(_that.type,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantReply implements AssistantReply {
  const _AssistantReply({required this.type, required this.text});
  factory _AssistantReply.fromJson(Map<String, dynamic> json) => _$AssistantReplyFromJson(json);

@override final  AssistantReplyType type;
@override final  String text;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantReply&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text);

@override
String toString() {
  return 'AssistantReply(type: $type, text: $text)';
}


}

/// @nodoc
abstract mixin class _$AssistantReplyCopyWith<$Res> implements $AssistantReplyCopyWith<$Res> {
  factory _$AssistantReplyCopyWith(_AssistantReply value, $Res Function(_AssistantReply) _then) = __$AssistantReplyCopyWithImpl;
@override @useResult
$Res call({
 AssistantReplyType type, String text
});




}
/// @nodoc
class __$AssistantReplyCopyWithImpl<$Res>
    implements _$AssistantReplyCopyWith<$Res> {
  __$AssistantReplyCopyWithImpl(this._self, this._then);

  final _AssistantReply _self;
  final $Res Function(_AssistantReply) _then;

/// Create a copy of AssistantReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,}) {
  return _then(_AssistantReply(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AssistantReplyType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
