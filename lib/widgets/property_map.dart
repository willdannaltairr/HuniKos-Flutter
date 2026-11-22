import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';

/// Peta lokasi kos. Memakai ubin OpenStreetMap supaya tidak perlu API key.
class PropertyMap extends StatelessWidget {
  const PropertyMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 190,
    this.interactive = false,
  });

  final double latitude;
  final double longitude;
  final double height;

  /// Bila false, peta hanya bisa dilihat agar tidak merebut gestur scroll.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: InteractionOptions(
                  flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hunikos.hunikos',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 46,
                      height: 46,
                      child: const _MapPin(),
                    ),
                  ],
                ),
              ],
            ),
            // Atribusi wajib saat memakai ubin OpenStreetMap.
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ivory.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '© OpenStreetMap',
                  style: AppFonts.label(
                    9,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pin lokasi: lingkaran navy dengan cincin emas.
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: AppColors.ivory, size: 20),
    );
  }
}
