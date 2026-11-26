import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/maintenance.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Daftar laporan kerusakan milik penyewa.
class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TenantProvider>();
      if (provider.maintenance.isEmpty && !provider.loadingMaintenance) {
        provider.loadMaintenance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenantProvider>();

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Laporan kerusakan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/maintenance/new'),
        icon: const Icon(Icons.add),
        label: const Text('Lapor'),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(TenantProvider provider) {
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
        title: 'Belum ada laporan',
        description: 'Laporan bisa dibuat setelah booking kamu dikonfirmasi pemilik.',
        icon: Icons.build_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadMaintenance,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: provider.maintenance.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = provider.maintenance[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.photoUrl != null) ...[
                    NetworkImageView(url: item.photoUrl, width: 56, height: 56),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
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
                          '${item.propertyName} • Kamar ${item.roomNumber}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.dateTime(item.createdAt?.toIso8601String()),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (item.ownerNote != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Catatan pemilik: ${item.ownerNote}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
