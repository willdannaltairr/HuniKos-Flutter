import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/room_card.dart';
import '../../widgets/state_views.dart';

/// Detail properti: galeri, deskripsi, aturan, info pemilik, dan daftar kamar.
/// Halaman ini boleh dibuka tamu, tapi tombol pesan hanya muncul untuk tenant.
class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Future<PropertyDetail> _future;
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<PropertyDetail> _load() {
    return context.read<CatalogProvider>().propertyDetail(widget.propertyId);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail kos')),
      body: FutureBuilder<PropertyDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorState(
              message: error is ApiException ? error.message : 'Gagal memuat properti',
              onRetry: _reload,
            );
          }

          final property = snapshot.data!;
          return ListView(
            children: [
              _Gallery(
                images: property.images,
                controller: _pageController,
                page: _page,
                onPageChanged: (value) => setState(() => _page = value),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.blueTint,
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
                        if (property.verificationStatus != 'approved') ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Belum terverifikasi',
                            style: TextStyle(fontSize: 11, color: AppColors.warningText),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.address}, ${property.city}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (property.rejectionNote != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Ditolak admin: ${property.rejectionNote}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Deskripsi',
                      child: Text(
                        property.description ?? 'Pemilik belum menuliskan deskripsi.',
                        style: const TextStyle(fontSize: 13.5, height: 1.6),
                      ),
                    ),
                    if (property.rules != null && property.rules!.isNotEmpty)
                      _Section(
                        title: 'Aturan kos',
                        child: Text(
                          property.rules!,
                          style: const TextStyle(fontSize: 13.5, height: 1.6),
                        ),
                      ),
                    _Section(
                      title: 'Pemilik',
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              property.owner.fullName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.owner.fullName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (property.owner.phoneNumber != null)
                                  Text(
                                    property.owner.phoneNumber!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kamar tersedia (${property.rooms.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (property.rooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    title: 'Belum ada kamar',
                    description: 'Pemilik belum menambahkan kamar untuk kos ini.',
                    icon: Icons.meeting_room_outlined,
                  ),
                )
              else
                ...property.rooms.map(
                  (room) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: RoomCard(
                      room: room,
                      onTap: () => context.push('/rooms/${room.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.controller,
    required this.page,
    required this.onPageChanged,
  });

  final List<PropertyImage> images;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const NetworkImageView(
        url: null,
        height: 210,
        borderRadius: 0,
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) => NetworkImageView(
              url: images[index].imageUrl,
              borderRadius: 0,
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${page + 1}/${images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
