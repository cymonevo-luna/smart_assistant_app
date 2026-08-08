import '../../../core/network/api_client.dart';
import '../models/user.dart';

/// Example repository showing the end-to-end pattern:
/// `ApiClient` -> typed `decoder` -> freezed model.
///
/// Resolve via the locator (or inject for tests):
/// `UserRepository(locator<ApiClient>())`.
class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  /// GET /me -> User
  Future<User> fetchCurrentUser() {
    return _api.get<User>('/me', decoder: (json) => User.fromJson(json));
  }

  /// GET /users -> `List<User>`
  Future<List<User>> fetchUsers() {
    return _api.get<List<User>>(
      '/users',
      decoder: (json) => (json as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// PATCH /me -> updated User
  Future<User> updateName(String name) {
    return _api.patch<User>(
      '/me',
      body: {'name': name},
      decoder: (json) => User.fromJson(json),
    );
  }
}
