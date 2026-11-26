import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';

/// Harga bulanan dengan label kecil "/bulan" agar tidak tertukar dengan total.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.amount,
    this.style,
    this.showSuffix = true,
  });

  final num? amount;
  final TextStyle? style;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: style ??
            TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
        children: [
          TextSpan(text: amount == null ? 'Belum ada kamar' : Formatters.rupiah(amount)),
          if (showSuffix && amount != null)
            TextSpan(
              text: ' /bulan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
