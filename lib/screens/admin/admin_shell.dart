import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../widgets/floating_nav_bar.dart';

/// Kerangka area admin dengan navigasi bawah.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          FloatingNavItem(
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard,
            label: I18n.t('nav.dashboard'),
          ),
          FloatingNavItem(
            icon: Icons.verified_outlined,
            selectedIcon: Icons.verified,
            label: I18n.t('nav.verification'),
          ),
          FloatingNavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: I18n.t('nav.users'),
          ),
          FloatingNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: I18n.t('nav.profile'),
          ),
        ],
      ),
    );
  }
}
