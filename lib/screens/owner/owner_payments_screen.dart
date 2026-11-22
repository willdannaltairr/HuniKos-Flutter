import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payment.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Daftar bukti transfer. Bukti bisa dilihat penuh (zoom), lalu disetujui
/// atau ditolak dengan catatan wajib.
class OwnerPaymentsScreen extends StatefulWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  State<OwnerPaymentsScreen> createState() => _OwnerPaymentsScreenState();
}

class _OwnerPaymentsScreenState extends State<OwnerPaymentsScreen> {
  static const _filters = [
    (value: null, label: 'Semua'),
    (value: 'PENDING', label: 'Menunggu'),
    (value: 'VERIFIED', label: 'Terverifikasi'),
    (value: 'REJECTED', label: 'Ditolak'),
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

  void _viewProof(Payment payment) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                'Bukti ${Formatters.rupiah(payment.amount)}',
                style: const TextStyle(fontSize: 15),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: NetworkImageView(
                  url: payment.proofUrl,
                  fit: BoxFit.contain,
                  borderRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify(Payment payment, bool approve) async {
    final decision = await showDecisionDialog(
      context,
      title: approve ? 'Verifikasi pembayaran?' : 'Tolak pembayaran?',
      message: approve
          ? 'Booking akan menjadi CONFIRMED dan kamar berstatus terisi.'
          : 'Penyewa bisa mengunggah bukti baru selama batas waktu masih ada.',
      confirmLabel: approve ? 'Verifikasi' : 'Tolak',
      requireNote: !approve,
      destructive: !approve,
    );
    if (!decision.confirmed || !mounted) return;

    final error = await context.read<OwnerProvider>().verifyPayment(
          paymentId: payment.id,
          action: approve ? 'approve' : 'reject',
          note: decision.note,
        );
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, approve ? 'Pembayaran diverifikasi' : 'Pembayaran ditolak');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((filter) {
                final selected = provider.paymentFilter == filter.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
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
        description: 'Bukti transfer dari penyewa akan muncul di sini.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPayments(status: provider.paymentFilter),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: provider.payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final payment = provider.payments[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _viewProof(payment),
                        child: NetworkImageView(
                          url: payment.proofUrl,
                          width: 64,
                          height: 64,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    Formatters.rupiah(payment.amount),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                StatusChip(
                                  compact: true,
                                  status: payment.status,
                                  label: PaymentStatus.label(payment.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${payment.tenantName} • ${payment.propertyName} '
                              'Kamar ${payment.roomNumber}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${payment.bookingCode} • '
                              '${Formatters.dateTime(payment.createdAt?.toIso8601String())}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (payment.note != null)
                              Text(
                                'Catatan: ${payment.note}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.dangerText,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (payment.isPending) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _verify(payment, false),
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
                            onPressed: () => _verify(payment, true),
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                            child: const Text('Verifikasi'),
                          ),
                        ),
                      ],
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
