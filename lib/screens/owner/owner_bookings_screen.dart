import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Booking masuk untuk semua kamar milik pemilik, dengan aksi setujui,
/// tolak (catatan wajib), dan selesaikan.
class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  static const _filters = [
    (value: null, label: 'Semua'),
    (value: 'PENDING', label: 'Menunggu'),
    (value: 'AWAITING_PAYMENT', label: 'Bayar'),
    (value: 'CONFIRMED', label: 'Aktif'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OwnerProvider>();
      if (provider.bookings.isEmpty && !provider.loadingBookings) {
        provider.loadBookings();
      }
    });
  }

  Future<void> _decide(Booking booking, bool approve) async {
    final decision = await showDecisionDialog(
      context,
      title: approve ? 'Setujui booking?' : 'Tolak booking?',
      message: approve
          ? 'Penyewa akan mendapat batas 24 jam untuk mengunggah bukti transfer.'
          : 'Beri alasan agar penyewa tahu kenapa pengajuan ditolak.',
      confirmLabel: approve ? 'Setujui' : 'Tolak',
      requireNote: !approve,
      destructive: !approve,
    );
    if (!decision.confirmed || !mounted) return;

    final error = await context.read<OwnerProvider>().decideBooking(
          bookingId: booking.id,
          action: approve ? 'approve' : 'reject',
          note: decision.note,
        );
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, approve ? 'Booking disetujui' : 'Booking ditolak');
    } else {
      showError(context, error);
    }
  }

  Future<void> _complete(Booking booking) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Selesaikan sewa?',
      message: 'Kamar akan kembali tersedia setelah masa sewa selesai.',
      confirmLabel: 'Selesaikan',
      destructive: false,
    );
    if (!confirmed || !mounted) return;

    final error = await context.read<OwnerProvider>().completeBooking(booking.id);
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Booking diselesaikan');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Booking masuk')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((filter) {
                final selected = provider.bookingFilter == filter.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    onSelected: (_) => provider.loadBookings(status: filter.value),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(OwnerProvider provider) {
    if (provider.loadingBookings && provider.bookings.isEmpty) {
      return const LoadingView();
    }
    if (provider.bookingsError != null) {
      return ErrorState(
        message: provider.bookingsError!,
        onRetry: () => provider.loadBookings(status: provider.bookingFilter),
      );
    }
    if (provider.bookings.isEmpty) {
      return const EmptyState(
        title: 'Belum ada booking',
        description: 'Pengajuan penyewa akan muncul di sini.',
        icon: Icons.event_note_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadBookings(status: provider.bookingFilter),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: provider.bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final booking = provider.bookings[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.tenant.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusChip(
                        compact: true,
                        status: booking.status,
                        label: BookingStatus.label(booking.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.property.name} • Kamar ${booking.room.roomNumber} • ${booking.bookingCode}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.dateRange(booking.startDate, booking.endDate),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${booking.durationMonths} bulan • ${Formatters.rupiah(booking.totalAmount)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (booking.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Catatan penyewa: ${booking.note}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                  if (booking.canDecide) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _decide(booking, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              foregroundColor: AppColors.dangerText,
                              side: const BorderSide(color: Color(0xFFFECACA)),
                            ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _decide(booking, true),
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                            child: const Text('Setujui'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (booking.canComplete) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _complete(booking),
                      icon: const Icon(Icons.task_alt, size: 16),
                      label: const Text('Selesaikan sewa'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
