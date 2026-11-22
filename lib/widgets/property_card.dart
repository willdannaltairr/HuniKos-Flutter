import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/property.dart';
import 'price_text.dart';
import 'status_chip.dart';

/// Kartu properti untuk daftar publik, milik pemilik, dan verifikasi admin.
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                InkWell(
                  onTap: onImageTap,
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: _cover(),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Kos ${property.typeLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${property.address}, ${property.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showOwner && property.ownerName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Pemilik: ${property.ownerName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: PriceText(amount: property.minPrice)),
                      Text(
                        '${property.availableRooms}/${property.totalRooms} kamar tersedia',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: property.availableRooms > 0
                              ? AppColors.successText
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (property.rejectionNote != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'Ditolak: ${property.rejectionNote}',
                        style: const TextStyle(fontSize: 12, color: AppColors.dangerText),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(height: 10),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    final url = property.coverImageUrl;
    if (url == null) {
      return Container(
        color: AppColors.blueTint,
        child: const Center(
          child: Icon(Icons.apartment_outlined, size: 36, color: Color(0xFF94A3B8)),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) => Container(
        color: AppColors.blueTint,
        child: const Center(
          child: Icon(Icons.apartment_outlined, size: 36, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  static String _verificationLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu verifikasi';
    }
  }
}
