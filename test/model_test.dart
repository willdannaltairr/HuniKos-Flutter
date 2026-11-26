import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hunikos/core/formatters.dart';
import 'package:hunikos/core/validators.dart';
import 'package:hunikos/models/booking.dart';
import 'package:hunikos/models/property.dart';
import 'package:hunikos/models/room_detail.dart';
import 'package:hunikos/models/user.dart';

void main() {
  // Format tanggal memakai locale id_ID, sama seperti main.dart.
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('User.fromJson', () {
    test('membaca field yang dikirim backend', () {
      final user = User.fromJson({
        'id': '2b6205f4-80bc-46d9-b68b-23485d8a85b8',
        'full_name': 'Andi Pratama',
        'email': 'tenant1@hunikos.test',
        'phone_number': '+6281200000004',
        'avatar_url': null,
        'role': 'tenant',
        'account_status': 'active',
        'created_at': '2026-11-19T04:59:00.587Z',
      });

      expect(user.fullName, 'Andi Pratama');
      expect(user.isTenant, isTrue);
      expect(user.isSuspended, isFalse);
      expect(user.initials, 'AP');
      expect(user.avatarUrl, isNull);
      expect(user.createdAt, isNotNull);
    });
  });

  group('PropertyItem.fromJson', () {
    test('angka dari API menjadi num, bukan teks', () {
      final property = PropertyItem.fromJson({
        'id': 'a51d8104-4ba9-45fb-ac29-3ae983275e3e',
        'name': 'Kos Uji',
        'city': 'Yogyakarta',
        'address': 'Jl. Uji',
        'property_type': 'campur',
        'min_price': 700000,
        'available_rooms': 1,
        'total_rooms': 2,
        'cover_image_url': null,
      });

      expect(property.minPrice, 700000);
      expect(property.availableRooms, 1);
      expect(property.typeLabel, 'Campur');
      expect(property.coverImageUrl, isNull);
    });

    test('min_price null saat belum ada kamar', () {
      final property = PropertyItem.fromJson({
        'id': 'x',
        'name': 'Kos Baru',
        'city': 'Bandung',
        'address': 'Jl. Baru',
        'property_type': 'putri',
        'min_price': null,
        'available_rooms': 0,
        'total_rooms': 0,
      });

      expect(property.minPrice, isNull);
      expect(property.typeLabel, 'Putri');
    });
  });

  group('Booking.fromJson', () {
    test('membaca objek bersarang room, property, dan tenant', () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'booking_code': 'BK-ABCD1234',
        'status': 'AWAITING_PAYMENT',
        'start_date': '2027-01-05',
        'end_date': '2027-04-05',
        'duration_months': 3,
        'rental_price_snapshot': 1200000,
        'total_amount': 3600000,
        'note': null,
        'owner_note': null,
        'expires_at': '2026-11-20T10:00:00.000Z',
        'created_at': '2026-11-19T10:00:00.000Z',
        'room': {'id': 'r1', 'room_number': 'A1', 'room_type': 'standard'},
        'property': {'id': 'p1', 'name': 'Kos Melati', 'city': 'Yogyakarta'},
        'tenant': {'id': 'u1', 'full_name': 'Andi', 'phone_number': null},
        'latest_payment_status': 'PENDING',
      });

      expect(booking.totalAmount, 3600000);
      expect(booking.durationMonths, 3);
      expect(booking.room.roomNumber, 'A1');
      expect(booking.property.name, 'Kos Melati');
      expect(booking.tenant.phoneNumber, isNull);
      expect(booking.canUploadProof, isTrue);
      expect(booking.canCancel, isTrue);
      expect(booking.latestPaymentStatus, 'PENDING');
    });
  });

  group('RoomDetail.fromJson', () {
    test('unavailable_ranges tetap berupa teks tanggal', () {
      final detail = RoomDetail.fromJson({
        'id': 'r1',
        'property_id': 'p1',
        'room_number': 'A1',
        'room_type': 'standard',
        'dimensions': '3x4 m',
        'monthly_price': 1100000,
        'max_occupants': 1,
        'bathroom_type': 'dalam',
        'floor_number': 1,
        'status': 'AVAILABLE',
        'facilities': [
          {'id': 'f1', 'name': 'AC'},
        ],
        'cover_image_url': null,
        'property': {
          'id': 'p1',
          'name': 'Kos Melati',
          'city': 'Yogyakarta',
          'address': 'Jl. Melati',
        },
        'images': [],
        'unavailable_ranges': [
          {'start_date': '2027-01-05', 'end_date': '2027-04-05'},
        ],
      });

      expect(detail.room.monthlyPrice, 1100000);
      expect(detail.room.facilities.single.name, 'AC');
      expect(detail.unavailableRanges.single.startDate, '2027-01-05');
      expect(detail.property.name, 'Kos Melati');
    });
  });

  group('Validators', () {
    test('email harus berformat benar', () {
      expect(Validators.email('bukan-email'), isNotNull);
      expect(Validators.email('tenant1@hunikos.test'), isNull);
    });

    test('password wajib 1 huruf dan 1 angka', () {
      expect(Validators.password('abcdefgh'), contains('angka'));
      expect(Validators.password('12345678'), contains('huruf'));
      expect(Validators.password('abcdefg1'), isNull);
      expect(Validators.password('a1'), contains('minimal 8'));
    });

    test('nomor telepon boleh kosong tetapi tidak boleh huruf', () {
      expect(Validators.phoneNumber(''), isNull);
      expect(Validators.phoneNumber('0812abc'), isNotNull);
      expect(Validators.phoneNumber('+6281200000004'), isNull);
    });

    test('nomor telepon pendaftaran wajib diisi dan berawalan +62', () {
      expect(Validators.phoneNumberRequired(''), contains('wajib diisi'));
      expect(Validators.phoneNumberRequired('+62'), contains('wajib diisi'));
      expect(Validators.phoneNumberRequired('081234567890'), contains('+62'));
      expect(Validators.phoneNumberRequired('+628'), contains('tidak valid'));
      expect(Validators.phoneNumberRequired('+6281234567890123'), contains('tidak valid'));
      expect(Validators.phoneNumberRequired('+6281234567890'), isNull);
      // Spasi dan tanda hubung yang diketik pengguna tidak membuatnya gagal.
      expect(Validators.phoneNumberRequired('+62 812-3456-7890'), isNull);
    });

    test('harga wajib lebih dari nol dan maksimal 100 juta', () {
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('100000001'), isNotNull);
      expect(Validators.price('1200000'), isNull);
    });
  });

  group('Formatters', () {
    test('rupiah tanpa desimal', () {
      expect(Formatters.rupiah(1200000), contains('1.200.000'));
      expect(Formatters.rupiah(null), '-');
    });

    test('tanggal ISO tidak bergeser satu hari', () {
      final parsed = Formatters.parseDate('2027-01-05');
      expect(parsed, DateTime(2027, 1, 5));
      expect(Formatters.shortDate('2027-01-05'), contains('2027'));
      expect(Formatters.isoDate(DateTime(2027, 1, 5)), '2027-01-05');
    });
  });
}
