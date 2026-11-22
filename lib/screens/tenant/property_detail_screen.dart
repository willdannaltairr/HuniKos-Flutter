import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/property_map.dart';
import '../../widgets/room_card.dart';
import '../../widgets/state_views.dart';

/// Detail properti: galeri, deskripsi, aturan, peta lokasi, info pemilik,
/// dan daftar kamar. Hanya untuk pengguna yang sudah login.
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
      body: FutureBuilder<PropertyDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SafeArea(child: LoadingView());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return SafeArea(
              child: ErrorState(
                message: error is ApiException ? error.message : 'Gagal memuat properti',
                onRetry: _reload,
              ),
            );
          }

          final property = snapshot.data!;
          final hasLocation = property.latitude != null && property.longitude != null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                backgroundColor: AppColors.cream,
                surfaceTintColor: Colors.transparent,
                leading: const _CircleBackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  background: _Gallery(
                    images: property.images,
                    controller: _pageController,
                    page: _page,
                    onPageChanged: (value) => setState(() => _page = value),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeBadge(label: 'Kos ${property.typeLabel}'),
                          if (property.verificationStatus != 'approved') ...[
                            const SizedBox(width: 8),
                            Text(
                              'Belum terverifikasi',
                              style: AppFonts.label(
                                11.5,
                                weight: FontWeight.w600,
                                color: AppColors.warningText,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(property.name, style: AppFonts.title(27)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: AppColors.goldDeep),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${property.address}, ${property.city}',
                              style: AppFonts.label(
                                13,
                                weight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (property.rejectionNote != null) ...[
                        const SizedBox(height: 12),
                        _NoteBox(
                          text: 'Ditolak admin: ${property.rejectionNote}',
                        ),
                      ],
                      const SizedBox(height: 20),
                      const _Divider(),
                      _Section(
                        title: 'Tentang kos ini',
                        child: Text(
                          property.description ?? 'Pemilik belum menuliskan deskripsi.',
                          style: AppFonts.label(14, weight: FontWeight.w500).copyWith(height: 1.65),
                        ),
                      ),
                      if (property.rules != null && property.rules!.isNotEmpty)
                        _Section(
                          title: 'Aturan kos',
                          child: Text(
                            property.rules!,
                            style: AppFonts.label(14, weight: FontWeight.w500).copyWith(height: 1.65),
                          ),
                        ),
                      if (hasLocation)
                        _Section(
                          title: 'Lokasi',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PropertyMap(
                                latitude: property.latitude!,
                                longitude: property.longitude!,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                property.city,
                                style: AppFonts.label(
                                  12.5,
                                  weight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _Section(
                        title: 'Pemilik',
                        child: _OwnerRow(owner: property.owner),
                      ),
                      const _Divider(),
                      const SizedBox(height: 18),
                      Text(
                        'Pilihan kamar',
                        style: AppFonts.title(20, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${property.rooms.length} kamar terdaftar',
                        style: AppFonts.label(
                          12.5,
                          weight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (property.rooms.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: EmptyState(
                      title: 'Belum ada kamar',
                      description: 'Pemilik belum menambahkan kamar untuk kos ini.',
                      icon: Icons.meeting_room_outlined,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: property.rooms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final room = property.rooms[index];
                      return RoomCard(
                        room: room,
                        onTap: () => context.push('/rooms/${room.id}'),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: AppColors.ivory.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/tenant'),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          color: AppColors.navy,
          tooltip: 'Kembali',
        ),
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
      return const NetworkImageView(url: null, borderRadius: 0);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          itemCount: images.length,
          itemBuilder: (context, index) => NetworkImageView(
            url: images[index].imageUrl,
            borderRadius: 0,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${page + 1}/${images.length}',
              style: AppFonts.label(11, weight: FontWeight.w600, color: AppColors.ivory),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppFonts.label(11, weight: FontWeight.w700, color: AppColors.goldDeep),
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.owner});

  final PropertyOwner owner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.navy,
          child: Text(
            owner.fullName.substring(0, 1).toUpperCase(),
            style: AppFonts.label(16, weight: FontWeight.w700, color: AppColors.ivory),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(owner.fullName, style: AppFonts.label(14, weight: FontWeight.w700)),
              if (owner.phoneNumber != null)
                Text(
                  owner.phoneNumber!,
                  style: AppFonts.label(
                    12.5,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppFonts.label(12.5, weight: FontWeight.w500, color: AppColors.dangerText),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, height: 1);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.title(19, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
