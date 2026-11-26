import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Label kecil di atas bubble: peran `Owner` memakai emas/navy, label kamar
/// dan calon penyewa memakai abu-abu netral.
class ChatBadge extends StatelessWidget {
  const ChatBadge({super.key, required this.label, this.compact = false});

  final String label;
  final bool compact;

  /// Teks kosong tidak perlu mengambil tempat di atas bubble.
  static bool shouldShow(String? label) =>
      label != null && label.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim();
    final isOwner = normalized.toLowerCase() == 'owner';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        // Warna token mengikuti tema terang/gelap yang sedang aktif.
        color: isOwner ? AppColors.goldSoft : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOwner ? AppColors.goldDeep : AppColors.border,
        ),
      ),
      child: Text(
        normalized,
        style: AppFonts.label(
          compact ? 10 : 11,
          weight: FontWeight.w700,
          color: isOwner ? AppColors.goldDeep : AppColors.neutralText,
        ),
      ),
    );
  }
}
