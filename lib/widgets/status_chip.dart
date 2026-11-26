import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Warna latar dan warna teks untuk satu status. Pada tema terang, latar
/// memakai pastel lembut dan teks memakai varian gelap agar kontrasnya cukup.
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
        return const StatusStyle(Color(0xFFE7F5E8), AppColors.successText);
      case 'AWAITING_PAYMENT':
      case 'PENDING':
      case 'OPEN':
      case 'pending':
        return const StatusStyle(Color(0xFFFFF4E5), AppColors.warningText);
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
      case 'suspended':
      case 'rejected':
        return const StatusStyle(Color(0xFFFFEBE9), AppColors.dangerText);
      case 'IN_PROGRESS':
      case 'RESERVED':
        return const StatusStyle(Color(0xFFEBF3FF), Color(0xFF1D4ED8));
      case 'OCCUPIED':
        return const StatusStyle(Color(0xFFF3EDFF), Color(0xFF6B3FA0));
      case 'MAINTENANCE':
        return const StatusStyle(Color(0xFFFDF0E3), Color(0xFF9A5B1B));
      case 'INACTIVE':
      case 'COMPLETED':
        return const StatusStyle(Color(0xFFF2F2F2), AppColors.neutralText);
      default:
        return const StatusStyle(Color(0xFFF2F2F2), AppColors.neutralText);
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
