import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Gambar dari server. URL sudah lengkap dari backend, jadi tidak digabung
/// lagi dengan baseUrl.
class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: AppColors.surfaceHigh,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, _, _) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(Icons.apartment_outlined, color: AppColors.textSecondary, size: 28),
      ),
    );
  }
}
