import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/auth/splash_page.dart';
import 'package:smart_assistant_app/features/settings/settings_page.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import 'helpers/auth_harness.dart';

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

class _FakeAssistantSettingsNotifier extends AssistantSettingsNotifier {
  _FakeAssistantSettingsNotifier(this._settings);

  final AssistantSettings _settings;

  @override
  Future<AssistantSettings> build() async => _settings;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    locator.registerSingleton<PreferencesService>(prefs);
  });

  testWidgets('splash shows Jarvis title and tagline', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _UnauthenticatedAuthController(),
          ),
        ],
        child: _materialApp(const SplashPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Jarvis'), findsOneWidget);
    expect(
      find.text('Your AI assistant, at your command.'),
      findsOneWidget,
    );
    expect(find.textContaining('Smart Assistant'), findsNothing);

    // Tear down before splash navigation timers fire.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('about dialog shows Jarvis title and tagline', (
    WidgetTester tester,
  ) async {
    const defaults = AssistantSettings(
      wakeWord: 'Jarvis',
      activeListeningEnabled: false,
      locationReminderThresholdMeters: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(defaults),
          ),
        ],
        child: _materialApp(const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final aboutTile = find.text('About');
    await tester.scrollUntilVisible(
      aboutTile,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(aboutTile);
    await tester.pumpAndSettle();

    expect(find.text('Jarvis'), findsWidgets);
    expect(
      find.text('Your AI assistant, at your command.'),
      findsOneWidget,
    );
    expect(find.textContaining('Smart Assistant'), findsNothing);
  });
}

class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}
