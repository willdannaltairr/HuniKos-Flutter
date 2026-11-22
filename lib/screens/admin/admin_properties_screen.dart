import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/property_card.dart';
import '../../widgets/state_views.dart';

/// Verifikasi properti: tab pending, approved, dan rejected. Penolakan
/// wajib beralasan.
class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  static const _tabs = [
    (value: 'pending', label: 'Menunggu'),
    (value: 'approved', label: 'Disetujui'),
    (value: 'rejected', label: 'Ditolak'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadProperties();
    });
  }

  Future<void> _verify(String propertyId, bool approve) async {
    final decision = await showDecisionDialog(
      context,
      title: approve ? 'Setujui properti?' : 'Tolak properti?',
      message: approve
          ? 'Properti akan tampil di pencarian publik.'
          : 'Jelaskan apa yang perlu diperbaiki agar pemilik bisa memperbaiki.',
      confirmLabel: approve ? 'Setujui' : 'Tolak',
      requireNote: !approve,
      destructive: !approve,
    );
    if (!decision.confirmed || !mounted) return;

    final error = await context.read<AdminProvider>().verifyProperty(
          propertyId: propertyId,
          action: approve ? 'approve' : 'reject',
          note: decision.note,
        );
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, approve ? 'Properti disetujui' : 'Properti ditolak');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi properti')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _tabs.map((tab) {
                final selected = provider.verificationFilter == tab.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab.label),
                    selected: selected,
                    onSelected: (_) => provider.loadProperties(status: tab.value),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(AdminProvider provider) {
    if (provider.loadingProperties && provider.properties.isEmpty) {
      return const LoadingView();
    }
    if (provider.propertiesError != null) {
      return ErrorState(
        message: provider.propertiesError!,
        onRetry: () => provider.loadProperties(),
      );
    }
    if (provider.properties.isEmpty) {
      return EmptyState(
        title: 'Tidak ada properti',
        description: provider.verificationFilter == 'pending'
            ? 'Semua pengajuan sudah diproses.'
            : 'Belum ada properti pada status ini.',
        icon: Icons.apartment_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadProperties(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: provider.properties.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final property = provider.properties[index];
          return PropertyCard(
            property: property,
            showOwner: true,
            onTap: () => context.push('/admin/properties/${property.id}'),
            onImageTap: () => context.push('/admin/properties/${property.id}'),
            trailing: provider.verificationFilter == 'pending'
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _verify(property.id, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            foregroundColor: const Color(0xFFB91C1C),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _verify(property.id, true),
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                          child: const Text('Setujui'),
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
