import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/state_views.dart';

/// Statistik platform untuk admin.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final dashboard = provider.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard admin'),
        actions: [
          IconButton(
            onPressed: provider.loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: provider.loadingDashboard && dashboard == null
          ? const LoadingView()
          : provider.dashboardError != null && dashboard == null
              ? ErrorState(
                  message: provider.dashboardError!,
                  onRetry: provider.loadDashboard,
                )
              : RefreshIndicator(
                  onRefresh: provider.loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Halo, ${auth.user?.fullName.split(' ').first ?? 'Admin'}',
                        style: AppFonts.title(26),
                      ),
                      Text(
                        'Ringkasan platform HuniKos.',
                        style: AppFonts.label(13, weight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total pengguna',
                              value: '${dashboard?.totalUsers ?? 0}',
                              icon: Icons.people_outline,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Properti',
                              value: '${dashboard?.totalProperties ?? 0}',
                              icon: Icons.apartment_outlined,
                              color: AppColors.successText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Penyewa',
                              value: '${dashboard?.totalTenants ?? 0}',
                              icon: Icons.person_outline,
                              color: AppColors.goldDeep,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Pemilik',
                              value: '${dashboard?.totalOwners ?? 0}',
                              icon: Icons.storefront_outlined,
                              color: AppColors.warningText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Menunggu verifikasi',
                              value: '${dashboard?.pendingProperties ?? 0}',
                              icon: Icons.pending_actions_outlined,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Booking aktif',
                              value: '${dashboard?.activeBookings ?? 0}',
                              icon: Icons.event_available_outlined,
                              color: AppColors.navySoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppFonts.title(26, weight: FontWeight.w700),
            ),
            Text(
              label,
              style: AppFonts.label(11.5, weight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
