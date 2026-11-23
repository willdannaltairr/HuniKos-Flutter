import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';

/// Form tambah dan ubah properti. Satu layar untuk dua mode karena field
/// dan validasinya sama.
class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  /// Null berarti mode tambah; terisi berarti mode ubah.
  final String? propertyId;

  bool get isEdit => propertyId != null;

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _rules = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  String _type = 'campur';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _prefill();
  }

  void _prefill() {
    final items = context.read<OwnerProvider>().properties;
    for (final property in items) {
      if (property.id != widget.propertyId) continue;
      _name.text = property.name;
      _address.text = property.address;
      _city.text = property.city;
      _type = property.propertyType;
      // Field tambahan wajib diisi ulang: backend menimpa seluruh kolom saat
      // update, jadi nilai yang tidak dikirim akan terhapus.
      _description.text = property.description ?? '';
      _rules.text = property.rules ?? '';
      _latitude.text = property.latitude?.toString() ?? '';
      _longitude.text = property.longitude?.toString() ?? '';
      break;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _description.dispose();
    _rules.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasLatitude = _latitude.text.trim().isNotEmpty;
    final hasLongitude = _longitude.text.trim().isNotEmpty;
    if (hasLatitude != hasLongitude) {
      setState(() => _error = 'Latitude dan longitude harus diisi bersamaan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'property_type': _type,
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'rules': _rules.text.trim().isEmpty ? null : _rules.text.trim(),
      if (hasLatitude) 'latitude': double.parse(_latitude.text.trim()),
      if (hasLongitude) 'longitude': double.parse(_longitude.text.trim()),
    };
    body.removeWhere((_, value) => value == null);

    final provider = context.read<OwnerProvider>();
    final error = widget.isEdit
        ? await provider.updateProperty(widget.propertyId!, body)
        : await provider.createProperty(body);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      showSuccess(
        context,
        widget.isEdit ? 'Properti berhasil diperbarui' : 'Properti dibuat, menunggu verifikasi admin',
      );
      context.pop(true);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Ubah properti' : 'Tambah properti'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _name,
              label: 'Nama properti',
              icon: Icons.apartment_outlined,
              validator: (value) =>
                  Validators.textLength(value, 'Nama properti', min: 3, max: 120),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _address,
              label: 'Alamat lengkap',
              icon: Icons.place_outlined,
              maxLines: 2,
              validator: (value) =>
                  Validators.textLength(value, 'Alamat', min: 5, max: 500),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _city,
              label: 'Kota',
              icon: Icons.location_city_outlined,
              validator: (value) =>
                  Validators.textLength(value, 'Kota', min: 2, max: 80),
            ),
            const SizedBox(height: 16),
            const Text('Tipe kos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _typeChip('putra', 'Putra'),
                _typeChip('putri', 'Putri'),
                _typeChip('campur', 'Campur'),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _description,
              label: 'Deskripsi',
              maxLines: 4,
              maxLength: 2000,
              validator: (value) =>
                  Validators.optionalTextLength(value, 'Deskripsi', max: 2000),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _rules,
              label: 'Aturan kos',
              hint: 'Contoh: tamu lawan jenis dilarang masuk',
              maxLines: 3,
              maxLength: 2000,
              validator: (value) =>
                  Validators.optionalTextLength(value, 'Aturan', max: 2000),
            ),
            const SizedBox(height: 16),
            const Text('Lokasi peta (opsional, isi keduanya atau kosongkan)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _latitude,
                    label: 'Latitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) =>
                        Validators.coordinate(value, 'Latitude', isLatitude: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _longitude,
                    label: 'Longitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) =>
                        Validators.coordinate(value, 'Longitude', isLatitude: false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C)),
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
                        color: AppColors.navy,
                      ),
                    )
                  : Text(widget.isEdit ? 'Simpan perubahan' : 'Simpan properti'),
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: 8),
              const Text(
                'Properti yang sebelumnya ditolak akan kembali menunggu verifikasi setelah diubah.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _type == value,
      onSelected: (_) => setState(() => _type = value),
    );
  }
}
