import 'app_settings.dart';

/// Kamus teks dua bahasa. Kunci yang belum diterjemahkan jatuh ke bahasa
/// Indonesia apa adanya, jadi tidak ada teks kosong di layar.
///
/// Pemanggilan: I18n.t('auth.login') atau
/// I18n.t('auth.socialUnavailable', {'provider': 'Google'}).
class I18n {
  const I18n._();

  static AppLanguage _language = AppLanguage.id;

  static void use(AppLanguage language) => _language = language;

  static AppLanguage get language => _language;

  static String t(String key, [Map<String, String>? params]) {
    final entry = _strings[key];
    var text = entry == null
        ? key
        : (_language == AppLanguage.en ? entry.$2 : entry.$1);
    if (params != null) {
      params.forEach((name, value) {
        text = text.replaceAll('{$name}', value);
      });
    }
    return text;
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
    // Masuk dan daftar
    'auth.tabLogin': ('Masuk', 'Sign in'),
    'auth.tabRegister': ('Daftar', 'Sign up'),
    'auth.loginTitle': ('Masuk dan lanjutkan\npencarian kosmu', 'Sign in and keep\nsearching for a home'),
    'auth.loginSubtitle': ('Satu akun untuk menyewa, membayar, dan melapor.', 'One account to rent, pay, and report.'),
    'auth.registerTitle': ('Ayo siapkan\nakunmu', "Let's set up\nyour account"),
    'auth.registerSubtitle': ('Daftar untuk mulai mencari atau mengelola kos.', 'Sign up to start searching or managing rooms.'),
    'auth.email': ('Alamat email', 'Email address'),
    'auth.password': ('Password', 'Password'),
    'auth.passwordHint': ('Masukkan password', 'Enter your password'),
    'auth.passwordLongHint': ('Minimal 8 karakter, ada huruf dan angka', 'At least 8 characters, with a letter and a number'),
    'auth.passwordRequired': ('Password wajib diisi', 'Password is required'),
    'auth.login': ('Login', 'Sign in'),
    'auth.orContinue': ('Atau lanjutkan dengan', 'Or continue with'),
    'auth.socialUnavailable': (
      'Masuk dengan {provider} belum tersedia. Gunakan email dan password.',
      'Sign in with {provider} is not available. Use email and password.'
    ),
    'auth.fullName': ('Nama lengkap', 'Full name'),
    'auth.nameHint': ('Sesuai KTP', 'As written on your ID'),
    'auth.phone': ('Nomor telepon', 'Phone number'),
    'auth.registerAs': ('Saya mendaftar sebagai', 'I am registering as'),
    'auth.tenant': ('Penyewa', 'Tenant'),
    'auth.owner': ('Pemilik', 'Owner'),
    'auth.tenantDesc': ('Mencari kos', 'Looking for a room'),
    'auth.ownerDesc': ('Mengelola kos', 'Managing rooms'),
    // Beranda
    'explore.greeting': ('Hai, {name} 👋', 'Hi, {name} 👋'),
    'explore.heroTitle': ('Mau tinggal di mana\nbulan ini?', 'Where would you like to stay\nthis month?'),
    'explore.all': ('Semua', 'All'),
    'explore.male': ('Putra', 'Male'),
    'explore.female': ('Putri', 'Female'),
    'explore.mixed': ('Campur', 'Mixed'),
    'explore.relevant': ('Paling relevan', 'Most relevant'),
    'explore.loadMore': ('Muat lebih banyak', 'Load more'),
    'explore.loading': ('Mencari kos terdekat untukmu…', 'Finding homes near you…'),
    'explore.emptyTitle': ('Belum ada kos yang cocok', 'No matching homes'),
    'explore.emptyDesc': ('Coba ubah kata kunci atau hapus beberapa filter.', 'Try another keyword or clear some filters.'),
    'explore.clearFilter': ('Hapus filter', 'Clear filters'),
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
    // Validasi form
    'val.nameRequired': ('Nama lengkap wajib diisi', 'Full name is required'),
    'val.nameMin': ('Nama lengkap minimal 2 karakter', 'Full name must be at least 2 characters'),
    'val.nameMax': ('Nama lengkap maksimal 100 karakter', 'Full name must be under 100 characters'),
    'val.emailRequired': ('Email wajib diisi', 'Email is required'),
    'val.emailMax': ('Email maksimal 150 karakter', 'Email must be under 150 characters'),
    'val.emailInvalid': ('Format email tidak valid', 'Invalid email format'),
    'val.passwordRequired': ('Password wajib diisi', 'Password is required'),
    'val.passwordMin': ('Password minimal 8 karakter', 'Password must be at least 8 characters'),
    'val.passwordMax': ('Password maksimal 72 karakter', 'Password must be under 72 characters'),
    'val.passwordLetter': ('Password minimal mengandung 1 huruf', 'Password needs at least 1 letter'),
    'val.passwordNumber': ('Password minimal mengandung 1 angka', 'Password needs at least 1 number'),
    'val.confirmRequired': ('Konfirmasi password wajib diisi', 'Confirm password is required'),
    'val.confirmMismatch': ('Konfirmasi password tidak sama', 'Passwords do not match'),
    'val.phoneChars': ('Hanya angka dan tanda plus, 8-20 karakter', 'Digits and plus sign only, 8-20 characters'),
    'val.phoneRequired': ('Nomor telepon wajib diisi', 'Phone number is required'),
    'val.phonePrefix': ('Awali dengan +62, contoh +6281234567890', 'Start with +62, e.g. +6281234567890'),
    'val.phoneInvalid': ('Nomor tidak valid, contoh +6281234567890', 'Invalid number, e.g. +6281234567890'),
    'val.required': ('{label} wajib diisi', '{label} is required'),
    'val.min': ('{label} minimal {min} karakter', '{label} must be at least {min} characters'),
    'val.max': ('{label} maksimal {max} karakter', '{label} must be under {max} characters'),
    'val.minSimple': ('{label} minimal {min}', '{label} must be at least {min}'),
    'val.maxSimple': ('{label} maksimal {max}', '{label} must be at most {max}'),
    'val.priceRequired': ('Harga wajib diisi', 'Price is required'),
    'val.pricePositive': ('Harga harus lebih dari 0', 'Price must be greater than 0'),
    'val.priceMax': ('Harga maksimal 100.000.000', 'Price must be under 100,000,000'),
    'val.coordinateNumber': ('{label} harus berupa angka', '{label} must be a number'),
    'val.coordinateRange': ('{label} harus di antara {min} dan {max}', '{label} must be between {min} and {max}'),
    'common.retry': ('Coba lagi', 'Retry'),
    'common.loading': ('Memuat…', 'Loading…'),
  };
}
