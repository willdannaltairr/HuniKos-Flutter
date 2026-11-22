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
        return const StatusStyle(Color(0xFFE1EEE0), AppColors.successText);
      case 'AWAITING_PAYMENT':
      case 'PENDING':
      case 'OPEN':
      case 'pending':
        return const StatusStyle(AppColors.goldSoft, AppColors.goldDeep);
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
      case 'suspended':
      case 'rejected':
        return const StatusStyle(Color(0xFFF6E3E0), AppColors.dangerText);
      case 'IN_PROGRESS':
      case 'RESERVED':
        return const StatusStyle(Color(0xFFEADFC8), Color(0xFF6B5320));
      case 'OCCUPIED':
        return const StatusStyle(Color(0xFFE6E2D8), AppColors.navy);
      case 'MAINTENANCE':
        return const StatusStyle(Color(0xFFF3E7D3), Color(0xFF7A5A18));
      case 'INACTIVE':
      case 'COMPLETED':
        return const StatusStyle(Color(0xFFEFEBE2), AppColors.neutralText);
      default:
        return const StatusStyle(Color(0xFFEFEBE2), AppColors.neutralText);
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
        style: AppFonts.label(
          compact ? 11 : 12,
          weight: FontWeight.w700,
          color: style.foreground,
        ),
      ),
    );
  }
}
