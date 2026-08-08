import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

/// Global service locator. Use `locator<T>()` to resolve singletons anywhere.
final GetIt locator = GetIt.instance;

/// Registers all app-wide services. Call once at startup, after
/// [AppConfig.load].
Future<void> setupLocator() async {
  // Storage.
  final prefs = await PreferencesService.create();
  locator
    ..registerSingleton<PreferencesService>(prefs)
    ..registerSingleton<SecureStorageService>(SecureStorageService());

  // Networking. Clears the token on 401 so the app can route to login.
  final secureStorage = locator<SecureStorageService>();
  final apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    onUnauthorized: () async {
      await secureStorage.deleteToken();
    },
  );

  // Restore a previously saved auth token (if any) onto the client.
  final savedToken = await secureStorage.readToken();
  if (savedToken != null) apiClient.setAuthToken(savedToken);

  locator.registerSingleton<ApiClient>(apiClient);
}
