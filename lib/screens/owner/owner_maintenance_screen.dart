import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/maintenance.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Laporan kerusakan dari penyewa. Status bergerak maju:
/// OPEN → IN_PROGRESS → DONE.
class OwnerMaintenanceScreen extends StatefulWidget {
  const OwnerMaintenanceScreen({super.key});

  @override
  State<OwnerMaintenanceScreen> createState() => _OwnerMaintenanceScreenState();
}

class _OwnerMaintenanceScreenState extends State<OwnerMaintenanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().loadMaintenance();
    });
  }

  Future<void> _advance(Maintenance item) async {
    final next = MaintenanceStatus.next(item.status);
    if (next == null) return;

    final decision = await showDecisionDialog(
      context,
      title: 'Ubah ke ${MaintenanceStatus.label(next)}?',
      message: 'Tambahkan catatan untuk penyewa bila perlu.',
      confirmLabel: 'Simpan',
    );
    if (!decision.confirmed || !mounted) return;

    final error = await context.read<OwnerProvider>().updateMaintenance(
          id: item.id,
          status: next,
          note: decision.note,
        );
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Status laporan diperbarui');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan kerusakan')),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(OwnerProvider provider) {
    if (provider.loadingMaintenance && provider.maintenance.isEmpty) {
      return const LoadingView();
    }
    if (provider.maintenanceError != null) {
      return ErrorState(
        message: provider.maintenanceError!,
        onRetry: provider.loadMaintenance,
      );
    }
    if (provider.maintenance.isEmpty) {
      return const EmptyState(
        title: 'Tidak ada laporan',
        description: 'Laporan kerusakan dari penyewa akan tampil di sini.',
        icon: Icons.build_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadMaintenance,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.maintenance.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = provider.maintenance[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusChip(
                        compact: true,
                        status: item.status,
                        label: MaintenanceStatus.label(item.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.tenantName} • ${item.propertyName} • Kamar ${item.roomNumber}',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.photoUrl != null) ...[
                        NetworkImageView(url: item.photoUrl, width: 64, height: 64),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          item.description,
                          style: const TextStyle(fontSize: 12.5, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.dateTime(item.createdAt?.toIso8601String()),
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (item.ownerNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Catatanmu: ${item.ownerNote}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.primary),
                    ),
                  ],
                  if (MaintenanceStatus.next(item.status) != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _advance(item),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        'Tandai ${MaintenanceStatus.label(MaintenanceStatus.next(item.status)!)}',
                      ),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
