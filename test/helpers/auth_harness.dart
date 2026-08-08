import 'package:get_it/get_it.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/location/location_service.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_repository.dart';
import 'package:smart_assistant_app/features/reminders/location_monitor_service.dart';
import 'package:smart_assistant_app/features/reminders/reminder_registration_service.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';

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

/// Registers reminder-related services required by [App] and [AssistantController].
void registerReminderTestServices(
  GetIt getIt, {
  required PreferencesService prefs,
  required ApiClient apiClient,
}) {
  final reminderRepository = ReminderRepository(prefs);
  getIt
    ..registerSingleton<LocationService>(LocationService())
    ..registerSingleton<ReminderRepository>(reminderRepository)
    ..registerSingleton<ReminderApiRepository>(
      ReminderApiRepository(apiClient),
    )
    ..registerSingleton<LocationMonitorService>(StubLocationMonitorService())
    ..registerSingleton<ReminderRegistrationService>(
      ReminderRegistrationService(
        reminderRepository: reminderRepository,
        reminderApiRepository: getIt<ReminderApiRepository>(),
        locationService: getIt<LocationService>(),
        locationMonitorService: getIt<LocationMonitorService>(),
      ),
    );
}
