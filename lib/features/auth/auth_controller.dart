import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/secure_storage_service.dart';
import '../user/models/user.dart';

/// Authentication status the rest of the app can react to (e.g. the router's
/// splash gate and logout actions).
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Snapshot of the current auth session.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.error,
  });

  final AuthStatus status;
  final User? user;

  /// True while a login/register request is in flight.
  final bool busy;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? busy,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      busy: busy ?? this.busy,
      error: error,
    );
  }
}

/// Owns the auth session against the go_template backend
/// (`/api/v1/auth/*` + `/api/v1/users/{id}`). Restores any saved session on
/// startup and exposes login / register / logout actions.
///
/// Any service cloned from this template is wired to the backend out of the box;
/// only `API_BASE_URL` in `.env` needs to point at the running service.
class AuthController extends Notifier<AuthState> {
  SecureStorageService get _secure => locator<SecureStorageService>();
  ApiClient get _api => locator<ApiClient>();

  @override
  AuthState build() {
    _restore();
    return const AuthState();
  }

  /// Restores a previously saved session: re-fetches the profile with the saved
  /// access token, transparently refreshing it once on a 401 before giving up.
  /// Any unexpected failure resolves to an unauthenticated state so the splash
  /// gate never blocks.
  Future<void> _restore() async {
    try {
      final token = await _secure.readToken();
      final userId = await _secure.readUserId();
      if (token == null || userId == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      _api.setAuthToken(token);
      try {
        final user = await _fetchUser(userId);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return;
      } on ApiException catch (e) {
        if (e.type == ApiErrorType.unauthorized && await _tryRefresh()) {
          final user = await _fetchUser(userId);
          state = state.copyWith(status: AuthStatus.authenticated, user: user);
          return;
        }
      }

      await _clearSession();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final user = await _loginRequest(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        busy: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: _messageFor(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(busy: true, error: null);
    try {
      // The backend register endpoint returns the created user but no tokens,
      // so we immediately log in to establish a session.
      await _api.post<void>(
        '/api/v1/auth/register',
        body: {'name': name, 'email': email, 'password': password},
        decoder: (_) {},
      );
      final user = await _loginRequest(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        busy: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: _messageFor(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<User> _loginRequest({
    required String email,
    required String password,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
      decoder: _unwrap,
    );
    final tokens = (data['tokens'] as Map).cast<String, dynamic>();
    final user = User.fromJson((data['user'] as Map).cast<String, dynamic>());
    await _persistSession(
      access: tokens['access_token'] as String,
      refresh: tokens['refresh_token'] as String?,
      userId: user.id,
    );
    return user;
  }

  Future<User> _fetchUser(String id) {
    return _api.get<User>(
      '/api/v1/users/$id',
      decoder: (raw) => User.fromJson(_unwrap(raw)),
    );
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _secure.readRefreshToken();
    if (refresh == null) return false;
    try {
      final data = await _api.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        body: {'refresh_token': refresh},
        decoder: _unwrap,
      );
      final tokens = (data['tokens'] as Map).cast<String, dynamic>();
      await _secure.writeToken(tokens['access_token'] as String);
      final newRefresh = tokens['refresh_token'] as String?;
      if (newRefresh != null) await _secure.writeRefreshToken(newRefresh);
      _api.setAuthToken(tokens['access_token'] as String);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _persistSession({
    required String access,
    String? refresh,
    required String userId,
  }) async {
    await _secure.writeToken(access);
    if (refresh != null) await _secure.writeRefreshToken(refresh);
    await _secure.writeUserId(userId);
    _api.setAuthToken(access);
  }

  Future<void> _clearSession() async {
    _api.setAuthToken(null);
    await _secure.deleteToken();
    await _secure.deleteRefreshToken();
    await _secure.deleteUserId();
  }

  /// Unwraps the standard `{ "success": ..., "data": ... }` API envelope.
  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    return (map['data'] as Map).cast<String, dynamic>();
  }

  /// Prefers the server-provided error message from the envelope, falling back
  /// to the generic [ApiException] message.
  String _messageFor(ApiException e) {
    final data = e.data;
    if (data is Map && data['error'] is Map) {
      final msg = (data['error'] as Map)['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return e.message;
  }
}

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
