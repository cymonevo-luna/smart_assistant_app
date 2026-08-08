import 'package:flutter_template/core/network/api_client.dart';
import 'package:flutter_template/core/storage/secure_storage_service.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// In-memory [SecureStorageService] for tests: overrides the primitive
/// read/write/delete so no platform channel (Keychain / EncryptedSharedPrefs)
/// is touched. The convenience token helpers reuse these overrides.
class FakeSecureStorage extends SecureStorageService {
  final Map<String, String> store = <String, String>{};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<void> delete(String key) async => store.remove(key);

  @override
  Future<void> clear() async => store.clear();
}

/// Builds an [ApiClient] whose underlying Dio is backed by a mock adapter so
/// requests can be stubbed without a live backend.
({ApiClient client, DioAdapter adapter}) buildMockedApiClient() {
  final client = ApiClient(baseUrl: 'https://api.test');
  final adapter = DioAdapter(dio: client.raw);
  return (client: client, adapter: adapter);
}
