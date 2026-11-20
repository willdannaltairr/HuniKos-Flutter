# 00 — KONTRAK BERSAMA HUNIKOS (API + DATABASE)

> Lampirkan file ini di awal SETIAP chat sebelum menempelkan prompt 01–05.
> File ini adalah satu-satunya sumber kebenaran untuk nama tabel, kolom, status, endpoint, dan format response.
> Kalau ada prompt yang bertentangan dengan file ini, file ini yang menang.

---

## 1. Keputusan teknis (sudah final)

| Hal | Keputusan | Alasan singkat |
|---|---|---|
| Database | **PostgreSQL 16+ di Aiven (free plan)** | Aiven sudah menutup pembuatan MySQL gratis baru sejak 6 Nov 2026; soal SRS mewajibkan database di Aiven; soal KOKE membolehkan MySQL atau PostgreSQL |
| Akses database | `pg` (node-postgres), SQL langsung, **tanpa ORM** | Mudah dijelaskan ke penguji |
| Migrasi | `node-pg-migrate` dengan file `.sql` | File SQL/migration wajib ada di soal KOKE |
| Backend | Node.js 20+ (LTS), **Express 5**, JavaScript ESM (`"type": "module"`) | Lebih sederhana dari TypeScript; async error otomatis diteruskan ke error handler di Express 5 |
| Validasi | `zod@3` | Skema pendek, pesan error jelas |
| Auth | JWT (HS256) + `bcryptjs` | Password wajib di-hash |
| Upload | `multer` (memory storage) → driver `local` (dev) atau `cloudinary` (produksi) | Disk gratis di hosting biasanya sementara |
| Mobile | Flutter (stable terbaru), Provider, Dio, go_router | Soal KOKE mewajibkan Flutter |
| Hosting backend | Render (free web service) | Gratis, tanpa kartu kredit, cocok untuk Express |
| Hosting web | Vercel (website Next.js sudah ada) | Sesuai soal SRS |

Bagian yang TIDAK masuk MVP (jangan dibuat): kontrak digital, invoice, payment gateway (Midtrans), Google Maps, email (Resend), Sentry, KosMatch, TrueCost, CampusRoute, KosVisit, Room Passport, review, chat, notifikasi, audit log.
Pembayaran diganti **upload bukti transfer yang diverifikasi pemilik**.

---

## 2. Role

Hanya **tiga role** di database: `tenant` (penyewa), `owner` (pemilik), `admin`.
"Guest" bukan role; guest adalah pengunjung yang belum login dan hanya boleh membaca data publik.
Register hanya boleh untuk `tenant` dan `owner`. Akun `admin` hanya dibuat lewat seed.

| Aksi | Guest | Tenant | Owner | Admin |
|---|:-:|:-:|:-:|:-:|
| Lihat daftar & detail kos yang sudah `approved`, detail kamar | ✔ | ✔ | ✔ | ✔ |
| Buat booking, upload bukti bayar, batalkan booking, lapor kerusakan | ✘ | ✔ | ✘ | ✘ |
| Kelola properti & kamar milik sendiri, upload foto | ✘ | ✘ | ✔ | ✘ |
| Setujui/tolak booking, verifikasi pembayaran, ubah status perbaikan | ✘ | ✘ | ✔ (milik sendiri) | ✘ |
| Verifikasi properti, kelola status akun pengguna, lihat statistik platform | ✘ | ✘ | ✘ | ✔ |
| Edit profil sendiri | ✘ | ✔ | ✔ | ✔ |

---

## 3. Nilai enum (tulis persis, huruf besar/kecil berpengaruh)

| Kolom | Nilai |
|---|---|
| `users.role` | `tenant`, `owner`, `admin` |
| `users.account_status` | `active`, `suspended` |
| `properties.property_type` | `putra`, `putri`, `campur` |
| `properties.verification_status` | `pending`, `approved`, `rejected` |
| `rooms.bathroom_type` | `dalam`, `luar` |
| `rooms.status` | `AVAILABLE`, `RESERVED`, `OCCUPIED`, `MAINTENANCE`, `INACTIVE` |
| `bookings.status` | `PENDING`, `AWAITING_PAYMENT`, `CONFIRMED`, `REJECTED`, `CANCELLED`, `EXPIRED`, `COMPLETED` |
| `payments.status` | `PENDING`, `VERIFIED`, `REJECTED` |
| `maintenance_requests.status` | `OPEN`, `IN_PROGRESS`, `DONE` |

---

## 4. Skema database (DDL PostgreSQL — sumber kebenaran)

```sql
-- 1. users
CREATE TABLE users (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name      VARCHAR(100) NOT NULL,
  email          VARCHAR(150) NOT NULL UNIQUE,          -- selalu disimpan lowercase oleh aplikasi
  password_hash  VARCHAR(255) NOT NULL,
  phone_number   VARCHAR(20),
  avatar_url     TEXT,
  role           VARCHAR(10) NOT NULL CHECK (role IN ('tenant','owner','admin')),
  account_status VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active','suspended')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. properties
CREATE TABLE properties (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id            UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  name                VARCHAR(120) NOT NULL,
  description         TEXT,
  address             TEXT NOT NULL,
  city                VARCHAR(80) NOT NULL,
  latitude            NUMERIC(9,6),
  longitude           NUMERIC(9,6),
  property_type       VARCHAR(10) NOT NULL CHECK (property_type IN ('putra','putri','campur')),
  rules               TEXT,
  verification_status VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending','approved','rejected')),
  rejection_note      TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. rooms
CREATE TABLE rooms (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  room_number   VARCHAR(20) NOT NULL,
  room_type     VARCHAR(50) NOT NULL DEFAULT 'standard',
  dimensions    VARCHAR(20),                              -- contoh: '3x4 m'
  monthly_price NUMERIC(14,2) NOT NULL CHECK (monthly_price > 0),
  max_occupants SMALLINT NOT NULL DEFAULT 1 CHECK (max_occupants BETWEEN 1 AND 10),
  bathroom_type VARCHAR(10) NOT NULL CHECK (bathroom_type IN ('dalam','luar')),
  floor_number  SMALLINT NOT NULL DEFAULT 1 CHECK (floor_number BETWEEN 1 AND 50),
  status        VARCHAR(12) NOT NULL DEFAULT 'AVAILABLE'
                CHECK (status IN ('AVAILABLE','RESERVED','OCCUPIED','MAINTENANCE','INACTIVE')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (property_id, room_number)
);

-- 4. facilities (data master, diisi lewat seed)
CREATE TABLE facilities (
  id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(60) NOT NULL UNIQUE
);

-- 5. room_facilities (relasi banyak-ke-banyak)
CREATE TABLE room_facilities (
  room_id     UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  facility_id UUID NOT NULL REFERENCES facilities(id) ON DELETE RESTRICT,
  PRIMARY KEY (room_id, facility_id)
);

-- 6. property_images (foto properti; kalau room_id terisi berarti foto kamar)
CREATE TABLE property_images (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  room_id     UUID REFERENCES rooms(id) ON DELETE CASCADE,
  image_url   TEXT NOT NULL,
  storage_key TEXT NOT NULL,                              -- path lokal atau public_id Cloudinary
  is_cover    BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. bookings
CREATE TABLE bookings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_code          VARCHAR(20) NOT NULL UNIQUE,      -- 'BK-' + 8 hex huruf besar
  tenant_id             UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  room_id               UUID NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
  start_date            DATE NOT NULL,
  duration_months       SMALLINT NOT NULL CHECK (duration_months BETWEEN 1 AND 24),
  end_date              DATE NOT NULL,                    -- start_date + duration_months bulan (end eksklusif)
  rental_price_snapshot NUMERIC(14,2) NOT NULL,           -- harga per bulan saat booking dibuat
  total_amount          NUMERIC(14,2) NOT NULL,           -- rental_price_snapshot * duration_months
  status                VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING','AWAITING_PAYMENT','CONFIRMED','REJECTED','CANCELLED','EXPIRED','COMPLETED')),
  note                  TEXT,                             -- catatan penyewa
  owner_note            TEXT,                             -- catatan pemilik
  expires_at            TIMESTAMPTZ,                      -- diisi saat status AWAITING_PAYMENT (sekarang + 24 jam)
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date > start_date)
);

-- 8. booking_status_histories
CREATE TABLE booking_status_histories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id  UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  from_status VARCHAR(20),
  to_status   VARCHAR(20) NOT NULL,
  changed_by  UUID REFERENCES users(id) ON DELETE SET NULL,  -- NULL berarti sistem (misal EXPIRED otomatis)
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. payments (bukti transfer)
CREATE TABLE payments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id  UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
  amount      NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  proof_url   TEXT NOT NULL,
  storage_key TEXT NOT NULL,
  status      VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','VERIFIED','REJECTED')),
  verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 10. maintenance_requests (laporan kerusakan)
CREATE TABLE maintenance_requests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id  UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
  room_id     UUID NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
  tenant_id   UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  title       VARCHAR(120) NOT NULL,
  description TEXT NOT NULL,
  photo_url   TEXT,
  storage_key TEXT,
  status      VARCHAR(12) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','IN_PROGRESS','DONE')),
  owner_note  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Relasi utama: `users 1—N properties 1—N rooms`, `rooms N—N facilities` (lewat `room_facilities`), `users 1—N bookings N—1 rooms`, `bookings 1—N payments`, `bookings 1—N booking_status_histories`, `bookings 1—N maintenance_requests`, `properties 1—N property_images`.

Index minimal yang harus dibuat: `properties(owner_id)`, `properties(verification_status, city)`, `rooms(property_id)`, `rooms(status)`, `rooms(monthly_price)`, `bookings(room_id, status)`, `bookings(tenant_id)`, `payments(booking_id)`, `maintenance_requests(room_id)`, `property_images(property_id)`.

Akibat `ON DELETE RESTRICT` pada booking: properti atau kamar yang pernah punya booking tidak bisa dihapus. Error Postgres yang muncul saat menghapus data yang masih dirujuk adalah **`23001`** (`restrict_violation`; sudah diuji, ini kode untuk `ON DELETE RESTRICT`), sedangkan `23503` (`foreign_key_violation`) muncul saat meng-insert dengan referensi yang tidak ada. Backend harus menerjemahkan **keduanya** menjadi HTTP 409 (untuk `23503` pada insert, lebih baik dicek dulu di service dan dijawab 404/422).

---

## 5. Aturan bisnis booking (state machine)

Booking dianggap **aktif** jika statusnya `PENDING`, `AWAITING_PAYMENT`, atau `CONFIRMED`.
Rentang sewa memakai konvensi `[start_date, end_date)`. Dua booking bentrok jika `a.start_date < b.end_date AND a.end_date > b.start_date`.

| Dari | Aksi | Oleh | Ke | Efek samping |
|---|---|---|---|---|
| (baru) | buat booking | tenant | `PENDING` | cek bentrok dalam transaksi dengan `SELECT ... FOR UPDATE` pada baris kamar; isi `rental_price_snapshot`, `total_amount`, `end_date`; catat history |
| `PENDING` | setujui | owner | `AWAITING_PAYMENT` | `expires_at = now() + 24 jam`; kamar → `RESERVED` |
| `PENDING` | tolak | owner | `REJECTED` | |
| `PENDING` / `AWAITING_PAYMENT` | batalkan | tenant | `CANCELLED` | kamar kembali `AVAILABLE` bila tidak ada booking aktif lain |
| `AWAITING_PAYMENT` | `expires_at` lewat | sistem | `EXPIRED` | kamar kembali `AVAILABLE` bila tidak ada booking aktif lain |
| `AWAITING_PAYMENT` | pembayaran diverifikasi (approve) | owner | `CONFIRMED` | kamar → `OCCUPIED`; payment → `VERIFIED` |
| `CONFIRMED` | selesaikan | owner | `COMPLETED` | kamar kembali `AVAILABLE` bila tidak ada booking aktif lain |

Catatan penting:
- **Kedaluwarsa dihitung secara lazy**, tanpa cron (hosting gratis bisa tidur). Sebelum setiap query booking, jalankan fungsi `expireStaleBookings()` yang mengubah `AWAITING_PAYMENT` yang `expires_at < now()` menjadi `EXPIRED`, mencatat history (`changed_by = NULL`), dan mereset status kamar.
- Status kamar `RESERVED` dan `OCCUPIED` hanya boleh diubah oleh sistem. Pemilik hanya boleh mengubah manual ke `AVAILABLE`, `MAINTENANCE`, atau `INACTIVE`, dan hanya jika tidak ada booking aktif pada kamar itu.
- Penolakan pembayaran (`REJECTED`) tidak mengubah status booking; penyewa boleh upload bukti baru selama booking masih `AWAITING_PAYMENT`.
- Pembatasan: tidak boleh ada payment `PENDING` ganda untuk satu booking.
- "Hari ini" selalu dihitung zona waktu Asia/Jakarta: `(now() AT TIME ZONE 'Asia/Jakarta')::date`.

---

## 6. Konvensi API

- Base path: `/api`. Format JSON, nama field **snake_case**.
- Auth: header `Authorization: Bearer <token>`. Payload JWT: `{ sub: <user.id>, role }`. Middleware tetap membaca user dari database di setiap request agar akun `suspended` langsung ditolak (403).
- ID: UUID string. Uang: **angka** (number), bukan string. Tanggal sewa: string `YYYY-MM-DD`. Waktu: ISO 8601.
- Konfigurasi `pg` wajib: tipe `NUMERIC` (OID 1700) di-parse ke `Number`, `DATE` (OID 1082) dibiarkan string, `INT8`/`COUNT` (OID 20) di-parse ke `Number`.
- Semua response memakai amplop yang sama (termasuk DELETE, tanpa HTTP 204):

```json
// sukses
{ "success": true, "message": "Booking berhasil dibuat", "data": { } }
// sukses dengan paginasi
{ "success": true, "message": "OK", "data": [ ], "meta": { "page": 1, "limit": 10, "total": 42, "total_pages": 5 } }
// gagal
{ "success": false, "message": "Data tidak valid", "errors": [ { "field": "email", "message": "Format email tidak valid" } ] }
```

`errors` hanya muncul pada kode 422.

| HTTP | Dipakai untuk |
|---|---|
| 200 | berhasil (GET, PUT, PATCH, DELETE) |
| 201 | berhasil membuat data (POST) |
| 400 | JSON rusak / parameter tidak masuk akal |
| 401 | token tidak ada, salah, atau kedaluwarsa; email/password salah |
| 403 | role tidak sesuai, akun `suspended`, atau bukan pemilik resource |
| 404 | data tidak ditemukan (juga dipakai untuk resource milik orang lain yang tidak boleh diketahui keberadaannya) |
| 409 | bentrok: booking bentrok, email sudah dipakai, status tidak boleh berpindah, data masih dipakai |
| 413 | file melebihi 2 MB |
| 415 | tipe file bukan jpg/png/webp |
| 422 | validasi input gagal |
| 429 | terlalu banyak percobaan login |
| 500 | error server (pesan generik, detail hanya di log) |

- Paginasi: query `page` (default 1) dan `limit` (default 10, maksimum 50). **Hanya** `GET /api/properties` dan `GET /api/admin/users` yang berpaginasi; endpoint list lain mengembalikan array biasa.
- Upload: field `images` (maks 5 file per request), `proof`, `photo`, `avatar`. Tipe `image/jpeg`, `image/png`, `image/webp`; ukuran maks 2 MB per file.

---

## 7. Aturan validasi (dipakai di backend dan di form Flutter)

| Data | Aturan |
|---|---|
| `full_name` | 2–100 karakter |
| `email` | format email valid, maks 150, disimpan lowercase |
| `password` | 8–72 karakter, minimal 1 huruf dan 1 angka |
| `phone_number` | opsional, regex `^[0-9+]{8,20}$` |
| `role` (register) | hanya `tenant` atau `owner` |
| Properti | `name` 3–120; `address` 5–500; `city` 2–80; `property_type` enum; `description` dan `rules` maks 2000; `latitude` −90..90 dan `longitude` −180..180 (opsional, keduanya harus diisi bersamaan) |
| Kamar | `room_number` 1–20; `room_type` 1–50; `dimensions` maks 20; `monthly_price` angka > 0 dan ≤ 100.000.000; `max_occupants` 1–10; `bathroom_type` enum; `floor_number` 1–50; `facility_ids` array UUID (opsional) |
| Booking | `room_id` UUID; `start_date` `YYYY-MM-DD` dan tidak boleh sebelum hari ini (WIB); `duration_months` bilangan bulat 1–24; `note` maks 300 |
| Laporan kerusakan | `booking_id` UUID; `title` 3–120; `description` 5–1000 |
| Catatan keputusan | `owner_note` / `note` maks 300; **wajib** (min 3 karakter) saat admin menolak properti dan saat pemilik menolak pembayaran |

---

## 8. Bentuk objek response

```
User            { id, full_name, email, phone_number, avatar_url, role, account_status, created_at }
Facility        { id, name }
Image           { id, image_url, room_id|null, is_cover }
PropertyItem    { id, name, city, address, property_type, cover_image_url|null, min_price|null, available_rooms, total_rooms }
PropertyDetail  { id, name, description, address, city, latitude|null, longitude|null, property_type, rules,
                  verification_status, rejection_note (hanya dikirim ke pemilik & admin; selain itu null),
                  owner:{ id, full_name, phone_number }, images:[Image], rooms:[RoomItem], created_at }
RoomItem        { id, property_id, room_number, room_type, dimensions, monthly_price, max_occupants,
                  bathroom_type, floor_number, status, facilities:[Facility], cover_image_url|null }
RoomDetail      RoomItem + { property:{ id, name, city, address }, images:[Image],
                  unavailable_ranges:[ { start_date, end_date } ] }     // dari booking aktif, tanpa data penyewa
Booking         { id, booking_code, status, start_date, end_date, duration_months, rental_price_snapshot,
                  total_amount, note, owner_note, expires_at|null, created_at,
                  room:{ id, room_number, room_type }, property:{ id, name, city },
                  tenant:{ id, full_name, phone_number }, latest_payment_status|null }
BookingDetail   Booking + { payments:[Payment], history:[ { from_status, to_status, note, created_at } ] }
Payment         { id, booking_id, amount, proof_url, status, note, verified_at|null, created_at,
                  booking_code, room_number, property_name, tenant_name }
Maintenance     { id, booking_id, room_id, title, description, photo_url|null, status, owner_note|null,
                  created_at, updated_at, room_number, property_name, tenant_name }
```

`min_price` = harga terendah kamar yang statusnya bukan `INACTIVE`. `available_rooms` = jumlah kamar berstatus `AVAILABLE`. `total_rooms` = jumlah kamar yang bukan `INACTIVE`.
`cover_image_url` = gambar dengan `is_cover = true`, kalau tidak ada pakai gambar pertama (berdasarkan `created_at`), kalau tidak ada gambar maka `null`.

---

## 9. Daftar endpoint (final)

### Auth & profil
| Method | Path | Akses | Body / query | Sukses |
|---|---|---|---|---|
| POST | `/api/auth/register` | publik | `full_name, email, password, phone_number?, role` | 201 `{ user, token }` |
| POST | `/api/auth/login` | publik | `email, password` | 200 `{ user, token }` (401 jika salah, 403 jika suspended) |
| GET | `/api/auth/me` | login | – | 200 `User` |
| PUT | `/api/users/me` | login | `full_name, phone_number?` | 200 `User` |
| POST | `/api/users/me/avatar` | login | multipart `avatar` | 200 `User` |
| GET | `/api/health` | publik | – | 200 `{ status: "ok" }` (cek `SELECT 1`) |

### Publik (login opsional)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/facilities` | array `Facility`, urut nama |
| GET | `/api/properties` | hanya `approved`. Query: `q` (nama/alamat/kota), `city`, `type`, `min_price`, `max_price`, `facility_ids` (dipisah koma, kamar harus punya SEMUA fasilitas), `available_only=true`, `sort` (`newest`\|`price_asc`\|`price_desc`), `page`, `limit`. Response `PropertyItem[]` + `meta` |
| GET | `/api/properties/:id` | `PropertyDetail`. Properti non-approved hanya terlihat oleh pemiliknya dan admin; selain itu 404. Kamar `INACTIVE` tidak ditampilkan ke publik |
| GET | `/api/rooms/:id` | `RoomDetail`. Hanya jika propertinya approved (atau pemilik/admin) |

### Penyewa (role `tenant`)
| Method | Path | Keterangan |
|---|---|---|
| POST | `/api/bookings` | body `room_id, start_date, duration_months, note?` → 201 `Booking`. Error: 404 kamar tidak ada/properti belum approved, 409 bentrok atau kamar `MAINTENANCE/INACTIVE`, 422 validasi |
| GET | `/api/bookings` | booking milik sendiri, query `status?`, urut terbaru. `Booking[]` |
| GET | `/api/bookings/:id` | `BookingDetail`; boleh dibaca penyewanya, pemilik kamar, dan admin |
| PATCH | `/api/bookings/:id/cancel` | dari `PENDING`/`AWAITING_PAYMENT` → `CANCELLED`, selain itu 409 |
| POST | `/api/bookings/:id/payments` | multipart `proof`; booking harus milik sendiri & `AWAITING_PAYMENT`; `amount` diambil dari `total_amount` (bukan dari client); 409 jika masih ada payment `PENDING` → 201 `Payment` |
| GET | `/api/payments` | pembayaran milik sendiri, `Payment[]` |
| POST | `/api/maintenance` | multipart `booking_id, title, description, photo?`; booking milik sendiri & `CONFIRMED` → 201 `Maintenance` |
| GET | `/api/maintenance` | laporan milik sendiri, `Maintenance[]` |

### Pemilik (role `owner`, semua hanya untuk data miliknya)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/owner/dashboard` | `{ total_properties, approved_properties, total_rooms, available_rooms, occupied_rooms, pending_bookings, pending_payments, open_maintenance, revenue_this_month, occupancy_rate }`. `revenue_this_month` = jumlah `payments.amount` berstatus `VERIFIED` yang `verified_at`-nya di bulan berjalan (WIB). `occupancy_rate` = `occupied_rooms / total_rooms × 100` (1 desimal, 0 bila tidak ada kamar) |
| GET | `/api/owner/properties` | `PropertyItem[]` semua status + field `verification_status` dan `rejection_note` |
| POST | `/api/owner/properties` | 201, status awal `pending` |
| PUT | `/api/owner/properties/:id` | jika sebelumnya `rejected` maka kembali `pending` dan `rejection_note` dikosongkan |
| DELETE | `/api/owner/properties/:id` | 409 jika ada kamar dengan riwayat booking |
| POST | `/api/owner/properties/:id/images` | multipart `images` (maks 5), opsional field teks `room_id` (harus kamar di properti itu). Gambar pertama properti otomatis `is_cover` bila belum ada cover |
| DELETE | `/api/owner/images/:imageId` | hapus baris + file |
| PATCH | `/api/owner/images/:imageId/cover` | jadikan cover (cover lain pada properti yang sama menjadi false) |
| GET | `/api/owner/properties/:propertyId/rooms` | `RoomItem[]` termasuk `INACTIVE` |
| POST | `/api/owner/properties/:propertyId/rooms` | body `room_number, room_type, dimensions?, monthly_price, max_occupants, bathroom_type, floor_number, facility_ids?` → 201. 409 jika `room_number` kembar |
| PUT | `/api/owner/rooms/:id` | field yang sama + `status?` (hanya `AVAILABLE`/`MAINTENANCE`/`INACTIVE`, dan hanya bila tidak ada booking aktif); `facility_ids` mengganti seluruh daftar |
| DELETE | `/api/owner/rooms/:id` | 409 jika ada riwayat booking |
| GET | `/api/owner/bookings` | query `status?`; `Booking[]` untuk semua kamar milik pemilik |
| PATCH | `/api/owner/bookings/:id/decision` | body `{ action: "approve"\|"reject", owner_note? }`; hanya dari `PENDING` |
| PATCH | `/api/owner/bookings/:id/complete` | hanya dari `CONFIRMED` |
| GET | `/api/owner/payments` | query `status?`; `Payment[]` |
| PATCH | `/api/owner/payments/:id/verify` | body `{ action: "approve"\|"reject", note? }`; hanya payment `PENDING`. Approve butuh booking masih `AWAITING_PAYMENT` dan belum lewat `expires_at`, jika tidak 409. Seluruh langkah dalam satu transaksi |
| GET | `/api/owner/maintenance` | query `status?`; `Maintenance[]` |
| PATCH | `/api/owner/maintenance/:id` | body `{ status, owner_note? }` |

### Admin (role `admin`)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/admin/dashboard` | `{ total_users, total_tenants, total_owners, total_properties, pending_properties, active_bookings }` (`active_bookings` = jumlah `CONFIRMED`) |
| GET | `/api/admin/users` | query `role?`, `account_status?`, `q?` (nama/email), `page`, `limit` → `User[]` + `meta` |
| PATCH | `/api/admin/users/:id/status` | body `{ account_status }`; admin tidak boleh mengubah akun admin (termasuk dirinya) → 403 |
| GET | `/api/admin/properties` | query `verification_status?` (default `pending`) → `PropertyItem[]` + `verification_status`, `rejection_note`, dan `owner:{ id, full_name }` |
| PATCH | `/api/admin/properties/:id/verification` | body `{ action: "approve"\|"reject", note? }`; `note` wajib saat reject |

---

## 10. Akun uji (wajib ada di seed, sesuai soal KOKE)

| Role | Email | Password |
|---|---|---|
| admin | `admin@hunikos.test` | `Admin123!` |
| owner | `owner1@hunikos.test`, `owner2@hunikos.test` | `Owner123!` |
| tenant | `tenant1@hunikos.test`, `tenant2@hunikos.test`, `tenant3@hunikos.test` | `Tenant123!` |

Password di-hash di skrip seed memakai `bcryptjs`, jangan simpan hash hasil karangan di file SQL. Ganti atau hapus akun ini setelah ujian selesai.

---

## 11. Variabel environment backend

| Nama | Contoh / keterangan |
|---|---|
| `PORT` | `3000` |
| `NODE_ENV` | `development` / `production` |
| `DATABASE_URL` | URI dari Aiven **tanpa** parameter `?sslmode=...` (SSL diatur lewat kode) |
| `DB_CA_CERT` | isi file `ca.pem` dari Aiven; jika berisi `\n` literal, kode harus menggantinya menjadi baris baru |
| `DB_POOL_MAX` | `5` (free plan Aiven membatasi 20 koneksi) |
| `JWT_SECRET` | string acak minimal 32 karakter |
| `JWT_EXPIRES_IN` | `7d` |
| `CORS_ORIGINS` | daftar origin dipisah koma (domain Vercel + `http://localhost:3000`) |
| `BASE_URL` | URL publik backend, dipakai membentuk `image_url` driver lokal |
| `STORAGE_DRIVER` | `local` atau `cloudinary` |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | hanya bila `STORAGE_DRIVER=cloudinary` |

---

## 12. Aturan kerja untuk AI (berlaku di semua prompt)

1. Jangan menambah tabel, kolom, endpoint, status, atau fitur di luar file ini. Kalau menurutmu ada yang kurang atau salah, **berhenti dan laporkan**, jangan diam-diam mengubah.
2. Jangan mengarang data, angka riset, atau hasil pengujian. Bagian yang butuh data lapangan diberi tanda `[ISI SENDIRI: ...]`.
3. Gaya kode "manusiawi": nama variabel jelas, komentar singkat bahasa Indonesia hanya pada bagian yang tidak langsung jelas, tanpa abstraksi berlebihan, satu file satu tanggung jawab, usahakan di bawah ±150 baris per file, supaya pelajar bisa menjelaskan semuanya ke penguji.
4. Gaya tulisan "manusiawi": bahasa Indonesia baku yang natural, kalimat bervariasi, hindari pembuka klise ("Di era digital yang berkembang pesat…") dan frasa generik.
5. Di akhir, buat daftar periksa: apa saja yang sudah dicocokkan dengan kontrak ini, apa yang belum, dan apa yang sengaja berbeda beserta alasannya.