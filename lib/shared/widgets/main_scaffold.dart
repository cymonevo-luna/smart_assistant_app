import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Shell scaffold for the bottom-navigation tabs. Backed by
/// [StatefulShellRoute.indexedStack], so each tab is built exactly once and
/// kept alive — switching tabs swaps the active branch instead of pushing a new
/// page, which avoids growing the navigation stack.
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelected(int index) {
    // Re-tapping the active tab pops it back to its initial location.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_box_outlined),
            selectedIcon: const Icon(Icons.check_box),
            label: l10n.tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.messages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

/// Hosts the branch navigators (like an [IndexedStack], so every tab stays
/// alive) but slides horizontally when the active tab changes — left/right
/// depending on the direction of travel.
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late int _currentIndex;
  late int _previousIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.currentIndex;
      _direction = _currentIndex > _previousIndex ? 1 : -1;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final animating = !_controller.isCompleted;
        final t = Curves.easeInOut.transform(_controller.value);

        final background = <Widget>[];
        Widget? outgoing;
        Widget? incoming;

        for (var i = 0; i < widget.children.length; i++) {
          // Branch navigators keep their own GlobalKeys, so moving them between
          // Offstage/SlideTransition wrappers preserves their state.
          final child = widget.children[i];
          final isCurrent = i == _currentIndex;
          final isPrevious =
              i == _previousIndex && animating && _previousIndex != _currentIndex;

          if (isCurrent) {
            incoming = FractionalTranslation(
              translation: Offset((1 - t) * _direction, 0),
              child: child,
            );
          } else if (isPrevious) {
            outgoing = FractionalTranslation(
              translation: Offset(-t * _direction, 0),
              child: child,
            );
          } else {
            background.add(
              Offstage(child: TickerMode(enabled: false, child: child)),
            );
          }
        }

        return IgnorePointer(
          ignoring: animating,
          child: Stack(
            children: [
              ...background,
              ?outgoing,
              ?incoming,
            ],
          ),
        );
      },
    );
  }
}
