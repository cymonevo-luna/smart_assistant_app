import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/locator.dart';
import '../../features/assistant/pages/assistant_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/plugins/pages/manage_plugins_page.dart';
import '../../features/plugins/pages/plugin_setup_page.dart';
import '../../features/assistant/services/widget_launch_service.dart';
import '../../features/assistant/services/widget_launch_uri.dart';
import '../../features/plugins/services/plugin_setup_deep_link_service.dart';
import '../../features/plugins/services/plugin_setup_oauth_callback.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reminders/pages/reminder_notifications_page.dart';
import '../../features/settings/settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Centralized route names/paths. Reference these instead of raw strings:
/// `context.goNamed(AppRoute.assistant.name)`.
enum AppRoute {
  splash('/'),
  login('/login'),
  register('/register'),
  assistant('/assistant'),
  profile('/profile'),
  settings('/settings'),
  reminderNotifications('/settings/notifications'),
  managePlugins('/plugins'),
  pluginStore('/plugins/store'),
  pluginSetup('/plugins/:id/setup'),
  composioAiSetup('/plugins/:id/composio-setup');

  const AppRoute(this.path);
  final String path;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root navigator for overlays and global navigation from services.
GlobalKey<NavigatorState> get appRootNavigatorKey => _rootNavigatorKey;

/// The app's router. Bottom-navigation tabs live inside a
/// [StatefulShellRoute.indexedStack] so each tab is instantiated only once and
/// kept alive; everything else (auth, settings) sits on the root navigator and
/// is presented over the shell.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoute.splash.path,
  redirect: (context, state) {
    if (isPluginSetupOAuthCallback(state.uri)) {
      locator<PluginSetupDeepLinkService>().handleUri(state.uri);
      return AppRoute.managePlugins.path;
    }
    if (isWidgetListenUri(state.uri)) {
      final uri = state.uri;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        locator<WidgetLaunchService>().handleUri(uri);
      });
      return AppRoute.assistant.path;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoute.splash.path,
      name: AppRoute.splash.name,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoute.login.path,
      name: AppRoute.login.name,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoute.register.path,
      name: AppRoute.register.name,
      builder: (context, state) => const RegisterPage(),
    ),
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          MainScaffold(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          AnimatedBranchContainer(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.assistant.path,
              name: AppRoute.assistant.name,
              builder: (context, state) => const AssistantPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.managePlugins.path,
              name: AppRoute.managePlugins.name,
              builder: (context, state) {
                final tab = state.uri.queryParameters['tab'];
                final initialTab = tab == 'available'
                    ? ManagePluginsTab.available
                    : ManagePluginsTab.installed;
                return ManagePluginsPage(initialTab: initialTab);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.profile.path,
              name: AppRoute.profile.name,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.settings.path,
      name: AppRoute.settings.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoute.reminderNotifications.path,
      name: AppRoute.reminderNotifications.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReminderNotificationsPage(),
    ),
    GoRoute(
      path: AppRoute.pluginStore.path,
      name: AppRoute.pluginStore.name,
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) =>
          '${AppRoute.managePlugins.path}?tab=available',
    ),
    GoRoute(
      path: AppRoute.pluginSetup.path,
      name: AppRoute.pluginSetup.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PluginSetupPage(
        pluginId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoute.composioAiSetup.path,
      name: AppRoute.composioAiSetup.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PluginSetupPage(
        pluginId: state.pathParameters['id']!,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
