import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';
import '../providers/owner_provider.dart';
import '../providers/tenant_provider.dart';

/// Ringkasan keuangan di halaman profil. Isi kartu berbeda tiap peran:
/// penyewa melihat pengeluaran, pemilik pendapatan, admin aktivitas platform.
class ProfileFinanceCard extends StatelessWidget {
  const ProfileFinanceCard({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    // Diawasi semuanya supaya angka ikut berubah saat data selesai dimuat.
    final tenant = context.watch<TenantProvider>();
    final owner = context.watch<OwnerProvider>();
    final admin = context.watch<AdminProvider>();

    if (role == 'tenant') {
      return _FinanceCard(
        title: I18n.t('finance.title'),
        items: [
          _FinanceItem(
            label: I18n.t('finance.spentTotal'),
            value: Formatters.rupiah(tenant.totalSpent),
            icon: Icons.payments_outlined,
            color: AppColors.primary,
          ),
          _FinanceItem(
            label: I18n.t('finance.spentMonth'),
            value: Formatters.rupiah(tenant.spentThisMonth),
            icon: Icons.calendar_month_outlined,
            color: AppColors.successText,
          ),
          _FinanceItem(
            label: I18n.t('finance.activeBookings'),
            value: '${tenant.activeBookingCount}',
            icon: Icons.event_available_outlined,
            color: AppColors.warningText,
          ),
        ],
      );
    }

    if (role == 'owner') {
      final data = owner.dashboard;
      return _FinanceCard(
        title: I18n.t('finance.title'),
        items: [
          _FinanceItem(
            label: I18n.t('finance.revenueMonth'),
            value: Formatters.rupiah(data?.revenueThisMonth ?? 0),
            icon: Icons.trending_up_rounded,
            color: AppColors.successText,
          ),
          _FinanceItem(
            label: I18n.t('finance.pendingPayments'),
            value: '${data?.pendingPayments ?? 0}',
            icon: Icons.hourglass_top_outlined,
            color: AppColors.warningText,
          ),
          _FinanceItem(
            label: I18n.t('finance.occupiedRooms'),
            value: '${data?.occupiedRooms ?? 0}',
            icon: Icons.meeting_room_outlined,
            color: AppColors.primary,
          ),
        ],
      );
    }

    final data = admin.dashboard;
    return _FinanceCard(
      title: I18n.t('finance.title'),
      items: [
        _FinanceItem(
          label: I18n.t('finance.totalUsers'),
          value: '${data?.totalUsers ?? 0}',
          icon: Icons.people_outline,
          color: AppColors.primary,
        ),
        _FinanceItem(
          label: I18n.t('finance.pendingVerification'),
          value: '${data?.pendingProperties ?? 0}',
          icon: Icons.pending_actions_outlined,
          color: AppColors.warningText,
        ),
        _FinanceItem(
          label: I18n.t('finance.activeBookingsAll'),
          value: '${data?.activeBookings ?? 0}',
          icon: Icons.event_available_outlined,
          color: AppColors.successText,
        ),
      ],
    );
  }
}

class _FinanceItem {
  const _FinanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.title, required this.items});

  final String title;
  final List<_FinanceItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.title(16, weight: FontWeight.w700)),
            const SizedBox(height: 14),
            Row(
              children: [for (final item in items) Expanded(child: _Tile(item: item))],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final _FinanceItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.title(14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.label(10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
