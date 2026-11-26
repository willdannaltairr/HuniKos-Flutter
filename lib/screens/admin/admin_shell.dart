import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        destinations: const [
          FloatingNavItem(
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard,
            label: 'Dasbor',
          ),
          FloatingNavItem(
            icon: Icons.verified_outlined,
            selectedIcon: Icons.verified,
            label: 'Verifikasi',
          ),
          FloatingNavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Pengguna',
          ),
          FloatingNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
