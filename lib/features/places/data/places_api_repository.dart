import '../../../core/network/api_client.dart';
import '../models/nearby_place.dart';

/// Fetches nearby places from the backend API.
class PlacesApiRepository {
  PlacesApiRepository(this._api);

  final ApiClient _api;

  static const nearbyPath = '/api/v1/places/nearby';

  Future<List<NearbyPlace>> fetchNearby({
    required String keyword,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    return _api.get<List<NearbyPlace>>(
      nearbyPath,
      query: {
        'keyword': keyword,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
      },
      decoder: (raw) => _parseList(raw),
    );
  }

  List<NearbyPlace> _parseList(dynamic raw) {
    final items = _unwrapList(raw);
    return items
        .map(
          (item) => NearbyPlace.fromJson(
            (item as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    final map = (raw as Map).cast<String, dynamic>();
    if (map.containsKey('data')) {
      return (map['data'] as List).cast<dynamic>();
    }
    return map.values.first as List<dynamic>;
  }
}
