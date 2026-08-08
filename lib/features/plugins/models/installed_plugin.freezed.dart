// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'installed_plugin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstalledPlugin {

 String get id; String get slug; String get name; String get description; bool get enabled;@JsonKey(name: 'setup_status') PluginSetupStatus get setupStatus;
/// Create a copy of InstalledPlugin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstalledPluginCopyWith<InstalledPlugin> get copyWith => _$InstalledPluginCopyWithImpl<InstalledPlugin>(this as InstalledPlugin, _$identity);

  /// Serializes this InstalledPlugin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstalledPlugin&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.setupStatus, setupStatus) || other.setupStatus == setupStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,description,enabled,setupStatus);

@override
String toString() {
  return 'InstalledPlugin(id: $id, slug: $slug, name: $name, description: $description, enabled: $enabled, setupStatus: $setupStatus)';
}


}

/// @nodoc
abstract mixin class $InstalledPluginCopyWith<$Res>  {
  factory $InstalledPluginCopyWith(InstalledPlugin value, $Res Function(InstalledPlugin) _then) = _$InstalledPluginCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String description, bool enabled,@JsonKey(name: 'setup_status') PluginSetupStatus setupStatus
});




}
/// @nodoc
class _$InstalledPluginCopyWithImpl<$Res>
    implements $InstalledPluginCopyWith<$Res> {
  _$InstalledPluginCopyWithImpl(this._self, this._then);

  final InstalledPlugin _self;
  final $Res Function(InstalledPlugin) _then;

/// Create a copy of InstalledPlugin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? description = null,Object? enabled = null,Object? setupStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,setupStatus: null == setupStatus ? _self.setupStatus : setupStatus // ignore: cast_nullable_to_non_nullable
as PluginSetupStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [InstalledPlugin].
extension InstalledPluginPatterns on InstalledPlugin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstalledPlugin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstalledPlugin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstalledPlugin value)  $default,){
final _that = this;
switch (_that) {
case _InstalledPlugin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstalledPlugin value)?  $default,){
final _that = this;
switch (_that) {
case _InstalledPlugin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String description,  bool enabled, @JsonKey(name: 'setup_status')  PluginSetupStatus setupStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstalledPlugin() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.description,_that.enabled,_that.setupStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String description,  bool enabled, @JsonKey(name: 'setup_status')  PluginSetupStatus setupStatus)  $default,) {final _that = this;
switch (_that) {
case _InstalledPlugin():
return $default(_that.id,_that.slug,_that.name,_that.description,_that.enabled,_that.setupStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String description,  bool enabled, @JsonKey(name: 'setup_status')  PluginSetupStatus setupStatus)?  $default,) {final _that = this;
switch (_that) {
case _InstalledPlugin() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.description,_that.enabled,_that.setupStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstalledPlugin implements InstalledPlugin {
  const _InstalledPlugin({required this.id, required this.slug, required this.name, this.description = '', required this.enabled, @JsonKey(name: 'setup_status') required this.setupStatus});
  factory _InstalledPlugin.fromJson(Map<String, dynamic> json) => _$InstalledPluginFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String name;
@override@JsonKey() final  String description;
@override final  bool enabled;
@override@JsonKey(name: 'setup_status') final  PluginSetupStatus setupStatus;

/// Create a copy of InstalledPlugin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstalledPluginCopyWith<_InstalledPlugin> get copyWith => __$InstalledPluginCopyWithImpl<_InstalledPlugin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstalledPluginToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstalledPlugin&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.setupStatus, setupStatus) || other.setupStatus == setupStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,description,enabled,setupStatus);

@override
String toString() {
  return 'InstalledPlugin(id: $id, slug: $slug, name: $name, description: $description, enabled: $enabled, setupStatus: $setupStatus)';
}


}

/// @nodoc
abstract mixin class _$InstalledPluginCopyWith<$Res> implements $InstalledPluginCopyWith<$Res> {
  factory _$InstalledPluginCopyWith(_InstalledPlugin value, $Res Function(_InstalledPlugin) _then) = __$InstalledPluginCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String description, bool enabled,@JsonKey(name: 'setup_status') PluginSetupStatus setupStatus
});




}
/// @nodoc
class __$InstalledPluginCopyWithImpl<$Res>
    implements _$InstalledPluginCopyWith<$Res> {
  __$InstalledPluginCopyWithImpl(this._self, this._then);

  final _InstalledPlugin _self;
  final $Res Function(_InstalledPlugin) _then;

/// Create a copy of InstalledPlugin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? description = null,Object? enabled = null,Object? setupStatus = null,}) {
  return _then(_InstalledPlugin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,setupStatus: null == setupStatus ? _self.setupStatus : setupStatus // ignore: cast_nullable_to_non_nullable
as PluginSetupStatus,
  ));
}


}

// dart format on
