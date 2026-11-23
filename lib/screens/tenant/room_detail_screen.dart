import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../models/room_detail.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/price_text.dart';
import '../../widgets/state_views.dart';

/// Detail kamar: foto, fasilitas, periode yang sudah dipesan, dan bilah
/// pemesanan di bawah. Pemilik dan admin melihat tanpa tombol pesan.
class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<RoomDetail> _future;
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

  Future<RoomDetail> _load() {
    return context.read<CatalogProvider>().roomDetail(widget.roomId);
  }

  void _reload() => setState(() => _future = _load());

  void _book(RoomItem room) {
    if (!room.isBookable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamar ini belum bisa dipesan saat ini.')),
      );
      return;
    }
    context.push('/rooms/${room.id}/book');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: FutureBuilder<RoomDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SafeArea(child: LoadingView());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return SafeArea(
              child: ErrorState(
                message: error is ApiException ? error.message : 'Gagal memuat kamar',
                onRetry: _reload,
              ),
            );
          }

          final detail = snapshot.data!;
          final room = detail.room;
          final isTenant = auth.user?.isTenant ?? false;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 260,
                      backgroundColor: AppColors.cream,
                      surfaceTintColor: Colors.transparent,
                      leading: const _CircleBackButton(),
                      flexibleSpace: FlexibleSpaceBar(
                        background: _Gallery(
                          images: detail.images,
                          controller: _pageController,
                          page: _page,
                          onPageChanged: (value) => setState(() => _page = value),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kamar ${room.roomNumber}', style: AppFonts.title(26)),
                            const SizedBox(height: 4),
                            Text(
                              '${detail.property.name} · ${detail.property.city}',
                              style: AppFonts.label(
                                13,
                                weight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PriceText(
                              amount: room.monthlyPrice,
                              style: AppFonts.label(20, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 18),
                            _InfoGrid(room: room),
                            const SizedBox(height: 22),
                            Text('Fasilitas', style: AppFonts.title(19, weight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            if (room.facilities.isEmpty)
                              Text(
                                'Belum ada fasilitas yang dicatat.',
                                style: AppFonts.label(
                                  13,
                                  weight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: room.facilities
                                    .map((facility) => _FacilityChip(name: facility.name))
                                    .toList(),
                              ),
                            const SizedBox(height: 22),
                            Text(
                              'Periode terisi',
                              style: AppFonts.title(19, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            if (detail.unavailableRanges.isEmpty)
                              Text(
                                'Belum ada periode yang dipesan.',
                                style: AppFonts.label(
                                  13,
                                  weight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            else
                              ...detail.unavailableRanges.map(
                                (range) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.event_busy_outlined,
                                        size: 16,
                                        color: AppColors.goldDeep,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          'Terisi ${Formatters.shortDate(range.startDate)} – '
                                          '${Formatters.shortDate(range.endDate)}',
                                          style: AppFonts.label(13, weight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isTenant) _BookingBar(room: room, onBook: () => _book(room)),
            ],
          );
        },
      ),
    );
  }
}

/// Bilah bawah bergaya Airbnb: harga di kiri, tombol di kanan.
class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.room, required this.onBook});

  final RoomItem room;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PriceText(
                      amount: room.monthlyPrice,
                      style: AppFonts.label(17, weight: FontWeight.w800),
                    ),
                    Text(
                      room.isAvailable ? 'Siap dihuni' : 'Belum tersedia',
                      style: AppFonts.label(
                        11.5,
                        weight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(148, 50),
                  backgroundColor: AppColors.navy,
                ),
                child: const Text('Pesan sekarang'),
              ),
            ],
          ),
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

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: AppColors.goldDeep),
          const SizedBox(width: 5),
          Text(name, style: AppFonts.label(12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Ringkasan atribut kamar dalam kotak krem dengan garis tepi tipis.
class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.room});

  final RoomItem room;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Tipe', room.roomType),
      ('Lantai', '${room.floorNumber}'),
      ('Kapasitas', '${room.maxOccupants} orang'),
      ('Kamar mandi', room.bathroomLabel),
      if (room.dimensions != null) ('Ukuran', room.dimensions!),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 14,
        children: items
            .map(
              (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: AppFonts.label(
                      11,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(item.$2, style: AppFonts.label(13.5, weight: FontWeight.w700)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
