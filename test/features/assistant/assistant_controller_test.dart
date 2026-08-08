import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/assistant_controller.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_reply.dart';
import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';
import 'package:smart_assistant_app/features/assistant/services/text_to_speech_service.dart';
import 'package:smart_assistant_app/features/location/location_service.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_api_repository.dart';
import 'package:smart_assistant_app/features/reminders/data/reminder_repository.dart';
import 'package:smart_assistant_app/features/reminders/location_monitor_service.dart';
import 'package:smart_assistant_app/features/reminders/reminder_registration_service.dart';

import '../../helpers/auth_harness.dart';

class FakeSpeechRecognizer implements SpeechRecognizer {
  FakeSpeechRecognizer({this.available = true});

  bool available;
  bool listening = false;
  void Function(SpeechRecognitionResult result)? onResult;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    return available;
  }

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => listening;

  @override
  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
    ListenMode listenMode = ListenMode.confirmation,
  }) async {
    this.onResult = onResult;
    listening = true;
  }

  @override
  Future<void> stop() async {
    listening = false;
  }

  void emitFinal(String words) {
    onResult?.call(_result(words, finalResult: true));
  }

  SpeechRecognitionResult _result(String words, {required bool finalResult}) {
    return SpeechRecognitionResult.init(
      [
        SpeechRecognitionWords(
          words,
          null,
          SpeechRecognitionWords.missingConfidence,
        ),
      ],
      finalResult ? ResultType.finalResult : ResultType.partial,
    );
  }
}

class FakeMicrophonePermissionClient implements MicrophonePermissionClient {
  @override
  Future<PermissionStatus> request() async => PermissionStatus.granted;
}

class FakeTextToSpeechEngine implements TextToSpeechEngine {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  void setCompletionHandler(void Function()? handler) {}
}

class FakeReminderRegistrationService extends ReminderRegistrationService {
  FakeReminderRegistrationService({
    required super.reminderRepository,
    required super.reminderApiRepository,
    required super.locationService,
    required super.locationMonitorService,
  });

  final handledActions = <AssistantAction>[];

  @override
  Future<void> handleActionResult(AssistantAction action) async {
    handledActions.add(action);
  }
}

void main() {
  late DioAdapter adapter;
  late FakeSpeechRecognizer recognizer;
  late FakeReminderRegistrationService fakeRegistration;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    recognizer = FakeSpeechRecognizer();

    final reminderRepository = ReminderRepository(prefs);
    final reminderApiRepository = ReminderApiRepository(mocked.client);

    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<LocationService>(LocationService())
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      )
      ..registerSingleton<ReminderRepository>(reminderRepository)
      ..registerSingleton<ReminderApiRepository>(reminderApiRepository)
      ..registerSingleton<LocationMonitorService>(StubLocationMonitorService());

    fakeRegistration = FakeReminderRegistrationService(
      reminderRepository: reminderRepository,
      reminderApiRepository: reminderApiRepository,
      locationService: locator<LocationService>(),
      locationMonitorService: locator<LocationMonitorService>(),
    );

    locator.registerSingleton<ReminderRegistrationService>(fakeRegistration);

    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'session_id': 'sess-1',
        },
      }),
    );
  });

  test('sendMessage action_result invokes reminder registration service', () async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'action_result',
            'text': 'Reminder set for the grocery store.',
            'action': {
              'plugin_slug': 'set-reminder',
              'status': 'success',
              'payload': {
                'reminder_id': 'rem-ctrl-1',
                'title': 'Grocery store',
                'location_mode': 'exact',
                'latitude': 37.7749,
                'longitude': -122.4194,
                'radius_meters': 150,
                'status': 'pending',
              },
            },
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Remind me at the grocery store',
        'source': 'wake_word',
      },
    );

    final container = ProviderContainer(
      overrides: [
        speechToTextServiceProvider.overrideWithValue(
          SpeechToTextService(
            recognizer: recognizer,
            permissionClient: FakeMicrophonePermissionClient(),
          ),
        ),
        textToSpeechServiceProvider.overrideWithValue(
          TextToSpeechService(engine: FakeTextToSpeechEngine()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(assistantControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.sendWakeWordCommand('Remind me at the grocery store');
    await Future<void>.delayed(Duration.zero);

    expect(fakeRegistration.handledActions, hasLength(1));
    expect(fakeRegistration.handledActions.first.pluginSlug, 'set-reminder');
    expect(fakeRegistration.handledActions.first.status, 'success');
    expect(
      fakeRegistration.handledActions.first.payload?['reminder_id'],
      'rem-ctrl-1',
    );

    final state = container.read(assistantControllerProvider);
    expect(
      state.messages.any(
        (message) =>
            !message.isUser &&
            message.text == 'Reminder set for the grocery store.',
      ),
      isTrue,
    );
  });
}
