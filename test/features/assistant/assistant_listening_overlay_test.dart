import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/assistant_controller.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/widgets/assistant_listening_overlay.dart';
import 'package:smart_assistant_app/features/assistant/widgets/assistant_listening_overlay_host.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';

Widget _materialApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  group('AssistantListeningOverlay', () {
    testWidgets('listening state renders mic animation and partial transcript',
        (tester) async {
      const uiState = AssistantUiState(
        interactionState: AssistantInteractionState.listening,
        partialTranscript: 'hello',
      );

      await tester.pumpWidget(
        _materialApp(
          AssistantListeningOverlay(
            state: uiState,
            onCancel: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('assistant_listening_overlay')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('assistant_listening_mic_animation')),
          findsOneWidget);
      expect(find.textContaining('hello'), findsOneWidget);
    });

    testWidgets('processing state renders spinner and Thinking text',
        (tester) async {
      const uiState = AssistantUiState(
        interactionState: AssistantInteractionState.processing,
      );

      await tester.pumpWidget(
        _materialApp(
          AssistantListeningOverlay(
            state: uiState,
            onCancel: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Thinking...'), findsOneWidget);
    });
  });

  group('AssistantListeningOverlayHost', () {
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
      registerReminderTestServices(
        locator,
        prefs: prefs,
        apiClient: mocked.client,
      );

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

    testWidgets('cancel button dismisses overlay', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return _materialApp(
                AssistantListeningOverlayHost(
                  child: const Scaffold(
                    body: Text('underneath'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overlayController =
          container.read(assistantListeningOverlayControllerProvider.notifier);
      overlayController.show();
      await tester.pump();

      expect(
        container.read(assistantListeningOverlayControllerProvider),
        isTrue,
      );
      expect(find.byKey(const ValueKey('assistant_listening_overlay')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('assistant_listening_overlay_cancel')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(assistantListeningOverlayControllerProvider),
        isFalse,
      );
      expect(find.byKey(const ValueKey('assistant_listening_overlay')),
          findsNothing);
    });
  });
}
