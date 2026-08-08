import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_session.dart';

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
          'session_id': 'sess-1',
        },
      }),
    );

    final session = await locator<AssistantRepository>().createSession();
    expect(session.id, 'sess-1');
    expect(session.sessionStatus.name, 'active');
  });

  test('createSession defaults sessionStatus when absent from API response', () async {
    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'session_id': 'sess-live',
        },
      }),
    );

    final session = await locator<AssistantRepository>().createSession();
    expect(session.id, 'sess-live');
    expect(session.sessionStatus, AssistantSessionStatus.active);
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

    expect(response.response.reply.text, 'Done');
    expect(response.response.reply.type.name, 'text');
  });

  test('sendMessage parses action_result reply with action payload', () async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'action_result',
            'text': 'Reminder set.',
            'action': {
              'plugin_slug': 'set-reminder',
              'status': 'success',
              'payload': {
                'reminder_id': 'rem-api-1',
                'title': 'Home',
                'location_mode': 'exact',
                'latitude': 37.7749,
                'longitude': -122.4194,
                'radius_meters': 150,
              },
            },
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Remind me at home',
        'source': 'button',
      },
    );

    final response = await locator<AssistantRepository>().sendMessage(
      sessionId: 'sess-1',
      text: 'Remind me at home',
      source: 'button',
    );

    expect(response.response.reply.type.name, 'actionResult');
    expect(response.response.reply.text, 'Reminder set.');
    expect(response.response.reply.action?.pluginSlug, 'set-reminder');
    expect(response.response.reply.action?.status, 'success');
    expect(response.response.reply.action?.payload?['reminder_id'], 'rem-api-1');
  });
}
