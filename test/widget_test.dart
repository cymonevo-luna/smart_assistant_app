import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/di/locator.dart';
import 'package:flutter_template/core/network/api_client.dart';
import 'package:flutter_template/core/storage/preferences_service.dart';
import 'package:flutter_template/core/storage/secure_storage_service.dart';
import 'package:flutter_template/features/auth/login_page.dart';

import 'helpers/auth_harness.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    locator
      ..registerSingleton<PreferencesService>(await PreferencesService.create())
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(ApiClient(baseUrl: 'https://api.test'));
  });

  testWidgets('unauthenticated startup routes to the login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    // The splash holds for a minimum display window before resolving auth and
    // routing. Advance past it, then let navigation settle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
