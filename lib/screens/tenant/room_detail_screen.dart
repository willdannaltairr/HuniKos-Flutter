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

/// Detail kamar: foto, fasilitas, periode yang sudah dipesan, dan tombol
/// pesan. Pemilik dan admin hanya melihat tanpa tombol pesan.
class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<RoomDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RoomDetail> _load() {
    return context.read<CatalogProvider>().roomDetail(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail kamar')),
      body: FutureBuilder<RoomDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorState(
              message: error is ApiException ? error.message : 'Gagal memuat kamar',
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final detail = snapshot.data!;
          final room = detail.room;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (detail.images.isEmpty)
                      const NetworkImageView(url: null, height: 200, borderRadius: 0)
                    else
                      SizedBox(
                        height: 210,
                        child: PageView.builder(
                          itemCount: detail.images.length,
                          itemBuilder: (context, index) => NetworkImageView(
                            url: detail.images[index].imageUrl,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kamar ${room.roomNumber}',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${detail.property.name} • ${detail.property.city}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          PriceText(
                            amount: room.monthlyPrice,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoGrid(room: room),
                          const SizedBox(height: 18),
                          const Text(
                            'Fasilitas',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (room.facilities.isEmpty)
                            const Text(
                              'Belum ada fasilitas yang dicatat.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: room.facilities
                                  .map(
                                    (facility) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        facility.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 18),
                          const Text(
                            'Sudah dipesan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          if (detail.unavailableRanges.isEmpty)
                            const Text(
                              'Belum ada periode yang dipesan.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            )
                          else
                            ...detail.unavailableRanges.map(
                              (range) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_busy,
                                        size: 15, color: AppColors.dangerText),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sudah dipesan: ${Formatters.shortDate(range.startDate)} – ${Formatters.shortDate(range.endDate)}',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (auth.user == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      // Tamu diarahkan login lalu kembali ke form booking.
                      onPressed: () {
                        final target = Uri.encodeComponent('/rooms/${room.id}/book');
                        context.push('/login?redirect=$target');
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Masuk untuk memesan'),
                    ),
                  ),
                )
              else if (auth.user!.isTenant)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!room.isBookable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kamar ini belum bisa dipesan saat ini.'),
                            ),
                          );
                          return;
                        }
                        context.push('/rooms/${room.id}/book');
                      },
                      icon: const Icon(Icons.event_available_outlined),
                      label: const Text('Pesan kamar'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: items
            .map(
              (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    item.$2,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
