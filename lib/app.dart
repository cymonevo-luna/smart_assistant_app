import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/locator.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/assistant/active_listening_controller.dart';
import 'features/assistant/services/speech_to_text_service.dart';
import 'features/assistant/widgets/assistant_listening_overlay_host.dart';
import 'features/plugins/plugin_setup_deep_link_provider.dart';
import 'features/plugins/services/plugin_setup_deep_link_service.dart';
import 'features/reminders/reminder_registration_service.dart';
import 'features/reminders/services/reminder_test_deep_link_service.dart';
import 'features/reminders/widgets/reminder_sync_lifecycle.dart';
import 'l10n/app_localizations.dart';

/// Root widget. Rebuilds [MaterialApp] whenever the theme or locale providers
/// change, so switching is instant app-wide.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  ReminderTestDeepLinkService? _reminderTestDeepLinkService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pluginSetupDeepLinkNotifierProvider);
      unawaited(locator<PluginSetupDeepLinkService>().startListening());
      _reminderTestDeepLinkService = ReminderTestDeepLinkService();
      unawaited(_reminderTestDeepLinkService!.startListening());
      unawaited(_syncPendingReminders());
    });
  }

  Future<void> _syncPendingReminders() async {
    try {
      await locator<ReminderRegistrationService>().syncPendingFromApi();
    } catch (_) {
      // Offline or unauthenticated startup should not block the app shell.
    }
  }

  @override
  void dispose() {
    unawaited(_reminderTestDeepLinkService?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(speechToTextInitializationProvider);
    ref.watch(activeListeningControllerProvider);
    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return WithForegroundTask(
      child: ReminderSyncLifecycle(
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
          builder: (context, child) {
            locator<ReminderRegistrationService>().onPermissionExplanationNeeded =
                (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            };
            return AssistantListeningOverlayHost(
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
