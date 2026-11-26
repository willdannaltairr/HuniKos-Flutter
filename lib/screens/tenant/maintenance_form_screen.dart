import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/booking.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/image_picker_field.dart';

/// Form laporan kerusakan. Booking yang bisa dipilih hanya yang CONFIRMED.
class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key, this.initialBookingId});

  final String? initialBookingId;

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  List<Booking> _bookings = [];
  String? _bookingId;
  XFile? _photo;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.initialBookingId;
    _loadBookings();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final result = await context.read<TenantProvider>().fetchConfirmedBookings();
    if (!mounted) return;
    setState(() {
      _bookings = result;
      _bookingId ??= result.isEmpty ? null : result.first.id;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bookingId == null) {
      setState(() => _error = 'Pilih booking yang ingin dilaporkan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await context.read<TenantProvider>().createMaintenance(
          bookingId: _bookingId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          photo: _photo,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      showSuccess(context, 'Laporan terkirim ke pemilik');
      context.pop();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor kerusakan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _NoBooking()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Booking',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _bookingId,
                        decoration: const InputDecoration(),
                        items: _bookings
                            .map(
                              (booking) => DropdownMenuItem(
                                value: booking.id,
                                child: Text(
                                  '${booking.property.name} • Kamar ${booking.room.roomNumber}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _bookingId = value),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _title,
                        label: 'Judul laporan',
                        hint: 'Contoh: Kran air kamar mandi bocor',
                        validator: (value) =>
                            Validators.textLength(value, 'Judul', min: 3, max: 120),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _description,
                        label: 'Deskripsi',
                        maxLines: 4,
                        maxLength: 1000,
                        validator: (value) =>
                            Validators.textLength(value, 'Deskripsi', min: 5, max: 1000),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Foto (opsional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ImagePickerField(
                        label: 'Pilih foto',
                        maxFiles: 1,
                        onPicked: (files) => setState(
                          () => _photo = files.isEmpty ? null : files.first,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.dangerText,
                          ),
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
                            : const Text('Kirim laporan'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _NoBooking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 40, color: AppColors.border),
            SizedBox(height: 12),
            Text(
              'Belum ada booking aktif',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Laporan kerusakan hanya bisa dibuat untuk booking yang sudah dikonfirmasi pemilik.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
