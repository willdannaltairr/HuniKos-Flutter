import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Pratinjau properti untuk admin sebelum memutuskan verifikasi.
class AdminPropertyDetailScreen extends StatefulWidget {
  const AdminPropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<AdminPropertyDetailScreen> createState() =>
      _AdminPropertyDetailScreenState();
}

class _AdminPropertyDetailScreenState extends State<AdminPropertyDetailScreen> {
  late Future<PropertyDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CatalogProvider>().propertyDetail(widget.propertyId);
  }

  Future<void> _decide(bool approve) async {
    final decision = await showDecisionDialog(
      context,
      title: approve ? 'Setujui properti?' : 'Tolak properti?',
      message: approve
          ? 'Properti akan tampil di pencarian publik.'
          : 'Tuliskan alasan penolakan agar pemilik bisa memperbaiki.',
      confirmLabel: approve ? 'Setujui' : 'Tolak',
      requireNote: !approve,
      destructive: !approve,
    );
    if (!decision.confirmed || !mounted) return;

    final error = await context.read<AdminProvider>().verifyProperty(
          propertyId: widget.propertyId,
          action: approve ? 'approve' : 'reject',
          note: decision.note,
        );
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, approve ? 'Properti disetujui' : 'Properti ditolak');
      Navigator.of(context).pop();
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tinjau properti')),
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
              onRetry: () => setState(() {
                _future =
                    context.read<CatalogProvider>().propertyDetail(widget.propertyId);
              }),
            );
          }

          final property = snapshot.data!;
          final canDecide = property.verificationStatus != 'approved';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusChip(
                          status: property.verificationStatus,
                          label: _label(property.verificationStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.address}, ${property.city} • Kos ${property.typeLabel}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pemilik: ${property.owner.fullName}'
                      '${property.owner.phoneNumber == null ? '' : ' • ${property.owner.phoneNumber}'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (property.rejectionNote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Catatan penolakan sebelumnya: ${property.rejectionNote}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.dangerText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.description ?? 'Pemilik belum menuliskan deskripsi.',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    if (property.rules != null) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Aturan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.rules!,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Foto (${property.images.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (property.images.isEmpty)
                      const Text(
                        'Belum ada foto.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: property.images.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemBuilder: (context, index) => NetworkImageView(
                          url: property.images[index].imageUrl,
                          borderRadius: 8,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Kamar (${property.rooms.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (property.rooms.isEmpty)
                      const Text(
                        'Belum ada kamar.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      )
                    else
                      ...property.rooms.map(
                        (room) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Kamar ${room.roomNumber} • ${room.status} • '
                            '${room.bathroomLabel} • ${room.maxOccupants} orang',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (canDecide)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _decide(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dangerText,
                              side: const BorderSide(color: Color(0xFFFECACA)),
                            ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _decide(true),
                            child: const Text('Setujui'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _label(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }
}
