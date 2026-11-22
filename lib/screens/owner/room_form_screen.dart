import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/property.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';

/// Form tambah dan ubah kamar. Status hanya bisa diubah manual ke
/// AVAILABLE, MAINTENANCE, atau INACTIVE karena RESERVED/OCCUPIED diatur
/// sistem.
class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key, required this.propertyId, this.room});

  final String propertyId;

  /// Null berarti mode tambah.
  final RoomItem? room;

  bool get isEdit => room != null;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _type = TextEditingController(text: 'standard');
  final _dimensions = TextEditingController();
  final _price = TextEditingController();
  final _occupants = TextEditingController(text: '1');
  final _floor = TextEditingController(text: '1');

  String _bathroom = 'dalam';
  String _status = 'AVAILABLE';
  Set<String> _facilityIds = {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    if (room != null) {
      _number.text = room.roomNumber;
      _type.text = room.roomType;
      _dimensions.text = room.dimensions ?? '';
      _price.text = room.monthlyPrice.toInt().toString();
      _occupants.text = room.maxOccupants.toString();
      _floor.text = room.floorNumber.toString();
      _bathroom = room.bathroomType;
      _status = _selectableStatus(room.status);
      _facilityIds = room.facilities.map((facility) => facility.id).toSet();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadFacilities();
    });
  }

  /// Status yang sedang diatur sistem tidak boleh dipilih ulang dari form;
  /// nilai awal tetap ditampilkan agar pemilik tahu kondisi sebenarnya.
  String _selectableStatus(String status) {
    if (status == 'AVAILABLE' || status == 'MAINTENANCE' || status == 'INACTIVE') {
      return status;
    }
    return 'AVAILABLE';
  }

  @override
  void dispose() {
    _number.dispose();
    _type.dispose();
    _dimensions.dispose();
    _price.dispose();
    _occupants.dispose();
    _floor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'room_number': _number.text.trim(),
      'room_type': _type.text.trim().isEmpty ? 'standard' : _type.text.trim(),
      'dimensions': _dimensions.text.trim().isEmpty ? null : _dimensions.text.trim(),
      'monthly_price': num.parse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')),
      'max_occupants': int.parse(_occupants.text.trim()),
      'bathroom_type': _bathroom,
      'floor_number': int.parse(_floor.text.trim()),
      'facility_ids': _facilityIds.toList(),
      // Status hanya dikirim saat mengubah, karena tambah selalu AVAILABLE.
      if (widget.isEdit) 'status': _status,
    };
    body.removeWhere((_, value) => value == null);

    final provider = context.read<OwnerProvider>();
    final error = widget.isEdit
        ? await provider.updateRoom(widget.room!.id, widget.propertyId, body)
        : await provider.createRoom(widget.propertyId, body);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      showSuccess(context, widget.isEdit ? 'Kamar diperbarui' : 'Kamar ditambahkan');
      context.pop();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilities = context.watch<CatalogProvider>().facilities;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Ubah kamar' : 'Tambah kamar')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _number,
                    label: 'Nomor kamar',
                    validator: (value) =>
                        Validators.textLength(value, 'Nomor kamar', min: 1, max: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _type,
                    label: 'Tipe kamar',
                    validator: (value) =>
                        Validators.textLength(value, 'Tipe kamar', min: 1, max: 50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _price,
              label: 'Harga per bulan',
              hint: 'Contoh: 1200000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.price,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _occupants,
                    label: 'Maks. penghuni',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.numberRange(value, 'Maksimal penghuni', min: 1, max: 10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _floor,
                    label: 'Lantai',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.numberRange(value, 'Lantai', min: 1, max: 50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _dimensions,
              label: 'Ukuran (opsional)',
              hint: 'Contoh: 3x4 m',
              validator: (value) =>
                  Validators.optionalTextLength(value, 'Ukuran', max: 20),
            ),
            const SizedBox(height: 16),
            const Text('Kamar mandi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Dalam'),
                  selected: _bathroom == 'dalam',
                  onSelected: (_) => setState(() => _bathroom = 'dalam'),
                ),
                ChoiceChip(
                  label: const Text('Luar'),
                  selected: _bathroom == 'luar',
                  onSelected: (_) => setState(() => _bathroom = 'luar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Fasilitas',
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
            if (widget.isEdit) ...[
              const SizedBox(height: 16),
              const Text('Status kamar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _statusChip('AVAILABLE', 'Tersedia'),
                  _statusChip('MAINTENANCE', 'Perbaikan'),
                  _statusChip('INACTIVE', 'Nonaktif'),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Status Dipesan dan Terisi diatur otomatis oleh sistem.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.dangerText),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.isEdit ? 'Simpan perubahan' : 'Simpan kamar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _status == value,
      onSelected: (_) => setState(() => _status = value),
    );
  }
}
