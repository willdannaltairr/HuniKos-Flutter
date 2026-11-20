# HuniKos Mobile (Flutter)

Aplikasi mobile **HuniKos** — client untuk REST API HUNIKOS (Node.js + Express + PostgreSQL).
Isi aplikasi mengikuti `docs/00_KONTRAK_BERSAMA.md` sebagai satu-satunya sumber kebenaran
nama field, enum, endpoint, dan format response.

## Isi aplikasi

| Peran | Layar |
|---|---|
| Publik / tamu | Explore (pencarian & filter), detail properti, detail kamar |
| Penyewa | Login, register, explore, detail kamar, form booking, booking saya, detail booking (unggah bukti transfer, batalkan), laporan kerusakan, profil |
| Pemilik | Dashboard, properti (tambah/ubah/hapus, foto, cover), kamar (tambah/ubah/hapus, fasilitas, status), booking masuk (setujui/tolak/selesaikan), verifikasi pembayaran, laporan kerusakan, profil |
| Admin | Dashboard statistik, verifikasi properti (setujui/tolak), kelola pengguna (aktif/nonaktif), profil |

## Menjalankan

Butuh Flutter stable (Dart 3) dan backend HuniKos yang menyala.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

- Emulator Android memakai `http://10.0.2.2:3001` untuk menjangkau komputer lokal.
- Perangkat fisik memakai IP LAN komputer, misal `http://192.168.1.10:3001`.
- Web / desktop boleh `http://localhost:3001`.
- Bila `API_BASE_URL` tidak diisi, default di `lib/core/config.dart` dipakai (localhost:3001
  atau 10.0.2.2:3001 untuk Android).

Backend dijalankan dari repo HuniKos-Backend:

```bash
cd api
npm install
npm start
```

Catatan: `image_url` dibentuk backend dari variabel `BASE_URL` miliknya. Agar gambar tampil di
emulator, jalankan backend dengan `BASE_URL` yang bisa dijangkau perangkat, misal
`BASE_URL=http://10.0.2.2:3001`.

## Build APK rilis

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<nama-app>.onrender.com
```

Build rilis tidak mengizinkan HTTP biasa; gunakan URL HTTPS (Render sudah menyediakannya).

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
| Unggah bukti transfer | `POST /api/bookings/:id/payments` |
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
| Pembayaran pemilik | `GET /api/owner/payments`, `PATCH /api/owner/payments/:id/verify` |
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
