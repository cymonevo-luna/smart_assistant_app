import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_assistant_app/core/theme/app_palette.dart';
import 'package:smart_assistant_app/core/theme/app_theme.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/auth/splash_page.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';
import 'package:smart_assistant_app/shared/widgets/app_logo.dart';

Widget _themedApp({
  required Widget child,
  required Color primary,
  Color? secondary,
  Brightness brightness = Brightness.dark,
  Key? appKey,
}) {
  final base = brightness == Brightness.dark
      ? AppTheme.dark(AppAccent.red)
      : AppTheme.light(AppAccent.red);
  final scheme = base.colorScheme.copyWith(
    primary: primary,
    secondary: secondary ?? base.colorScheme.secondary,
  );

  return MaterialApp(
    key: appKey,
    theme: base.copyWith(colorScheme: scheme),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Widget _splashTestApp({
  required Color primary,
  required AuthController Function() authOverride,
}) {
  final base = AppTheme.dark(AppAccent.red);
  final scheme = base.colorScheme.copyWith(primary: primary);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const SizedBox(key: Key('login')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(authOverride),
    ],
    child: MaterialApp.router(
      theme: base.copyWith(colorScheme: scheme),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

BoxDecoration _logoDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppLogo),
      matching: find.byType(Container),
    ).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('AppLogo renders arc-reactor CustomPaint instead of layers icon',
      (tester) async {
    await tester.pumpWidget(
      _themedApp(
        child: const Scaffold(body: Center(child: AppLogo(size: 96))),
        primary: const Color(0xFFEF4444),
      ),
    );

    expect(find.byIcon(Icons.layers_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppLogo),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('AppLogo gradient follows red ColorScheme.primary', (tester) async {
    const red = Color(0xFFEF4444);

    await tester.pumpWidget(
      _themedApp(
        child: const Scaffold(body: Center(child: AppLogo())),
        primary: red,
      ),
    );

    final gradient = _logoDecoration(tester).gradient! as LinearGradient;
    expect(gradient.colors.first, red);
  });

  testWidgets('AppLogo gradient follows purple ColorScheme.primary',
      (tester) async {
    const purple = Color(0xFF8B5CF6);

    await tester.pumpWidget(
      _themedApp(
        child: const Scaffold(body: Center(child: AppLogo())),
        primary: purple,
      ),
    );

    final gradient = _logoDecoration(tester).gradient! as LinearGradient;
    expect(gradient.colors.first, purple);
  });

  testWidgets('AppLogo scales at 96px without clipping', (tester) async {
    await tester.pumpWidget(
      _themedApp(
        child: const Scaffold(body: Center(child: AppLogo(size: 96))),
        primary: const Color(0xFFEF4444),
      ),
    );

    final logoBox = tester.getRect(find.byType(AppLogo));
    expect(logoBox.width, 96);
    expect(logoBox.height, 96);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Splash page shows AppLogo with dark scaffold background',
      (tester) async {
    const primary = Color(0xFFEF4444);

    await tester.pumpWidget(
      _splashTestApp(
        primary: primary,
        authOverride: _UnauthenticatedAuthController.new,
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byIcon(Icons.layers_rounded), findsNothing);

    final theme = Theme.of(tester.element(find.byType(SplashPage)));
    expect(theme.scaffoldBackgroundColor, AppPalette.darkScaffold);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
  });

  testWidgets('Splash progress indicator uses theme primary color',
      (tester) async {
    const primary = Color(0xFFEF4444);

    await tester.pumpWidget(
      _splashTestApp(
        primary: primary,
        authOverride: _UnauthenticatedAuthController.new,
      ),
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    final theme = Theme.of(
      tester.element(find.byType(LinearProgressIndicator)),
    );

    expect(indicator.color ?? theme.colorScheme.primary, primary);
    expect(indicator.backgroundColor, primary.withValues(alpha: 0.15));

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
  });
}

class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}
