import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/facility.dart';
import '../../models/property.dart';
import '../../models/room_detail.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/price_text.dart';
import '../../widgets/state_views.dart';

/// Detail kamar bergaya aplikasi perjalanan: foto besar di atas, lalu judul,
/// info singkat, fasilitas, dan periode terisi. Bilah pesan menempel di bawah.
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
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Gallery(
                      images: detail.images,
                      controller: _pageController,
                      page: _page,
                      onPageChanged: (value) => setState(() => _page = value),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kamar ${room.roomNumber} · ${room.roomType}',
                            style: AppFonts.title(23, weight: FontWeight.w700)
                                .copyWith(height: 1.25),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${detail.property.name} · ${detail.property.city}',
                            style: AppFonts.label(
                              13,
                              weight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusRow(room: room),
                          const SizedBox(height: 16),
                          Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 16),
                          _HostRow(room: room),
                          const SizedBox(height: 18),
                          _Amenities(facilities: room.facilities),
                          const SizedBox(height: 18),
                          _Highlight(
                            icon: Icons.check_circle_outline,
                            title: room.isAvailable ? 'Siap dihuni' : 'Sedang tidak tersedia',
                            subtitle: room.isAvailable
                                ? 'Kamar bisa dipesan hari ini.'
                                : 'Tunggu sampai kamar kembali tersedia.',
                          ),
                          const SizedBox(height: 12),
                          _Highlight(
                            icon: Icons.calendar_month_outlined,
                            title: 'Periode terisi',
                            subtitle: detail.unavailableRanges.isEmpty
                                ? 'Belum ada periode yang dipesan.'
                                : detail.unavailableRanges
                                    .map((range) =>
                                        '${Formatters.shortDate(range.startDate)} – '
                                        '${Formatters.shortDate(range.endDate)}')
                                    .join(', '),
                          ),
                          const SizedBox(height: 24),
                        ],
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

/// Bilah bawah: harga di kiri, tombol pesan di kanan.
class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.room, required this.onBook});

  final RoomItem room;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
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
                style: FilledButton.styleFrom(minimumSize: const Size(140, 50)),
                child: const Text('Pesan sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Galeri foto dengan tombol tutup, bagikan, dan penanda halaman.
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
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              child: images.isEmpty
                  ? const NetworkImageView(url: null, borderRadius: 0)
                  : PageView.builder(
                      controller: controller,
                      onPageChanged: onPageChanged,
                      itemCount: images.length,
                      itemBuilder: (context, index) => NetworkImageView(
                        url: images[index].imageUrl,
                        borderRadius: 0,
                      ),
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Tutup',
                    onTap: () => context.canPop() ? context.pop() : context.go('/tenant'),
                  ),
                  _GlassButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Bagikan',
                    onTap: () => _share(context),
                  ),
                ],
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${page + 1}/${images.length}',
                  style: AppFonts.label(11, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tombol ini mengikuti rujukan visual, tetapi belum ada layanan bagikan
  /// yang dipasang, jadi beri tahu terus terang daripada mengaku berhasil.
  void _share(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur bagikan belum tersedia')),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Baris status kamar dan jumlah penghuni.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.room});

  final RoomItem room;

  static String _statusLabel(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Tersedia';
      case 'RESERVED':
        return 'Dipesan';
      case 'OCCUPIED':
        return 'Terisi';
      case 'MAINTENANCE':
        return 'Perbaikan';
      case 'INACTIVE':
        return 'Nonaktif';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          room.isAvailable ? Icons.bolt_rounded : Icons.lock_clock_outlined,
          size: 17,
          color: room.isAvailable ? AppColors.successText : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          _statusLabel(room.status),
          style: AppFonts.label(
            12.5,
            weight: FontWeight.w600,
            color: room.isAvailable ? AppColors.successText : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '${room.maxOccupants} orang',
          style: AppFonts.label(12.5, weight: FontWeight.w500, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Tempat tinggal: tipe, lantai, ukuran.
class _HostRow extends StatelessWidget {
  const _HostRow({required this.room});

  final RoomItem room;

  @override
  Widget build(BuildContext context) {
    final parts = [
      room.bathroomLabel,
      'Lantai ${room.floorNumber}',
      if (room.dimensions != null) room.dimensions!,
    ];

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.paperSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.meeting_room_outlined, color: AppColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kamar ${room.roomNumber}', style: AppFonts.label(14, weight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(
                parts.join(' · '),
                style: AppFonts.label(12.5, weight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Daftar fasilitas dalam dua kolom seperti bagian "Amenities".
class _Amenities extends StatelessWidget {
  const _Amenities({required this.facilities});

  final List<Facility> facilities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fasilitas', style: AppFonts.title(18, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (facilities.isEmpty)
          Text(
            'Belum ada fasilitas yang dicatat.',
            style: AppFonts.label(13, weight: FontWeight.w500, color: AppColors.textSecondary),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final facility in facilities)
                    SizedBox(
                      width: columnWidth,
                      child: Row(
                        children: [
                          Icon(Icons.check_rounded, size: 16, color: AppColors.ink),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              facility.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.label(13, weight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Blok sorotan dengan ikon, judul, dan keterangan kecil.
class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppFonts.label(13.5, weight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: AppFonts.label(12.5, weight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
