import 'app_settings.dart';

/// Kamus teks dua bahasa. Kunci yang belum diterjemahkan jatuh ke bahasa
/// Indonesia apa adanya, jadi tidak ada teks kosong di layar.
class I18n {
  const I18n._();

  static AppLanguage _language = AppLanguage.id;

  static void use(AppLanguage language) => _language = language;

  static AppLanguage get language => _language;

  static String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return _language == AppLanguage.en ? entry.$2 : entry.$1;
  }

  /// (Indonesia, English)
  static const Map<String, (String, String)> _strings = {
    // Navigasi penyewa
    'nav.explore': ('Jelajah', 'Explore'),
    'nav.bookings': ('Booking', 'Bookings'),
    'nav.reports': ('Laporan', 'Reports'),
    'nav.profile': ('Profil', 'Profile'),
    // Navigasi pemilik
    'nav.dashboard': ('Dasbor', 'Dashboard'),
    'nav.properties': ('Properti', 'Properties'),
    'nav.payments': ('Bayar', 'Payments'),
    // Navigasi admin
    'nav.verification': ('Verifikasi', 'Verification'),
    'nav.users': ('Pengguna', 'Users'),
    // Profil
    'profile.title': ('Profil', 'Profile'),
    'profile.settings': ('Pengaturan', 'Settings'),
    'profile.appearance': ('Tampilan', 'Appearance'),
    'profile.darkMode': ('Mode gelap', 'Dark mode'),
    'profile.language': ('Bahasa', 'Language'),
    'profile.account': ('Akun', 'Account'),
    'profile.edit': ('Ubah profil', 'Edit profile'),
    'profile.changePhoto': ('Ganti foto', 'Change photo'),
    'profile.save': ('Simpan perubahan', 'Save changes'),
    'profile.name': ('Nama lengkap', 'Full name'),
    'profile.phone': ('Nomor telepon', 'Phone number'),
    'profile.logout': ('Keluar', 'Log out'),
    'profile.logoutTitle': ('Keluar dari akun?', 'Log out of this account?'),
    'profile.logoutMessage': (
      'Kamu perlu masuk lagi untuk membuka data sewa.',
      'You will need to sign in again to see your rental data.'
    ),
    'profile.saved': ('Profil berhasil diperbarui', 'Profile updated'),
    'profile.saveFailed': ('Gagal memperbarui profil', 'Could not update profile'),
    'profile.imageTooLarge': ('Ukuran gambar maksimal 2 MB', 'Image size must be under 2 MB'),
    'profile.photoUpdated': ('Foto profil diperbarui', 'Profile photo updated'),
    'profile.uploadFailed': ('Gagal mengunggah foto', 'Could not upload the photo'),
    // Ringkasan keuangan
    'finance.title': ('Ringkasan keuangan', 'Financial summary'),
    'finance.spentTotal': ('Total pengeluaran', 'Total spent'),
    'finance.spentMonth': ('Bulan ini', 'This month'),
    'finance.activeBookings': ('Sewa aktif', 'Active rentals'),
    'finance.revenueMonth': ('Pendapatan bulan ini', 'Revenue this month'),
    'finance.pendingPayments': ('Pembayaran menunggu', 'Pending payments'),
    'finance.occupiedRooms': ('Kamar terisi', 'Occupied rooms'),
    'finance.pendingVerification': ('Menunggu verifikasi', 'Pending verification'),
    'finance.totalUsers': ('Total pengguna', 'Total users'),
    'finance.activeBookingsAll': ('Booking aktif', 'Active bookings'),
    'finance.none': ('Belum ada data', 'No data yet'),
    // Halaman pencarian penuh
    'search.title': ('Cari', 'Search'),
    'search.hint': ('Cari kos, alamat, atau kota', 'Search homes, address, or city'),
    'common.retry': ('Coba lagi', 'Retry'),
    'common.loading': ('Memuat…', 'Loading…'),
  };
}
