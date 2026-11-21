import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Warna latar dan warna teks untuk satu status. Teks memakai varian lebih
/// gelap dari latar agar tetap terbaca.
class StatusStyle {
  const StatusStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static StatusStyle of(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'VERIFIED':
      case 'DONE':
      case 'approved':
      case 'active':
      case 'AVAILABLE':
        return const StatusStyle(Color(0xFFDCFCE7), AppColors.successText);
      case 'AWAITING_PAYMENT':
      case 'PENDING':
      case 'OPEN':
      case 'pending':
        return const StatusStyle(Color(0xFFFEF3C7), AppColors.warningText);
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
      case 'suspended':
      case 'rejected':
        return const StatusStyle(Color(0xFFFEE2E2), AppColors.dangerText);
      case 'IN_PROGRESS':
      case 'RESERVED':
        return const StatusStyle(Color(0xFFDBEAFE), Color(0xFF1D4ED8));
      case 'OCCUPIED':
        return const StatusStyle(Color(0xFFEDE9FE), Color(0xFF6D28D9));
      case 'MAINTENANCE':
        return const StatusStyle(Color(0xFFFFEDD5), Color(0xFFC2410C));
      case 'INACTIVE':
      case 'COMPLETED':
        return const StatusStyle(Color(0xFFF1F5F9), AppColors.neutralText);
      default:
        return const StatusStyle(Color(0xFFF1F5F9), AppColors.neutralText);
    }
  }
}

/// Chip status berwarna; dipakai untuk booking, pembayaran, laporan, dan
/// status verifikasi properti.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.status, this.compact = false});

  final String label;
  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: style.foreground,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
