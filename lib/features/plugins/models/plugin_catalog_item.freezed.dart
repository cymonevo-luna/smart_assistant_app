// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plugin_catalog_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PluginCatalogItem {

 String get slug; String get name; String get description; String? get version;@JsonKey(name: 'icon_url') String? get iconUrl;@JsonKey(name: 'required_setup') bool get requiredSetup;@JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson) PluginSetupType? get setupType;
/// Create a copy of PluginCatalogItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginCatalogItemCopyWith<PluginCatalogItem> get copyWith => _$PluginCatalogItemCopyWithImpl<PluginCatalogItem>(this as PluginCatalogItem, _$identity);

  /// Serializes this PluginCatalogItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginCatalogItem&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.version, version) || other.version == version)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.requiredSetup, requiredSetup) || other.requiredSetup == requiredSetup)&&(identical(other.setupType, setupType) || other.setupType == setupType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name,description,version,iconUrl,requiredSetup,setupType);

@override
String toString() {
  return 'PluginCatalogItem(slug: $slug, name: $name, description: $description, version: $version, iconUrl: $iconUrl, requiredSetup: $requiredSetup, setupType: $setupType)';
}


}

/// @nodoc
abstract mixin class $PluginCatalogItemCopyWith<$Res>  {
  factory $PluginCatalogItemCopyWith(PluginCatalogItem value, $Res Function(PluginCatalogItem) _then) = _$PluginCatalogItemCopyWithImpl;
@useResult
$Res call({
 String slug, String name, String description, String? version,@JsonKey(name: 'icon_url') String? iconUrl,@JsonKey(name: 'required_setup') bool requiredSetup,@JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson) PluginSetupType? setupType
});




}
/// @nodoc
class _$PluginCatalogItemCopyWithImpl<$Res>
    implements $PluginCatalogItemCopyWith<$Res> {
  _$PluginCatalogItemCopyWithImpl(this._self, this._then);

  final PluginCatalogItem _self;
  final $Res Function(PluginCatalogItem) _then;

/// Create a copy of PluginCatalogItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? name = null,Object? description = null,Object? version = freezed,Object? iconUrl = freezed,Object? requiredSetup = null,Object? setupType = freezed,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,requiredSetup: null == requiredSetup ? _self.requiredSetup : requiredSetup // ignore: cast_nullable_to_non_nullable
as bool,setupType: freezed == setupType ? _self.setupType : setupType // ignore: cast_nullable_to_non_nullable
as PluginSetupType?,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginCatalogItem].
extension PluginCatalogItemPatterns on PluginCatalogItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginCatalogItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginCatalogItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginCatalogItem value)  $default,){
final _that = this;
switch (_that) {
case _PluginCatalogItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginCatalogItem value)?  $default,){
final _that = this;
switch (_that) {
case _PluginCatalogItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String name,  String description,  String? version, @JsonKey(name: 'icon_url')  String? iconUrl, @JsonKey(name: 'required_setup')  bool requiredSetup, @JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson)  PluginSetupType? setupType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginCatalogItem() when $default != null:
return $default(_that.slug,_that.name,_that.description,_that.version,_that.iconUrl,_that.requiredSetup,_that.setupType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String name,  String description,  String? version, @JsonKey(name: 'icon_url')  String? iconUrl, @JsonKey(name: 'required_setup')  bool requiredSetup, @JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson)  PluginSetupType? setupType)  $default,) {final _that = this;
switch (_that) {
case _PluginCatalogItem():
return $default(_that.slug,_that.name,_that.description,_that.version,_that.iconUrl,_that.requiredSetup,_that.setupType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String name,  String description,  String? version, @JsonKey(name: 'icon_url')  String? iconUrl, @JsonKey(name: 'required_setup')  bool requiredSetup, @JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson)  PluginSetupType? setupType)?  $default,) {final _that = this;
switch (_that) {
case _PluginCatalogItem() when $default != null:
return $default(_that.slug,_that.name,_that.description,_that.version,_that.iconUrl,_that.requiredSetup,_that.setupType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginCatalogItem implements PluginCatalogItem {
  const _PluginCatalogItem({required this.slug, required this.name, required this.description, this.version, @JsonKey(name: 'icon_url') this.iconUrl, @JsonKey(name: 'required_setup') this.requiredSetup = false, @JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson) this.setupType});
  factory _PluginCatalogItem.fromJson(Map<String, dynamic> json) => _$PluginCatalogItemFromJson(json);

@override final  String slug;
@override final  String name;
@override final  String description;
@override final  String? version;
@override@JsonKey(name: 'icon_url') final  String? iconUrl;
@override@JsonKey(name: 'required_setup') final  bool requiredSetup;
@override@JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson) final  PluginSetupType? setupType;

/// Create a copy of PluginCatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginCatalogItemCopyWith<_PluginCatalogItem> get copyWith => __$PluginCatalogItemCopyWithImpl<_PluginCatalogItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginCatalogItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginCatalogItem&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.version, version) || other.version == version)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.requiredSetup, requiredSetup) || other.requiredSetup == requiredSetup)&&(identical(other.setupType, setupType) || other.setupType == setupType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name,description,version,iconUrl,requiredSetup,setupType);

@override
String toString() {
  return 'PluginCatalogItem(slug: $slug, name: $name, description: $description, version: $version, iconUrl: $iconUrl, requiredSetup: $requiredSetup, setupType: $setupType)';
}


}

/// @nodoc
abstract mixin class _$PluginCatalogItemCopyWith<$Res> implements $PluginCatalogItemCopyWith<$Res> {
  factory _$PluginCatalogItemCopyWith(_PluginCatalogItem value, $Res Function(_PluginCatalogItem) _then) = __$PluginCatalogItemCopyWithImpl;
@override @useResult
$Res call({
 String slug, String name, String description, String? version,@JsonKey(name: 'icon_url') String? iconUrl,@JsonKey(name: 'required_setup') bool requiredSetup,@JsonKey(name: 'setup_type', fromJson: _setupTypeFromJson, toJson: _setupTypeToJson) PluginSetupType? setupType
});




}
/// @nodoc
class __$PluginCatalogItemCopyWithImpl<$Res>
    implements _$PluginCatalogItemCopyWith<$Res> {
  __$PluginCatalogItemCopyWithImpl(this._self, this._then);

  final _PluginCatalogItem _self;
  final $Res Function(_PluginCatalogItem) _then;

/// Create a copy of PluginCatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? name = null,Object? description = null,Object? version = freezed,Object? iconUrl = freezed,Object? requiredSetup = null,Object? setupType = freezed,}) {
  return _then(_PluginCatalogItem(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,requiredSetup: null == requiredSetup ? _self.requiredSetup : requiredSetup // ignore: cast_nullable_to_non_nullable
as bool,setupType: freezed == setupType ? _self.setupType : setupType // ignore: cast_nullable_to_non_nullable
as PluginSetupType?,
  ));
}


}

// dart format on
