import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/room_detail.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/state_views.dart';

/// Form booking: pilih tanggal mulai, durasi, catatan, lalu lihat ringkasan
/// total. Total dihitung ulang oleh server saat booking dibuat.
class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  late Future<RoomDetail> _future;
  final _note = TextEditingController();
  DateTime? _startDate;
  int _duration = 1;
  bool _submitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _future = context.read<CatalogProvider>().roomDetail(widget.roomId);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _endDate {
    final start = _startDate ?? _today;
    // Perkiraan saja; tanggal akhir yang sebenarnya dihitung server. Hari
    // dipotong ke akhir bulan agar 31 Jan + 1 bulan tidak melewati Maret.
    final monthIndex = start.month - 1 + _duration;
    final year = start.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return DateTime(year, month, day);
  }

  bool _isBlocked(DateTime day, List<UnavailableRange> ranges) {
    for (final range in ranges) {
      final start = Formatters.parseDate(range.startDate);
      final end = Formatters.parseDate(range.endDate);
      if (start == null || end == null) continue;
      final date = DateTime(day.year, day.month, day.day);
      if (!date.isBefore(start) && date.isBefore(end)) return true;
    }
    return false;
  }

  Future<void> _pickDate(List<UnavailableRange> ranges) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _today,
      firstDate: _today,
      lastDate: DateTime(_today.year + 2, 12, 31),
      selectableDayPredicate: (day) => !_isBlocked(day, ranges),
      helpText: 'Pilih tanggal mulai sewa',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit(RoomDetail detail) async {
    if (_startDate == null) {
      setState(() => _formError = 'Pilih tanggal mulai sewa terlebih dahulu.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      final booking = await context.read<TenantProvider>().createBooking(
            roomId: detail.room.id,
            startDate: Formatters.isoDate(_startDate!),
            durationMonths: _duration,
            note: _note.text.trim(),
          );
      if (!mounted) return;
      await _showSuccess(booking.bookingCode);
      if (mounted) context.go('/bookings/${booking.id}');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = error.message;
      });
      if (error.isConflict) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kamar sudah dipesan'),
            content: Text(error.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Pilih tanggal lain'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showSuccess(String code) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 36),
        title: const Text('Booking terkirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pemilik akan memeriksa pengajuanmu. Simpan kode booking ini:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Lihat booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan kamar')),
      body: FutureBuilder<RoomDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorState(
              message: error is ApiException ? error.message : 'Gagal memuat kamar',
              onRetry: () => setState(() {
                _future = context.read<CatalogProvider>().roomDetail(widget.roomId);
              }),
            );
          }

          final detail = snapshot.data!;
          final room = detail.room;
          final total = room.monthlyPrice * _duration;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.property.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kamar ${room.roomNumber} • ${Formatters.rupiah(room.monthlyPrice)} /bulan',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Tanggal mulai',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDate(detail.unavailableRanges),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _startDate == null
                                    ? 'Pilih tanggal'
                                    : Formatters.date(Formatters.isoDate(_startDate!)),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _startDate == null
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Durasi sewa',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _duration > 1
                                ? () => setState(() => _duration--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(
                            child: Text(
                              '$_duration bulan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _duration < 24
                                ? () => setState(() => _duration++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Catatan untuk pemilik (opsional)',
                        hintText: 'Contoh: rencana masuk awal bulan depan',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.blueTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            'Harga per bulan',
                            Formatters.rupiah(room.monthlyPrice),
                          ),
                          const SizedBox(height: 6),
                          _summaryRow('Durasi', '$_duration bulan'),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Perkiraan selesai',
                            Formatters.shortDate(Formatters.isoDate(_endDate)),
                          ),
                          const Divider(height: 20),
                          _summaryRow(
                            'Total',
                            Formatters.rupiah(total),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _formError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.dangerText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Booking masih perlu disetujui pemilik sebelum kamu membayar.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _submit(detail),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.navy,
                            ),
                          )
                        : const Text('Kirim pengajuan booking'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 12.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
