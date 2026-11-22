import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/state_views.dart';
import 'explore_filter_sheet.dart';

/// Beranda pencarian kos untuk penyewa, dipakai di dalam shell.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  static const _quickTypes = [
    (value: null, label: 'Semua', icon: Icons.auto_awesome_outlined),
    (value: 'putra', label: 'Putra', icon: Icons.male_rounded),
    (value: 'putri', label: 'Putri', icon: Icons.female_rounded),
    (value: 'campur', label: 'Campur', icon: Icons.people_alt_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadFacilities();
      if (catalog.items.isEmpty) catalog.search();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context.read<CatalogProvider>().loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<CatalogProvider>().search(query: value);
    });
  }

  Future<void> _openFilter() async {
    final catalog = context.read<CatalogProvider>();
    final result = await showModalBottomSheet<PropertyFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: catalog,
        child: ExploreFilterSheet(current: catalog.filter),
      ),
    );
    if (result != null) catalog.applyFilter(result);
  }

  void _selectType(String? type) {
    final catalog = context.read<CatalogProvider>();
    catalog.applyFilter(
      type == null
          ? catalog.filter.copyWith(clearType: true)
          : catalog.filter.copyWith(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.fullName.split(' ').first ?? 'Pencari kos';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $firstName', style: AppFonts.title(26)),
                  const SizedBox(height: 2),
                  Text(
                    'Mau tinggal di mana bulan ini?',
                    style: AppFonts.label(13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  _SearchPill(
                    controller: _searchController,
                    onChanged: _onQueryChanged,
                    onSubmitted: (value) =>
                        context.read<CatalogProvider>().search(query: value),
                    onClear: () {
                      _searchController.clear();
                      setState(() {});
                      context.read<CatalogProvider>().search(query: '');
                    },
                    onFilter: _openFilter,
                    filterCount: catalog.filter.activeCount,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickTypes.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = _quickTypes[index];
                        return _TypeChip(
                          label: item.label,
                          icon: item.icon,
                          selected: catalog.filter.type == item.value,
                          onTap: () => _selectType(item.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(catalog)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CatalogProvider catalog) {
    if (catalog.loading && catalog.items.isEmpty) {
      return const LoadingView(message: 'Mencari kos terdekat untukmu…');
    }
    if (catalog.error != null && catalog.items.isEmpty) {
      return ErrorState(message: catalog.error!, onRetry: () => catalog.search());
    }
    if (catalog.items.isEmpty) {
      return EmptyState(
        title: 'Belum ada kos yang cocok',
        description: 'Coba ubah kata kunci atau hapus beberapa filter.',
        icon: Icons.search_off,
        action: catalog.filter.isActive
            ? OutlinedButton(
                onPressed: catalog.resetFilter,
                child: const Text('Hapus filter'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: catalog.refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: catalog.items.length + (catalog.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          if (index >= catalog.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: catalog.loadingMore
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : OutlinedButton(
                        onPressed: catalog.loadMore,
                        child: const Text('Muat lebih banyak'),
                      ),
              ),
            );
          }

          final property = catalog.items[index];
          return PropertyCard(
            property: property,
            onTap: () => context.push('/properties/${property.id}'),
          );
        },
      ),
    );
  }
}

/// Kolom pencarian berbentuk pil dengan bayangan tipis, seperti bilah cari
/// pada aplikasi perjalanan.
class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
    required this.filterCount,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilter;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F14213D), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, size: 21, color: AppColors.navy),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppFonts.label(14, weight: FontWeight.w500),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                hintText: 'Cari kos, alamat, atau kota',
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textSecondary,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterButton(count: filterCount, onTap: onFilter),
          ),
        ],
      ),
    );
  }
}

/// Tombol filter bulat dengan penanda jumlah filter aktif.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.navy,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.tune_rounded, size: 20, color: AppColors.ivory),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppFonts.label(10, weight: FontWeight.w800, color: AppColors.navy),
              ),
            ),
          ),
      ],
    );
  }
}

/// Chip kategori dengan ikon; versi terpilih berwarna navy penuh.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.ivory : AppColors.navy;

    return Material(
      color: selected ? AppColors.navy : AppColors.ivory,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.gold : AppColors.navy),
              const SizedBox(width: 6),
              Text(label, style: AppFonts.label(12.5, weight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
