import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../core/midtrans_payment.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../models/booking_detail.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Detail booking: status, riwayat, batas bayar, unggah bukti, dan batal.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadDetail(widget.bookingId);
    });
  }

  Future<void> _bayar() async {
    setState(() => _paying = true);
    final provider = context.read<TenantProvider>();
    try {
      final checkout = await provider.createMidtransCheckout(widget.bookingId);
      final hasil = await MidtransPayment().start(
        snapToken: checkout.snapToken,
        redirectUrl: checkout.redirectUrl,
      );

      if (!mounted) return;
      if (hasil == PaymentOutcome.browserOpened) {
        showSuccess(
          context,
          'Halaman pembayaran dibuka. Kembali ke aplikasi setelah selesai '
          'untuk memeriksa statusnya.',
        );
      } else if (hasil == PaymentOutcome.paid) {
        showSuccess(context, 'Pembayaran berhasil, menunggu konfirmasi sistem');
      } else if (hasil == PaymentOutcome.pending) {
        showSuccess(context, 'Pembayaran belum selesai. Kamu bisa melanjutkannya nanti.');
      }

      // Status asli tetap diambil dari backend, bukan dari hasil di perangkat.
      await provider.syncMidtransPayment(widget.bookingId);
    } catch (error) {
      if (!mounted) return;
      showError(context, error is ApiException ? error.message : 'Pembayaran gagal dimulai');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _cekStatus() async {
    setState(() => _paying = true);
    try {
      await context.read<TenantProvider>().syncMidtransPayment(widget.bookingId);
      if (!mounted) return;
      showSuccess(context, 'Status pembayaran sudah diperbarui');
    } catch (error) {
      if (!mounted) return;
      showError(context, error is ApiException ? error.message : 'Gagal mengecek status');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Batalkan booking?',
      message: 'Booking yang dibatalkan tidak bisa dilanjutkan lagi.',
      confirmLabel: 'Ya, batalkan',
    );
    if (!confirmed || !mounted) return;

    final error = await context.read<TenantProvider>().cancelBooking(widget.bookingId);
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Booking dibatalkan');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenantProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail booking')),
      body: provider.loadingDetail
          ? const LoadingView()
          : provider.detail == null
              ? ErrorState(
                  message: provider.detailError ?? 'Booking tidak ditemukan',
                  onRetry: () => provider.loadDetail(widget.bookingId),
                )
              : _buildContent(provider.detail!),
    );
  }

  Widget _buildContent(BookingDetail detail) {
    final booking = detail.booking;
    final pendingPayment = context.read<TenantProvider>().latestPendingPayment(detail);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.bookingCode,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  StatusChip(
                    status: booking.status,
                    label: BookingStatus.label(booking.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                booking.property.name,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              Text(
                'Kamar ${booking.room.roomNumber} • ${booking.room.roomType}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                rows: [
                  ('Tanggal mulai', Formatters.date(booking.startDate)),
                  ('Tanggal selesai', Formatters.date(booking.endDate)),
                  ('Durasi', '${booking.durationMonths} bulan'),
                  ('Harga per bulan', Formatters.rupiah(booking.rentalPriceSnapshot)),
                  ('Total', Formatters.rupiah(booking.totalAmount)),
                ],
              ),
              if (booking.note != null) ...[
                const SizedBox(height: 12),
                _Note(title: 'Catatanmu', text: booking.note!),
              ],
              if (booking.ownerNote != null) ...[
                const SizedBox(height: 12),
                _Note(title: 'Catatan pemilik', text: booking.ownerNote!),
              ],
              if (booking.status == 'AWAITING_PAYMENT' && booking.expiresAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bayar sebelum ${Formatters.dateTime(booking.expiresAt!.toIso8601String())} '
                          '(sisa ${Formatters.countdown(booking.expiresAt)})',
                          style: AppFonts.label(12.5, color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Riwayat status',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (detail.history.isEmpty)
                const Text(
                  'Belum ada riwayat.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                )
              else
                ...detail.history.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.circle, size: 7, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.fromStatus == null
                                    ? BookingStatus.label(entry.toStatus)
                                    : '${BookingStatus.label(entry.fromStatus!)} → '
                                        '${BookingStatus.label(entry.toStatus)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${Formatters.dateTime(entry.createdAt?.toIso8601String())}'
                                '${entry.note == null ? '' : ' • ${entry.note}'}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (detail.payments.isEmpty)
                const Text(
                  'Belum ada bukti pembayaran.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                )
              else
                ...detail.payments.map(
                  (payment) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.rupiah(payment.amount),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  Formatters.dateTime(payment.createdAt?.toIso8601String()),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (payment.note != null)
                                  Text(
                                    payment.note!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.dangerText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          StatusChip(
                            compact: true,
                            status: payment.status,
                            label: _paymentLabel(payment.status),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Column(
              children: [
                if (booking.canUploadProof && pendingPayment == null)
                  FilledButton.icon(
                    onPressed: _paying ? null : _bayar,
                    icon: _paying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navy,
                            ),
                          )
                        : const Icon(Icons.payment_outlined),
                    label: Text(
                      _paying
                          ? 'Membuka pembayaran…'
                          : 'Bayar ${Formatters.rupiah(booking.totalAmount)}',
                    ),
                  ),
                if (booking.canUploadProof && pendingPayment != null) ...[
                  if (pendingPayment.fromMidtrans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.icon(
                        onPressed: _paying ? null : _bayar,
                        icon: const Icon(Icons.payment_outlined),
                        label: const Text('Lanjutkan pembayaran'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _paying ? null : _cekStatus,
                    icon: const Icon(Icons.refresh_outlined, size: 18),
                    label: const Text('Cek status pembayaran'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, top: 8),
                    child: Text(
                      'Status diperbarui otomatis oleh notifikasi Midtrans.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.warningText),
                    ),
                  ),
                ],
                if (booking.canCancel)
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerText,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    ),
                    child: const Text('Batalkan booking'),
                  ),
                if (booking.status == 'CONFIRMED')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/maintenance/new?bookingId=${booking.id}'),
                    icon: const Icon(Icons.build_outlined, size: 18),
                    label: const Text('Laporkan kerusakan'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _paymentLabel(String status) {
    switch (status) {
      case 'VERIFIED':
        return 'Terverifikasi';
      case 'REJECTED':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
