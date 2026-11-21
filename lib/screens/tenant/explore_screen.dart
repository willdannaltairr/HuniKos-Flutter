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

/// Beranda pencarian kos. Dipakai tamu (dengan AppBar sendiri) dan penyewa
/// (di dalam shell).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  static const _quickTypes = [
    (value: null, label: 'Semua'),
    (value: 'putra', label: 'Putra'),
    (value: 'putri', label: 'Putri'),
    (value: 'campur', label: 'Campur'),
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
      showDragHandle: false,
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

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('HuniKos'),
              actions: [
                TextButton(
                  onPressed: () => context.go(
                    auth.isLoggedIn ? '/tenant' : '/login',
                  ),
                  child: Text(auth.isLoggedIn ? 'Akun saya' : 'Masuk'),
                ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, widget.embedded ? 12 : 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.embedded) ...[
                  Text(
                    'Halo, ${auth.user?.fullName.split(' ').first ?? 'Pencari kos'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text(
                    'Temukan kos yang pas untuk kamu.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onQueryChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) =>
                            context.read<CatalogProvider>().search(query: value),
                        decoration: InputDecoration(
                          hintText: 'Cari nama kos, alamat, atau kota',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                    context.read<CatalogProvider>().search(query: '');
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterButton(
                      count: catalog.filter.activeCount,
                      onTap: _openFilter,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _quickTypes.map((item) {
                      final selected = catalog.filter.type == item.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item.label),
                          selected: selected,
                          onSelected: (_) => _selectType(item.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(catalog, auth)),
        ],
      ),
    );
  }

  Widget _buildBody(CatalogProvider catalog, AuthProvider auth) {
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: catalog.items.length + (catalog.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(52, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.tune, size: 22),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
