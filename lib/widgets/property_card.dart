import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/property.dart';
import 'price_text.dart';
import 'status_chip.dart';

/// Kartu properti bergaya Airbnb: foto besar bersudut bulat, lalu judul,
/// lokasi, dan harga tanpa kotak pembatas.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onImageTap,
    this.trailing,
    this.showOwner = false,
  });

  final PropertyItem property;
  final VoidCallback? onTap;
  final VoidCallback? onImageTap;
  final Widget? trailing;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onImageTap ?? onTap,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _cover(),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Badge(text: 'Kos ${property.typeLabel}'),
                    ),
                    if (property.verificationStatus != null)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: StatusChip(
                          compact: true,
                          status: property.verificationStatus!,
                          label: _verificationLabel(property.verificationStatus!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  property.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.title(16, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, size: 16, color: AppColors.goldDeep),
              const SizedBox(width: 2),
              Text(
                property.availableRooms > 0 ? 'Tersedia' : 'Penuh',
                style: AppFonts.label(
                  12,
                  weight: FontWeight.w600,
                  color: property.availableRooms > 0
                      ? AppColors.successText
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${property.city} · ${property.availableRooms}/${property.totalRooms} kamar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.label(12.5, weight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          if (showOwner && property.ownerName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Pemilik: ${property.ownerName}',
                style: AppFonts.label(12, weight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 6),
          PriceText(
            amount: property.minPrice,
            style: AppFonts.label(15, weight: FontWeight.w800, color: AppColors.navy),
          ),
          if (property.rejectionNote != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBEAE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ditolak: ${property.rejectionNote}',
                style: AppFonts.label(12, weight: FontWeight.w500, color: AppColors.dangerText),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 10),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _cover() {
    final url = property.coverImageUrl;
    if (url == null || url.isEmpty) return const _CoverFallback();

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) => const _CoverFallback(),
    );
  }

  static String _verificationLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ivory.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppFonts.label(11, weight: FontWeight.w700, color: AppColors.navy),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldSoft, AppColors.blueTint],
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_work_outlined, size: 36, color: AppColors.goldDeep),
      ),
    );
  }
}
