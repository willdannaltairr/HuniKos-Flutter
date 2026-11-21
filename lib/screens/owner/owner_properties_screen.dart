import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/property_card.dart';
import '../../widgets/state_views.dart';

/// Daftar properti milik pemilik dengan aksi tambah, ubah, dan hapus.
class OwnerPropertiesScreen extends StatefulWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  State<OwnerPropertiesScreen> createState() => _OwnerPropertiesScreenState();
}

class _OwnerPropertiesScreenState extends State<OwnerPropertiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OwnerProvider>();
      if (provider.properties.isEmpty && !provider.loadingProperties) {
        provider.loadProperties();
      }
    });
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus properti?',
      message: 'Properti "$name" akan dihapus permanen beserta kamar dan fotonya.',
      confirmLabel: 'Ya, hapus',
    );
    if (!confirmed || !mounted) return;

    final error = await context.read<OwnerProvider>().deleteProperty(id);
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Properti berhasil dihapus');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properti saya'),
        actions: [
          IconButton(
            onPressed: provider.loadProperties,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/owner/properties/new');
          if (created == true) provider.loadProperties();
        },
        icon: const Icon(Icons.add),
        label: const Text('Properti'),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(OwnerProvider provider) {
    if (provider.loadingProperties && provider.properties.isEmpty) {
      return const LoadingView();
    }
    if (provider.propertiesError != null) {
      return ErrorState(
        message: provider.propertiesError!,
        onRetry: provider.loadProperties,
      );
    }
    if (provider.properties.isEmpty) {
      return const EmptyState(
        title: 'Belum ada properti',
        description: 'Tambahkan kos pertamamu lewat tombol di bawah.',
        icon: Icons.apartment_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadProperties,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: provider.properties.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final property = provider.properties[index];
          return PropertyCard(
            property: property,
            onTap: () => context.push('/owner/properties/${property.id}'),
            trailing: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/owner/properties/${property.id}/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Ubah'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/owner/properties/${property.id}/rooms'),
                  icon: const Icon(Icons.meeting_room_outlined, size: 15),
                  label: const Text('Kamar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _delete(property.id, property.name),
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: AppColors.dangerText,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
