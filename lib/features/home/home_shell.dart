import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/brand_widgets.dart';
import '../auth/presentation/auth_controller.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _fullTabs = <_TabItem>[
    _TabItem(label: 'Turmas', route: '/', icon: Icons.class_outlined),
    _TabItem(label: 'Alunos', route: '/students', icon: Icons.people_alt_outlined),
  ];

  static const _adminTabs = <_TabItem>[
    _TabItem(label: 'Turmas', route: '/', icon: Icons.class_outlined),
    _TabItem(label: 'Alunos', route: '/students', icon: Icons.people_alt_outlined),
    _TabItem(label: 'Usuarios', route: '/users', icon: Icons.manage_accounts_outlined),
  ];

  static const _superAdminTabs = <_TabItem>[
    _TabItem(label: 'Escolas', route: '/platform/schools', icon: Icons.apartment_rounded),
  ];

  static const _parentTabs = <_TabItem>[
    _TabItem(label: 'Alunos', route: '/students', icon: Icons.people_alt_outlined),
  ];

  int _indexFromLocation(
    String location, {
    required bool isParent,
    required bool isAdmin,
    required bool isSuperAdmin,
  }) {
    if (isSuperAdmin) {
      return 0;
    }

    if (isParent) {
      return 0;
    }

    if (location == '/' || location.startsWith('/classrooms')) {
      return 0;
    }
    if (location.startsWith('/students')) {
      return 1;
    }
    if (isAdmin && location.startsWith('/users')) {
      return 2;
    }
    return 0;
  }

  List<_TabItem> _tabsFor({
    required bool isParent,
    required bool isAdmin,
    required bool isSuperAdmin,
  }) {
    if (isSuperAdmin) return _superAdminTabs;
    if (isParent) return _parentTabs;
    if (isAdmin) return _adminTabs;
    return _fullTabs;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isParent = authSession?.isParent == true;
    final isAdmin = authSession?.isAdmin == true;
    final isSuperAdmin = authSession?.isSuperAdmin == true;
    final tabs = _tabsFor(isParent: isParent, isAdmin: isAdmin, isSuperAdmin: isSuperAdmin);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(
      location,
      isParent: isParent,
      isAdmin: isAdmin,
      isSuperAdmin: isSuperAdmin,
    );
    final showBottomNavigation = !isParent && tabs.length >= 2;

    return Scaffold(
      extendBody: true,
      body: AppBackdrop(child: child),
      bottomNavigationBar: !showBottomNavigation
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF17324B).withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: NavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (idx) => context.go(tabs[idx].route),
                    destinations: [
                      for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
                    ],
                  ),
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
