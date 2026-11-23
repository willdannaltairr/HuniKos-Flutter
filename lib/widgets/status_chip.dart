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
        return const StatusStyle(Color(0x337CC79A), AppColors.successText);
      case 'AWAITING_PAYMENT':
      case 'PENDING':
      case 'OPEN':
      case 'pending':
        return const StatusStyle(Color(0x2EE4C27A), AppColors.gold);
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
      case 'suspended':
      case 'rejected':
        return const StatusStyle(Color(0x33E0796E), AppColors.dangerText);
      case 'IN_PROGRESS':
      case 'RESERVED':
        return const StatusStyle(Color(0x3396B4D3), Color(0xFFC3D8EC));
      case 'OCCUPIED':
        return const StatusStyle(Color(0x33B99248), Color(0xFFE4C27A));
      case 'MAINTENANCE':
        return const StatusStyle(Color(0x33D9A05B), Color(0xFFEBC08A));
      case 'INACTIVE':
      case 'COMPLETED':
        return const StatusStyle(Color(0x26F4EDE0), AppColors.neutralText);
      default:
        return const StatusStyle(Color(0x26F4EDE0), AppColors.neutralText);
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
