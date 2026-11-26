import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/floating_nav_bar.dart';

/// Kerangka area pemilik dengan navigasi bawah.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.navigationShell});

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
            icon: Icons.apartment_outlined,
            selectedIcon: Icons.apartment,
            label: 'Properti',
          ),
          FloatingNavItem(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note,
            label: 'Booking',
          ),
          FloatingNavItem(
            icon: Icons.payments_outlined,
            selectedIcon: Icons.payments,
            label: 'Bayar',
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
