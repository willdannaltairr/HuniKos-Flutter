import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Daftar pembayaran Midtrans milik pemilik. Statusnya ditulis otomatis oleh
/// webhook, jadi pemilik hanya melihat dan bisa menyegarkan data.
class OwnerPaymentsScreen extends StatefulWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  State<OwnerPaymentsScreen> createState() => _OwnerPaymentsScreenState();
}

class _OwnerPaymentsScreenState extends State<OwnerPaymentsScreen> {
  static const _filters = [
    (value: null, label: 'Semua'),
    (value: 'PENDING', label: 'Menunggu'),
    (value: 'VERIFIED', label: 'Lunas'),
    (value: 'REJECTED', label: 'Gagal'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OwnerProvider>();
      if (provider.payments.isEmpty && !provider.loadingPayments) {
        provider.loadPayments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        actions: [
          IconButton(
            onPressed: () => provider.loadPayments(status: provider.paymentFilter),
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Segarkan status',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: provider.paymentFilter == filter.value,
                    onSelected: (_) => provider.loadPayments(status: filter.value),
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
    if (provider.loadingPayments && provider.payments.isEmpty) {
      return const LoadingView();
    }
    if (provider.paymentsError != null) {
      return ErrorState(
        message: provider.paymentsError!,
        onRetry: () => provider.loadPayments(status: provider.paymentFilter),
      );
    }
    if (provider.payments.isEmpty) {
      return const EmptyState(
        title: 'Belum ada pembayaran',
        description: 'Pembayaran Midtrans dari penyewa akan muncul di sini.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPayments(status: provider.paymentFilter),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: provider.payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _PaymentCard(payment: provider.payments[index]),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
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
                    Formatters.rupiah(payment.amount),
                    style: AppFonts.title(16, weight: FontWeight.w700),
                  ),
                ),
                StatusChip(
                  compact: true,
                  status: payment.status,
                  label: PaymentStatus.label(payment.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${payment.tenantName} • ${payment.propertyName} Kamar ${payment.roomNumber}',
              style: AppFonts.label(12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${payment.bookingCode} • '
              '${Formatters.dateTime(payment.createdAt?.toIso8601String())}',
              style: AppFonts.label(11.5, color: AppColors.textSecondary),
            ),
            if (payment.midtransOrderId != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Midtrans: ${payment.midtransOrderId}'
                  '${payment.midtransPaymentType == null ? '' : ' • ${payment.midtransPaymentType}'}',
                  style: AppFonts.label(11.5, color: AppColors.textSecondary),
                ),
              ),
            ],
            if (payment.isPending)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Menunggu konfirmasi dari Midtrans — tidak perlu diverifikasi manual.',
                  style: AppFonts.label(11.5, color: AppColors.warningText),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
