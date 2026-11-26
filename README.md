# HuniKos Mobile (Flutter)

Aplikasi mobile **HuniKos** — client untuk REST API HUNIKOS (Node.js + Express + PostgreSQL).
Isi aplikasi mengikuti `docs/00_KONTRAK_BERSAMA.md` sebagai satu-satunya sumber kebenaran
nama field, enum, endpoint, dan format response.

## Isi aplikasi

| Peran | Layar |
|---|---|
| Tanpa akun | Hanya login dan register; halaman lain otomatis diarahkan ke login |
| Penyewa | Explore (pencarian & filter), detail properti, detail kamar, form booking, booking saya, detail booking (bayar via Midtrans, batalkan), laporan kerusakan, profil |
| Pemilik | Dashboard, properti (tambah/ubah/hapus, foto, cover), kamar (tambah/ubah/hapus, fasilitas, status), booking masuk (setujui/tolak/selesaikan), pantau status pembayaran Midtrans, laporan kerusakan, profil |
| Admin | Dashboard statistik, verifikasi properti (setujui/tolak), kelola pengguna (aktif/nonaktif), profil |

## Menjalankan

Butuh Flutter stable (Dart 3) dan backend HuniKos yang menyala.

```bash
flutter pub get
flutter run -d chrome
```

- Tanpa flag apa pun, aplikasi langsung memakai backend yang sudah online:
  `https://hunikosbackend.vercel.app` (lihat `lib/core/config.dart`).
- Ingin memakai backend lokal? Timpa alamatnya:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

- Emulator Android memakai `http://10.0.2.2:3000` untuk menjangkau komputer lokal.
- Perangkat fisik memakai IP LAN komputer, misal `http://192.168.1.10:3000`.
- Backend menerima origin `localhost`/`127.0.0.1` berapa pun portnya, jadi
  `flutter run -d chrome` yang memilih port acak tetap tersambung.

Backend dijalankan dari repo HuniKos-Backend:

```bash
npm install
npm run dev
```

Catatan: semua gambar disimpan di Cloudinary, jadi `image_url` yang dikirim backend sudah
berupa alamat HTTPS dan bisa langsung dimuat dari perangkat mana pun.

## Build APK rilis

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<nama-project>.vercel.app
```

Build rilis tidak mengizinkan HTTP biasa; gunakan URL HTTPS (Vercel sudah menyediakannya).

## Akun uji

| Peran | Email | Password |
|---|---|---|
| Admin | `admin@hunikos.test` | `Admin123!` |
| Pemilik | `owner1@hunikos.test`, `owner2@hunikos.test` | `Owner123!` |
| Penyewa | `tenant1@hunikos.test`, `tenant2@hunikos.test`, `tenant3@hunikos.test` | `Tenant123!` |

## Pemetaan layar ke endpoint

| Layar | Endpoint |
|---|---|
| Login | `POST /api/auth/login` |
| Register | `POST /api/auth/register` |
| Auto-login saat aplikasi dibuka | `GET /api/auth/me` |
| Explore | `GET /api/properties`, `GET /api/facilities` |
| Detail properti | `GET /api/properties/:id` |
| Detail kamar | `GET /api/rooms/:id` |
| Form booking | `POST /api/bookings` |
| Booking saya | `GET /api/bookings` |
| Detail booking | `GET /api/bookings/:id` |
| Bayar lewat Midtrans | `POST /api/bookings/:id/payments/midtrans` |
| Cek status pembayaran | `GET /api/bookings/:id/payments/midtrans/status` |
| Batalkan booking | `PATCH /api/bookings/:id/cancel` |
| Riwayat pembayaran penyewa | `GET /api/payments` |
| Buat laporan kerusakan | `POST /api/maintenance` (multipart) |
| Daftar laporan penyewa | `GET /api/maintenance` |
| Profil | `PUT /api/users/me`, `POST /api/users/me/avatar` |
| Dashboard pemilik | `GET /api/owner/dashboard` |
| Properti pemilik | `GET/POST /api/owner/properties`, `PUT/DELETE /api/owner/properties/:id` |
| Foto properti | `POST /api/owner/properties/:id/images`, `DELETE /api/owner/images/:imageId`, `PATCH /api/owner/images/:imageId/cover` |
| Kamar pemilik | `GET/POST /api/owner/properties/:id/rooms`, `PUT/DELETE /api/owner/rooms/:id` |
| Booking masuk | `GET /api/owner/bookings`, `PATCH /api/owner/bookings/:id/decision`, `PATCH /api/owner/bookings/:id/complete` |
| Pembayaran pemilik | `GET /api/owner/payments` (status ditulis otomatis oleh webhook Midtrans) |
| Laporan kerusakan pemilik | `GET /api/owner/maintenance`, `PATCH /api/owner/maintenance/:id` |
| Dashboard admin | `GET /api/admin/dashboard` |
| Verifikasi properti | `GET /api/admin/properties`, `PATCH /api/admin/properties/:id/verification` |
| Kelola pengguna | `GET /api/admin/users`, `PATCH /api/admin/users/:id/status` |

## Struktur

```
lib/
├─ main.dart / app.dart       # bootstrap, provider, MaterialApp.router
├─ core/                      # config, ApiClient, router, tema, validator, formatter
├─ models/                    # fromJson manual sesuai kontrak bagian 8
├─ services/                  # satu file per kelompok endpoint
├─ providers/                 # ChangeNotifier per area
├─ screens/                   # auth, tenant, owner, admin, shared
└─ widgets/                   # widget bersama (status chip, kartu, dialog, dsb.)
```

## Pengujian

```bash
flutter analyze   # harus bersih
flutter test      # model, validator, dan formatter
```

## Kredit aset

Foto latar halaman login dan register: Photo by Max Vakhtbovych on Pexels
(`assets/images/auth_header.jpg`), dipakai sesuai lisensi Pexels.
