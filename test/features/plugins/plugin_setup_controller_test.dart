import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/features/plugins/plugin_setup_deep_link_provider.dart';
import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/plugins/plugin_setup_provider.dart';
import 'package:smart_assistant_app/features/plugins/plugins_provider.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';

import '../../helpers/auth_harness.dart';
import '../../helpers/plugin_test_data.dart';

class _RecordingUrlLauncher implements PluginAuthUrlLauncher {
  final List<String> urls = [];

  @override
  Future<bool> launchAuthorizationUrl(String url) async {
    urls.add(url);
    return true;
  }
}


final _installedCalendar = nestedInstalledPlugin(
  id: 'plugin-calendar',
  slug: 'google-calendar',
  name: 'Google Calendar',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter adapter;
  late _RecordingUrlLauncher urlLauncher;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    urlLauncher = _RecordingUrlLauncher();
    locator
      ..registerSingleton<PreferencesService>(
        await PreferencesService.create(),
      )
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client))
      ..registerSingleton<PluginAuthUrlLauncher>(urlLauncher)
      ..registerSingleton<PluginSetupDeepLinkService>(
        PluginSetupDeepLinkService(),
      );
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
    );
  }

  test('startSetup launches authorization URL', () async {
    adapter.onPost(
      PluginRepository.setupPath('plugin-1'),
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'authorization_url': 'https://accounts.google.com/o/oauth2/auth',
        },
      }),
    );
    adapter.onGet(
      '${PluginRepository.setupPath('plugin-1')}/status',
      (server) => server.reply(200, {
        'success': true,
        'data': {'setup_status': 'in_progress'},
      }),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pluginSetupControllerProvider.notifier)
      ..bind('plugin-1');

    await notifier.connectGoogleAccount();

    expect(urlLauncher.urls, ['https://accounts.google.com/o/oauth2/auth']);
    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.polling,
    );
    container.read(pluginSetupControllerProvider.notifier).retry();
  });

  test('handleUri emits deep link events', () {
    final service = PluginSetupDeepLinkService();
    final events = <PluginSetupDeepLinkEvent>[];
    service.events.listen(events.add);
    service.handleUri(
      Uri.parse('smartassistant://plugin-setup/complete?status=success'),
    );
    expect(events, hasLength(1));
    expect(events.first.status, PluginSetupDeepLinkStatus.success);
  });

  test('installed plugins refresh fetches again', () async {
    var fetchCount = 0;
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.replyCallback(200, (request) {
        fetchCount++;
        return {
          'success': true,
          'data': [_installedCalendar],
        };
      }),
    );

    final repo = locator<PluginRepository>();
    await repo.listInstalled();
    await repo.listInstalled();
    expect(fetchCount, 2);
  });

  test('deep link bootstrap refreshes installed plugins', () async {
    var installedFetchCount = 0;
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.replyCallback(200, (request) {
        installedFetchCount++;
        return {
          'success': true,
          'data': [
            {
              ...Map<String, dynamic>.from(_installedCalendar),
              'setup_status':
                  installedFetchCount > 1 ? 'completed' : 'not_started',
            },
          ],
        };
      }),
    );

    final container = createContainer();
    addTearDown(container.dispose);
    container.read(pluginSetupDeepLinkNotifierProvider);
    expect(locator<PluginSetupDeepLinkService>().hasActiveListeners, isTrue);
    await container.read(installedPluginsProvider.future);
    expect(installedFetchCount, 1);

    locator<PluginSetupDeepLinkService>().handleUri(
      Uri.parse('smartassistant://plugin-setup/complete?status=success'),
    );
    for (var attempt = 0; attempt < 40; attempt++) {
      if (installedFetchCount >= 2) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    expect(installedFetchCount, greaterThanOrEqualTo(2));
  });
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}
