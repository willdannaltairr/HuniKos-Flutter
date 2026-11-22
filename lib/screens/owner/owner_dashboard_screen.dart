import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/state_views.dart';

/// Dashboard pemilik: ringkasan kamar, antrean kerja, dan pendapatan.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final auth = context.watch<AuthProvider>();
    final dashboard = provider.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: provider.loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
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
                        'Halo, ${auth.user?.fullName.split(' ').first ?? 'Pemilik'}',
                        style: AppFonts.title(26),
                      ),
                      Text(
                        'Ringkasan kos kamu hari ini.',
                        style: AppFonts.label(13, weight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      _RevenueCard(
                        revenue: dashboard?.revenueThisMonth ?? 0,
                        occupancy: dashboard?.occupancyRate ?? 0,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Kamar tersedia',
                              value: '${dashboard?.availableRooms ?? 0}',
                              of: '${dashboard?.totalRooms ?? 0} kamar',
                              icon: Icons.door_front_door_outlined,
                              color: AppColors.successText,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Kamar terisi',
                              value: '${dashboard?.occupiedRooms ?? 0}',
                              of: '${dashboard?.totalRooms ?? 0} kamar',
                              icon: Icons.person_pin_circle_outlined,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Properti disetujui',
                              value: '${dashboard?.approvedProperties ?? 0}',
                              of: 'dari ${dashboard?.totalProperties ?? 0}',
                              icon: Icons.verified_outlined,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Tingkat hunian',
                              value: '${(dashboard?.occupancyRate ?? 0).toStringAsFixed(1)}%',
                              of: 'semua kamar',
                              icon: Icons.percent,
                              color: AppColors.warningText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Perlu tindakan',
                        style: AppFonts.title(19, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _ActionTile(
                        label: 'Booking menunggu keputusan',
                        count: dashboard?.pendingBookings ?? 0,
                        icon: Icons.event_available_outlined,
                        onTap: () => context.go('/owner/bookings'),
                      ),
                      _ActionTile(
                        label: 'Pembayaran menunggu verifikasi',
                        count: dashboard?.pendingPayments ?? 0,
                        icon: Icons.receipt_long_outlined,
                        onTap: () => context.go('/owner/payments'),
                      ),
                      _ActionTile(
                        label: 'Laporan kerusakan terbuka',
                        count: dashboard?.openMaintenance ?? 0,
                        icon: Icons.build_outlined,
                        onTap: () => context.go('/owner/maintenance'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.revenue, required this.occupancy});

  final double revenue;
  final double occupancy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan bulan ini',
            style: AppFonts.label(12, weight: FontWeight.w500, color: AppColors.goldSoft),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.rupiah(revenue),
            style: AppFonts.title(26, weight: FontWeight.w700, color: AppColors.ivory),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (occupancy / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.ivory.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hunian terisi ${occupancy.toStringAsFixed(1)}%',
            style: AppFonts.label(11.5, weight: FontWeight.w500, color: AppColors.goldSoft),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.of,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String of;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppFonts.title(24, weight: FontWeight.w700),
            ),
            Text(
              label,
              style: AppFonts.label(11.5, weight: FontWeight.w500, color: AppColors.textSecondary),
            ),
            Text(
              of,
              style: AppFonts.label(10.5, weight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 13.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: AppFonts.label(11.5, weight: FontWeight.w700, color: AppColors.goldDeep),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
