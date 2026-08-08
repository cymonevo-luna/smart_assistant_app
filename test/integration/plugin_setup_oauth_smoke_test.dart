import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/plugins/models/plugin_setup_status.dart';
import 'package:smart_assistant_app/features/plugins/plugin_setup_deep_link_provider.dart';
import 'package:smart_assistant_app/features/plugins/plugin_setup_provider.dart';
import 'package:smart_assistant_app/features/plugins/plugins_provider.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';

import '../helpers/auth_harness.dart';
import '../helpers/plugin_test_data.dart';

/// End-to-end smoke test for the Google OAuth plugin setup flow.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter adapter;
  late _RecordingUrlLauncher urlLauncher;

  const pluginId = 'plugin-calendar';
  const authorizationUrl =
      'https://accounts.google.com/o/oauth2/auth?client_id=smoke-test';

  final installedCalendar = nestedInstalledPlugin(
    id: pluginId,
    slug: 'google-calendar',
    name: 'Google Calendar',
  );

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

  test('manual Google setup smoke flow completes plugin setup', () async {
    var installedFetchCount = 0;
    var statusPollCount = 0;
    var setupCompleted = false;

    adapter.onGet(
      PluginRepository.catalogPath,
      (server) => server.reply(200, {
        'success': true,
        'data': <Map<String, dynamic>>[],
      }),
    );

    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.replyCallback(200, (request) {
        installedFetchCount++;
        return {
          'success': true,
          'data': [
            {
              ...installedCalendar,
              'setup_status': setupCompleted
                  ? 'completed'
                  : installedCalendar['setup_status'],
            },
          ],
        };
      }),
    );

    adapter.onPost(
      PluginRepository.setupPath(pluginId),
      (server) => server.reply(200, {
        'success': true,
        'data': {'authorization_url': authorizationUrl},
      }),
    );

    adapter.onGet(
      '${PluginRepository.setupPath(pluginId)}/status',
      (server) => server.replyCallback(200, (request) {
        statusPollCount++;
        final completed = statusPollCount >= 2;
        if (completed) {
          setupCompleted = true;
        }
        return {
          'success': true,
          'data': {
            'setup_status': completed ? 'completed' : 'in_progress',
          },
        };
      }),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
    );
    addTearDown(container.dispose);

    container.read(pluginSetupDeepLinkNotifierProvider);
    await container.read(installedPluginsProvider.future);
    expect(installedFetchCount, 1);

    final setupNotifier = container.read(pluginSetupControllerProvider.notifier)
      ..bind(pluginId);
    await setupNotifier.connectGoogleAccount();

    expect(urlLauncher.urls, [authorizationUrl]);
    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.polling,
    );

    locator<PluginSetupDeepLinkService>().handleUri(
      Uri.parse('smartassistant://plugin-setup/complete?status=success'),
    );

    for (var attempt = 0; attempt < 40; attempt++) {
      final phase = container.read(pluginSetupControllerProvider).phase;
      if (phase == PluginSetupPhase.completed && setupCompleted) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.completed,
    );
    expect(statusPollCount, greaterThanOrEqualTo(2));
    expect(installedFetchCount, greaterThanOrEqualTo(2));

    await container.read(installedPluginsProvider.notifier).refresh();
    final plugins = container.read(installedPluginsProvider).requireValue;
    expect(plugins.single.setupStatus, PluginSetupStatus.completed);
  });
}

class _RecordingUrlLauncher implements PluginAuthUrlLauncher {
  final List<String> urls = [];

  @override
  Future<bool> launchAuthorizationUrl(String url) async {
    urls.add(url);
    return true;
  }
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}
