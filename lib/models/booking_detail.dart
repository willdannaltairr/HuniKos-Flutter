import '../core/json_utils.dart';
import 'booking.dart';
import 'payment.dart';

class BookingHistoryEntry {
  const BookingHistoryEntry({
    required this.toStatus,
    this.fromStatus,
    this.note,
    this.createdAt,
  });

  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime? createdAt;

  factory BookingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BookingHistoryEntry(
      fromStatus: asString(json['from_status']),
      toStatus: asString(json['to_status']) ?? '-',
      note: asString(json['note']),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
    );
  }
}

/// BookingDetail = Booking + daftar pembayaran + riwayat status.
class BookingDetail {
  const BookingDetail({
    required this.booking,
    required this.payments,
    required this.history,
  });

  final Booking booking;
  final List<Payment> payments;
  final List<BookingHistoryEntry> history;

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      booking: Booking.fromJson(json),
      payments:
          asMapList(json['payments']).map(Payment.fromJson).toList(growable: false),
      history: asMapList(json['history'])
          .map(BookingHistoryEntry.fromJson)
          .toList(growable: false),
    );
  }
}
