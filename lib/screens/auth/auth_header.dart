import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Kepala halaman auth: lambang emas, judul serif, dan penjelasan singkat.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(color: Color(0x1F14213D), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.home_work_rounded, color: AppColors.gold, size: 28),
        ),
        const SizedBox(height: 20),
        Text(title, style: AppFonts.title(29)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppFonts.label(13.5, weight: FontWeight.w500, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
