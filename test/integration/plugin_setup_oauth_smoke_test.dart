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

/// End-to-end smoke test for the Google OAuth plugin setup flow.
///
/// Mirrors the manual QA checklist: start setup, open authorization URL,
/// receive the deep-link callback, poll until completed, and refresh the
/// installed-plugins list without a manual pull-to-refresh.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter adapter;
  late _RecordingUrlLauncher urlLauncher;

  const pluginId = 'plugin-calendar';
  const authorizationUrl =
      'https://accounts.google.com/o/oauth2/auth?client_id=smoke-test';

  const installedCalendar = {
    'id': pluginId,
    'slug': 'google-calendar',
    'name': 'Google Calendar',
    'description': 'Sync your calendar events',
    'enabled': true,
    'setup_status': 'not_started',
  };

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

    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.replyCallback(200, (request) {
        installedFetchCount++;
        return {
          'success': true,
          'data': [
            {
              ...installedCalendar,
              'setup_status': installedFetchCount > 2
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
        return {
          'success': true,
          'data': {
            'setup_status':
                statusPollCount < 2 ? 'in_progress' : 'completed',
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
      if (phase == PluginSetupPhase.completed && installedFetchCount >= 3) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.completed,
    );
    expect(statusPollCount, greaterThanOrEqualTo(2));
    expect(installedFetchCount, greaterThanOrEqualTo(3));

    final plugins = await container.read(installedPluginsProvider.future);
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
