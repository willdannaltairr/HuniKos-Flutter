import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/floating_nav_bar.dart';

/// Kerangka area penyewa: navigasi bawah tetap terlihat di semua tab.
class TenantShell extends StatelessWidget {
  const TenantShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) {
          // goBranch mempertahankan tumpukan halaman tiap tab.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          FloatingNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Jelajah',
          ),
          FloatingNavItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Booking',
          ),
          FloatingNavItem(
            icon: Icons.build_outlined,
            selectedIcon: Icons.build,
            label: 'Laporan',
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
