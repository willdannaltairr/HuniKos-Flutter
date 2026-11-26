import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/property.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import 'room_photo_field.dart';

/// Form tambah dan ubah kamar. Status hanya bisa diubah manual ke
/// AVAILABLE, MAINTENANCE, atau INACTIVE karena RESERVED/OCCUPIED diatur
/// sistem. Setiap kamar wajib punya minimal satu foto.
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
  final _photoKey = GlobalKey<RoomPhotoFieldState>();
  final _number = TextEditingController();
  final _type = TextEditingController(text: 'standard');
  final _dimensions = TextEditingController();
  final _price = TextEditingController();
  final _occupants = TextEditingController(text: '1');
  final _floor = TextEditingController(text: '1');

  String _bathroom = 'dalam';
  String _status = 'AVAILABLE';
  Set<String> _facilityIds = {};
  List<PropertyImage> _existingPhotos = [];
  bool _photoError = false;
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
      if (room != null) _loadPhotos();
    });
  }

  /// Foto kamar diambil dari detail properti, karena endpoint itu yang
  /// memuat semua gambar beserta room_id-nya.
  Future<void> _loadPhotos() async {
    try {
      final detail =
          await context.read<CatalogProvider>().propertyDetail(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _existingPhotos = detail.images
            .where((image) => image.roomId == widget.room!.id)
            .toList(growable: false);
      });
    } on ApiException {
      // Foto hanya pelengkap form; kegagalan memuatnya tidak menghalangi
      // pemilik menyimpan data kamar.
    }
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

  Future<void> _removePhoto(String imageId) async {
    final error = await context.read<OwnerProvider>().deleteImage(imageId);
    if (!mounted) return;
    if (error == null) {
      setState(() {
        _existingPhotos = _existingPhotos
            .where((image) => image.id != imageId)
            .toList(growable: false);
      });
    } else {
      showError(context, error);
    }
  }

  Future<void> _submit() async {
    final validForm = _formKey.currentState!.validate();
    final photos = _photoKey.currentState!;
    final hasPhoto = _existingPhotos.isNotEmpty || photos.files.isNotEmpty;

    if (!hasPhoto) setState(() => _photoError = true);
    if (!validForm || !hasPhoto) return;

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
    String? error;
    String? roomId = widget.room?.id;

    if (widget.isEdit) {
      error = await provider.updateRoom(roomId!, widget.propertyId, body);
    } else {
      final result = await provider.createRoom(widget.propertyId, body);
      error = result.error;
      roomId = result.room?.id;
      // Kamar sudah terbuat tetapi id tidak terbaca: fotonya tidak bisa
      // diunggah, jadi pemilik diberi tahu alih-alih diam saja.
      if (error == null && roomId == null) {
        error = 'Kamar tersimpan, tetapi foto gagal diunggah. Buka kamar ini '
            'lalu tambahkan fotonya.';
      }
    }

    if (!mounted) return;

    if (error == null && roomId != null && photos.files.isNotEmpty) {
      final uploadError = await provider.uploadImages(
        widget.propertyId,
        photos.files,
        roomId: roomId,
      );
      if (!mounted) return;
      error = uploadError;
    }

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
            const SizedBox(height: 18),
            RoomPhotoField(
              key: _photoKey,
              existing: _existingPhotos,
              showError: _photoError,
              enabled: !_submitting,
              onDeleteExisting: _removePhoto,
            ),
            const SizedBox(height: 18),
            Text('Kamar mandi', style: AppFonts.label(13, weight: FontWeight.w700)),
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
            Text('Fasilitas', style: AppFonts.label(13, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (facilities.isEmpty)
              Text(
                'Daftar fasilitas belum termuat.',
                style: AppFonts.label(12, color: AppColors.textSecondary),
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
              Text('Status kamar', style: AppFonts.label(13, weight: FontWeight.w700)),
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
              Text(
                'Status Dipesan dan Terisi diatur otomatis oleh sistem.',
                style: AppFonts.label(11.5, color: AppColors.textSecondary),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppFonts.label(12.5, color: AppColors.dangerText),
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
