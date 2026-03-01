import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/brand_widgets.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = <_TabItem>[
    _TabItem(label: 'Turmas', route: '/', icon: Icons.class_outlined),
    _TabItem(label: 'Alunos', route: '/students', icon: Icons.people_alt_outlined),
  ];

  int _indexFromLocation(String location) {
    if (location == '/' || location.startsWith('/classrooms')) {
      return 0;
    }
    if (location.startsWith('/students')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      extendBody: true,
      body: AppBackdrop(child: child),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 72,
            selectedIndex: currentIndex,
            onDestinationSelected: (idx) => context.go(_tabs[idx].route),
            destinations: [
              for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final String route;
  final IconData icon;
  const _TabItem({required this.label, required this.route, required this.icon});
}
