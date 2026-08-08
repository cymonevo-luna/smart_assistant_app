// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocationReminder {

@JsonKey(name: 'reminder_id') String get id; String get title;@JsonKey(name: 'location_mode') LocationMode get locationMode;@JsonKey(name: 'place_query') String? get placeQuery; double? get latitude; double? get longitude;@JsonKey(name: 'place_keyword') String? get placeKeyword;@JsonKey(name: 'radius_meters') int get radiusMeters; ReminderStatus get status;
/// Create a copy of LocationReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationReminderCopyWith<LocationReminder> get copyWith => _$LocationReminderCopyWithImpl<LocationReminder>(this as LocationReminder, _$identity);

  /// Serializes this LocationReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationReminder&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.locationMode, locationMode) || other.locationMode == locationMode)&&(identical(other.placeQuery, placeQuery) || other.placeQuery == placeQuery)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.placeKeyword, placeKeyword) || other.placeKeyword == placeKeyword)&&(identical(other.radiusMeters, radiusMeters) || other.radiusMeters == radiusMeters)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,locationMode,placeQuery,latitude,longitude,placeKeyword,radiusMeters,status);

@override
String toString() {
  return 'LocationReminder(id: $id, title: $title, locationMode: $locationMode, placeQuery: $placeQuery, latitude: $latitude, longitude: $longitude, placeKeyword: $placeKeyword, radiusMeters: $radiusMeters, status: $status)';
}


}

/// @nodoc
abstract mixin class $LocationReminderCopyWith<$Res>  {
  factory $LocationReminderCopyWith(LocationReminder value, $Res Function(LocationReminder) _then) = _$LocationReminderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reminder_id') String id, String title,@JsonKey(name: 'location_mode') LocationMode locationMode,@JsonKey(name: 'place_query') String? placeQuery, double? latitude, double? longitude,@JsonKey(name: 'place_keyword') String? placeKeyword,@JsonKey(name: 'radius_meters') int radiusMeters, ReminderStatus status
});




}
/// @nodoc
class _$LocationReminderCopyWithImpl<$Res>
    implements $LocationReminderCopyWith<$Res> {
  _$LocationReminderCopyWithImpl(this._self, this._then);

  final LocationReminder _self;
  final $Res Function(LocationReminder) _then;

/// Create a copy of LocationReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? locationMode = null,Object? placeQuery = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? placeKeyword = freezed,Object? radiusMeters = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,locationMode: null == locationMode ? _self.locationMode : locationMode // ignore: cast_nullable_to_non_nullable
as LocationMode,placeQuery: freezed == placeQuery ? _self.placeQuery : placeQuery // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,placeKeyword: freezed == placeKeyword ? _self.placeKeyword : placeKeyword // ignore: cast_nullable_to_non_nullable
as String?,radiusMeters: null == radiusMeters ? _self.radiusMeters : radiusMeters // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReminderStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationReminder].
extension LocationReminderPatterns on LocationReminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationReminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationReminder value)  $default,){
final _that = this;
switch (_that) {
case _LocationReminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationReminder value)?  $default,){
final _that = this;
switch (_that) {
case _LocationReminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'reminder_id')  String id,  String title, @JsonKey(name: 'location_mode')  LocationMode locationMode, @JsonKey(name: 'place_query')  String? placeQuery,  double? latitude,  double? longitude, @JsonKey(name: 'place_keyword')  String? placeKeyword, @JsonKey(name: 'radius_meters')  int radiusMeters,  ReminderStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationReminder() when $default != null:
return $default(_that.id,_that.title,_that.locationMode,_that.placeQuery,_that.latitude,_that.longitude,_that.placeKeyword,_that.radiusMeters,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'reminder_id')  String id,  String title, @JsonKey(name: 'location_mode')  LocationMode locationMode, @JsonKey(name: 'place_query')  String? placeQuery,  double? latitude,  double? longitude, @JsonKey(name: 'place_keyword')  String? placeKeyword, @JsonKey(name: 'radius_meters')  int radiusMeters,  ReminderStatus status)  $default,) {final _that = this;
switch (_that) {
case _LocationReminder():
return $default(_that.id,_that.title,_that.locationMode,_that.placeQuery,_that.latitude,_that.longitude,_that.placeKeyword,_that.radiusMeters,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'reminder_id')  String id,  String title, @JsonKey(name: 'location_mode')  LocationMode locationMode, @JsonKey(name: 'place_query')  String? placeQuery,  double? latitude,  double? longitude, @JsonKey(name: 'place_keyword')  String? placeKeyword, @JsonKey(name: 'radius_meters')  int radiusMeters,  ReminderStatus status)?  $default,) {final _that = this;
switch (_that) {
case _LocationReminder() when $default != null:
return $default(_that.id,_that.title,_that.locationMode,_that.placeQuery,_that.latitude,_that.longitude,_that.placeKeyword,_that.radiusMeters,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocationReminder implements LocationReminder {
  const _LocationReminder({@JsonKey(name: 'reminder_id') required this.id, required this.title, @JsonKey(name: 'location_mode') required this.locationMode, @JsonKey(name: 'place_query') this.placeQuery, this.latitude, this.longitude, @JsonKey(name: 'place_keyword') this.placeKeyword, @JsonKey(name: 'radius_meters') required this.radiusMeters, this.status = ReminderStatus.pending});
  factory _LocationReminder.fromJson(Map<String, dynamic> json) => _$LocationReminderFromJson(json);

@override@JsonKey(name: 'reminder_id') final  String id;
@override final  String title;
@override@JsonKey(name: 'location_mode') final  LocationMode locationMode;
@override@JsonKey(name: 'place_query') final  String? placeQuery;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey(name: 'place_keyword') final  String? placeKeyword;
@override@JsonKey(name: 'radius_meters') final  int radiusMeters;
@override@JsonKey() final  ReminderStatus status;

/// Create a copy of LocationReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationReminderCopyWith<_LocationReminder> get copyWith => __$LocationReminderCopyWithImpl<_LocationReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationReminder&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.locationMode, locationMode) || other.locationMode == locationMode)&&(identical(other.placeQuery, placeQuery) || other.placeQuery == placeQuery)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.placeKeyword, placeKeyword) || other.placeKeyword == placeKeyword)&&(identical(other.radiusMeters, radiusMeters) || other.radiusMeters == radiusMeters)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,locationMode,placeQuery,latitude,longitude,placeKeyword,radiusMeters,status);

@override
String toString() {
  return 'LocationReminder(id: $id, title: $title, locationMode: $locationMode, placeQuery: $placeQuery, latitude: $latitude, longitude: $longitude, placeKeyword: $placeKeyword, radiusMeters: $radiusMeters, status: $status)';
}


}

/// @nodoc
abstract mixin class _$LocationReminderCopyWith<$Res> implements $LocationReminderCopyWith<$Res> {
  factory _$LocationReminderCopyWith(_LocationReminder value, $Res Function(_LocationReminder) _then) = __$LocationReminderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reminder_id') String id, String title,@JsonKey(name: 'location_mode') LocationMode locationMode,@JsonKey(name: 'place_query') String? placeQuery, double? latitude, double? longitude,@JsonKey(name: 'place_keyword') String? placeKeyword,@JsonKey(name: 'radius_meters') int radiusMeters, ReminderStatus status
});




}
/// @nodoc
class __$LocationReminderCopyWithImpl<$Res>
    implements _$LocationReminderCopyWith<$Res> {
  __$LocationReminderCopyWithImpl(this._self, this._then);

  final _LocationReminder _self;
  final $Res Function(_LocationReminder) _then;

/// Create a copy of LocationReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? locationMode = null,Object? placeQuery = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? placeKeyword = freezed,Object? radiusMeters = null,Object? status = null,}) {
  return _then(_LocationReminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,locationMode: null == locationMode ? _self.locationMode : locationMode // ignore: cast_nullable_to_non_nullable
as LocationMode,placeQuery: freezed == placeQuery ? _self.placeQuery : placeQuery // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,placeKeyword: freezed == placeKeyword ? _self.placeKeyword : placeKeyword // ignore: cast_nullable_to_non_nullable
as String?,radiusMeters: null == radiusMeters ? _self.radiusMeters : radiusMeters // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReminderStatus,
  ));
}


}

// dart format on
