import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/catalog_provider.dart';

/// Bottom sheet filter: kota, rentang harga, fasilitas, ketersediaan,
/// dan urutan. Nilai baru baru diterapkan saat tombol Terapkan ditekan.
class ExploreFilterSheet extends StatefulWidget {
  const ExploreFilterSheet({super.key, required this.current});

  final PropertyFilter current;

  @override
  State<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<ExploreFilterSheet> {
  late final TextEditingController _city;
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;
  late Set<String> _facilityIds;
  late bool _availableOnly;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.current.city ?? '');
    _minPrice = TextEditingController(
      text: widget.current.minPrice == null ? '' : widget.current.minPrice!.toInt().toString(),
    );
    _maxPrice = TextEditingController(
      text: widget.current.maxPrice == null ? '' : widget.current.maxPrice!.toInt().toString(),
    );
    _facilityIds = widget.current.facilityIds.toSet();
    _availableOnly = widget.current.availableOnly;
    _sort = widget.current.sort;
  }

  @override
  void dispose() {
    _city.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minPrice.text.trim());
    final max = double.tryParse(_maxPrice.text.trim());

    // Rentang terbalik akan mengembalikan nol hasil, jadi dibalik saja.
    final resolvedMin = min != null && max != null && min > max ? max : min;
    final resolvedMax = min != null && max != null && min > max ? min : max;

    Navigator.of(context).pop(
      PropertyFilter(
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        type: widget.current.type,
        minPrice: resolvedMin,
        maxPrice: resolvedMax,
        facilityIds: _facilityIds.toList(),
        availableOnly: _availableOnly,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilities = context.watch<CatalogProvider>().facilities;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter pencarian',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _city.clear();
                    _minPrice.clear();
                    _maxPrice.clear();
                    setState(() {
                      _facilityIds = {};
                      _availableOnly = false;
                      _sort = 'newest';
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'Kota',
                prefixIcon: Icon(Icons.location_city_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Rentang harga per bulan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Terendah'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('–'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tertinggi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Fasilitas kamar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (facilities.isEmpty)
              const Text(
                'Daftar fasilitas belum termuat.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: facilities.map((facility) {
                  final selected = _facilityIds.contains(facility.id);
                  return FilterChip(
                    label: Text(facility.name),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _facilityIds.add(facility.id);
                        } else {
                          _facilityIds.remove(facility.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _availableOnly,
              onChanged: (value) => setState(() => _availableOnly = value),
              title: const Text('Hanya yang ada kamar tersedia',
                  style: TextStyle(fontSize: 13.5)),
            ),
            const SizedBox(height: 6),
            const Text('Urutkan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _sortChip('newest', 'Terbaru'),
                _sortChip('price_asc', 'Harga terendah'),
                _sortChip('price_desc', 'Harga tertinggi'),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _apply, child: const Text('Terapkan filter')),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Harga mulai ${Formatters.rupiah(500000)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _sort == value,
      onSelected: (_) => setState(() => _sort = value),
    );
  }
}
