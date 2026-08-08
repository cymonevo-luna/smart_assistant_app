import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/assistant/active_listening_controller.dart';
import 'features/assistant/services/speech_to_text_service.dart';
import 'l10n/app_localizations.dart';

/// Root widget. Rebuilds [MaterialApp] whenever the theme or locale providers
/// change, so switching is instant app-wide.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(speechToTextInitializationProvider);
    ref.watch(activeListeningControllerProvider);
    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return WithForegroundTask(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(theme.accent),
        darkTheme: AppTheme.dark(theme.accent),
        themeMode: theme.mode,
        locale: locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
      ),
    );
  }
}
