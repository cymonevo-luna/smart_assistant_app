import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/pages/assistant_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/plugins/pages/my_plugins_page.dart';
import '../../features/plugins/pages/plugin_setup_page.dart';
import '../../features/plugins/pages/plugin_store_page.dart';
import '../../features/profile/profile_page.dart';
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
  pluginStore('/plugins/store'),
  myPlugins('/plugins'),
  pluginSetup('/plugins/:id/setup');

  const AppRoute(this.path);
  final String path;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. Bottom-navigation tabs live inside a
/// [StatefulShellRoute.indexedStack] so each tab is instantiated only once and
/// kept alive; everything else (auth, settings) sits on the root navigator and
/// is presented over the shell.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoute.splash.path,
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
      path: AppRoute.pluginStore.path,
      name: AppRoute.pluginStore.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PluginStorePage(),
    ),
    GoRoute(
      path: AppRoute.myPlugins.path,
      name: AppRoute.myPlugins.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyPluginsPage(),
    ),
    GoRoute(
      path: AppRoute.pluginSetup.path,
      name: AppRoute.pluginSetup.name,
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
