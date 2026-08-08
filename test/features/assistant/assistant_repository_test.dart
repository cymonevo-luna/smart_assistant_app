import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';

import '../../helpers/auth_harness.dart';

void main() {
  late DioAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      );
  });

  test('createSession posts to assistant sessions endpoint', () async {
    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'id': 'sess-1',
          'session_status': 'active',
        },
      }),
    );

    final session = await locator<AssistantRepository>().createSession();
    expect(session.id, 'sess-1');
    expect(session.sessionStatus.name, 'active');
  });

  test('sendMessage posts text and source to session messages', () async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Done',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Hello',
        'source': 'button',
      },
    );

    final response = await locator<AssistantRepository>().sendMessage(
      sessionId: 'sess-1',
      text: 'Hello',
      source: 'button',
    );

    expect(response.reply.text, 'Done');
    expect(response.reply.type.name, 'text');
  });
}
