import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/placeholder/coming_soon_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/showcase/showcase_page.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Centralized route names/paths. Reference these instead of raw strings:
/// `context.goNamed(AppRoute.home.name)`.
enum AppRoute {
  splash('/'),
  login('/login'),
  register('/register'),
  home('/home'),
  tasks('/tasks'),
  calendar('/calendar'),
  messages('/messages'),
  profile('/profile'),
  settings('/settings'),
  details('/details');

  const AppRoute(this.path);
  final String path;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. Bottom-navigation tabs live inside a
/// [StatefulShellRoute.indexedStack] so each tab is instantiated only once and
/// kept alive; everything else (auth, settings, details) sits on the root
/// navigator and is presented over the shell.
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
              path: AppRoute.home.path,
              name: AppRoute.home.name,
              builder: (context, state) => const ShowcasePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.tasks.path,
              name: AppRoute.tasks.name,
              builder: (context, state) => ComingSoonPage(
                title: AppLocalizations.of(context).tasks,
                icon: Icons.check_box_outlined,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.calendar.path,
              name: AppRoute.calendar.name,
              builder: (context, state) => ComingSoonPage(
                title: AppLocalizations.of(context).calendar,
                icon: Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.messages.path,
              name: AppRoute.messages.name,
              builder: (context, state) => ComingSoonPage(
                title: AppLocalizations.of(context).messages,
                icon: Icons.chat_bubble_outline,
              ),
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
      path: AppRoute.details.path,
      name: AppRoute.details.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const _DetailsPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);

/// Placeholder destination to demonstrate navigation. Replace with real pages.
class _DetailsPage extends StatelessWidget {
  const _DetailsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(child: Text('Details page')),
    );
  }
}
