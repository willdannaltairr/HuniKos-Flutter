import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/state_views.dart';
import 'explore_filter_sheet.dart';

/// Halaman pencarian penuh yang dibuka dari bilah cari beranda.
/// Kolom cari mengetik langsung ke katalog yang sama dengan beranda, jadi
/// hasilnya konsisten begitu popup ditutup.
class SearchSheet extends StatefulWidget {
  const SearchSheet({super.key, required this.initialQuery});

  final String initialQuery;

  /// Membuka popup sebagai halaman penuh yang bisa ditutup dengan geseran.
  static Future<void> open(BuildContext context, String query) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SearchSheet(initialQuery: query),
      ),
    );
  }

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  static const _types = [
    (value: null, label: 'Semua'),
    (value: 'putra', label: 'Putra'),
    (value: 'putri', label: 'Putri'),
    (value: 'campur', label: 'Campur'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        context.read<CatalogProvider>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadFacilities();
      if (catalog.query != widget.initialQuery) {
        catalog.search(query: widget.initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<CatalogProvider>().search(query: value);
    });
    setState(() {});
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

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        I18n.t('search.title'),
                        style: AppFonts.title(16, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.tune_rounded,
                    badge: catalog.filter.activeCount,
                    onTap: _openFilter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchField(
                controller: _controller,
                onChanged: _onChanged,
                onClear: () {
                  _controller.clear();
                  context.read<CatalogProvider>().search(query: '');
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final selected = catalog.filter.type == type.value;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (_) => _selectType(type.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _results(catalog)),
          ],
        ),
      ),
    );
  }

  Widget _results(CatalogProvider catalog) {
    if (catalog.loading && catalog.items.isEmpty) {
      return const LoadingView(message: 'Mencari kos…');
    }
    if (catalog.error != null && catalog.items.isEmpty) {
      return ErrorState(message: catalog.error!, onRetry: catalog.search);
    }
    if (catalog.items.isEmpty) {
      return EmptyState(
        title: 'Belum ada kos yang cocok',
        description: 'Coba kata kunci lain atau ubah filter.',
        icon: Icons.search_off,
        action: catalog.filter.isActive
            ? OutlinedButton(
                onPressed: catalog.resetFilter,
                child: const Text('Hapus filter'),
              )
            : null,
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: catalog.items.length + (catalog.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 22),
      itemBuilder: (context, index) {
        if (index >= catalog.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
          onTap: () {
            // Router ditangkap sebelum sheet ditutup: setelah pop, context
            // widget ini sudah tidak dipakai lagi oleh navigator.
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push('/properties/${property.id}');
          },
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.badge = 0});

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paperSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.textPrimary),
              if (badge > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.rose,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: false,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppFonts.label(14, weight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                hintText: I18n.t('search.hint'),
                hintStyle: AppFonts.label(13, color: AppColors.textSecondary),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
