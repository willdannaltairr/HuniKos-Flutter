import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Daftar booking milik penyewa dengan filter status.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const _filters = [
    (value: null, label: 'Semua'),
    (value: 'PENDING', label: 'Menunggu'),
    (value: 'AWAITING_PAYMENT', label: 'Bayar'),
    (value: 'CONFIRMED', label: 'Aktif'),
    (value: 'COMPLETED', label: 'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TenantProvider>();
      if (provider.bookings.isEmpty && !provider.loadingBookings) {
        provider.loadBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenantProvider>();

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Booking saya')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((filter) {
                final selected = provider.statusFilter == filter.value;
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

  Widget _buildBody(TenantProvider provider) {
    if (provider.loadingBookings && provider.bookings.isEmpty) {
      return const LoadingView();
    }
    if (provider.bookingsError != null) {
      return ErrorState(
        message: provider.bookingsError!,
        onRetry: () => provider.loadBookings(status: provider.statusFilter),
      );
    }
    if (provider.bookings.isEmpty) {
      return const EmptyState(
        title: 'Belum ada booking',
        description: 'Cari kos di tab Explore lalu ajukan booking.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadBookings(
        status: provider.statusFilter,
        keepFilter: true,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _BookingCard(
          booking: provider.bookings[index],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.property.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                'Kamar ${booking.room.roomNumber} • ${booking.bookingCode}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.dateRange(booking.startDate, booking.endDate),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Total ${Formatters.rupiah(booking.totalAmount)} • ${booking.durationMonths} bulan',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
