# Alur Git HUNIKOS (panduan lengkap)

Panduan singkat yang berlaku otomatis ada di `AGENTS.md`. File ini versi panjangnya: alasan tiap
aturan, perintah yang bisa disalin, dan tutorial menerima pull request di GitHub.

## 1. Gambaran besar

```
main      ●──────────────●─────────────●        rilis stabil, hanya lewat PR dari develop
           \            /               \
develop     ●──●──●──●──●──●──●──●───────●       tempat fitur yang sudah fix berkumpul
               \      /      \      /
feature/*       ●────●        ●────●             pekerjaan harian, satu fitur satu branch
```

Tiga aturan yang menopang semuanya:

1. **`main` tidak pernah menerima commit langsung.** Isinya hanya hasil merge PR dari `develop`,
   dan PR itu dibuat setelah `develop` dinyatakan fix olehmu.
2. **`develop` tidak pernah menerima commit langsung.** Isinya hanya hasil merge PR dari
   `feature/*`.
3. **Semua pekerjaan terjadi di `feature/*`.** Kalau sebuah pekerjaan belum selesai, branch
   fiturnya tetap hidup dan belum masuk `develop`.

## 2. Branch

| Branch | Dibuat dari | Di-merge ke | Boleh commit langsung |
|---|---|---|---|
| `main` | – | – | tidak |
| `develop` | `main` (sekali saja) | `main` | tidak |
| `feature/<area>-<nama>` | `develop` | `develop` | ya |

- Nama: huruf kecil, kebab-case, diawali area — `db`, `api`, `mobile`, `web`, `docs`, `deploy`.
- Contoh: `feature/db-schema`, `feature/api-auth`, `feature/api-bookings`,
  `feature/api-owner-management`, `feature/mobile-tenant`, `feature/docs-srs`.
- Satu fitur = satu branch. Dua fitur yang dikerjakan bersamaan = dua branch.
- **Branch fitur tidak dihapus setelah merge.** Branch itu tetap ada supaya kalau fiturnya perlu
  diubah lagi, riwayatnya tidak hilang.

## 3. Mulai bekerja: perintah yang dipakai setiap kali

```bash
# 1. pastikan develop terbaru
git switch develop
git pull origin develop

# 2. buat branch fitur baru
git switch -c feature/api-auth

# 3. kerjakan, lalu commit per langkah (lihat bagian 4)
git add src/modules/auth/auth.schema.js
git commit -m "feat(api): add login and register validation schemas"

# 4. kirim branch ke GitHub (push pertama memberi --set-upstream)
git push -u origin feature/api-auth
```

Kalau branch fiturnya sudah ada dan kamu lanjut bekerja di hari lain:

```bash
git switch feature/api-auth
git pull origin feature/api-auth
```

Sebelum membuat PR, selaraskan dulu dengan `develop` supaya tidak ada konflik di GitHub:

```bash
git fetch origin
git merge origin/develop
# jika muncul konflik: perbaiki file, lalu
git add <file-yang-konflik>
git commit          # pesan merge bawaan boleh dipakai
git push
```

## 4. Commit: satu langkah = satu commit

Format (Conventional Commits 1.0.0):

```text
<type>(<scope>): <subject>

<body opsional — jelaskan KENAPA, bungkus ±72 karakter>

<footer opsional — Refs #12>
```

Contoh nyata:

```text
feat(api): add booking creation endpoint

Lock the room row in a transaction so two tenants cannot book the same
period at once. End date is computed in SQL with make_interval.

Refs #14
```

### Yang wajib dipecah per commit

| Pekerjaan | Contoh commit |
|---|---|
| file baru | `feat(db): add init schema migration` |
| file dihapus | `refactor(api): remove unused asyncHandler wrapper` |
| folder/modul baru | `feat(api): scaffold owner module folders` |
| satu endpoint | `feat(api): add owner booking decision endpoint` |
| satu migration | `feat(db): add booking overlap exclusion constraint` |
| satu dokumen | `docs(db): add erd and data dictionary` |
| konfigurasi | `build(api): add express and pg dependencies` |

Aturan praktis:

- **Jangan** menumpuk semuanya di satu commit `feat: initial commit`.
- **Jangan** memakai `git add -A` kalau working tree berisi lebih dari satu langkah; pakai
  `git add <path>` atau `git add -p` untuk memilih potongan yang masuk.
- **Jangan** commit `.env`, key, `ca.pem`, `node_modules/`, `uploads/`, file hasil generate.
- Subject bahasa Inggris, mood perintah (`add`, `fix`, `remove`), huruf kecil, tanpa titik akhir,
  maksimal 72 karakter.
- Perubahan yang merusak kompatibilitas: `feat(api)!: ...` plus footer `BREAKING CHANGE: ...`.

Menulis karena terlanjur salah commit?

```bash
git commit --amend            # commit terakhir, belum di-push
git reset --soft HEAD~1       # batalkan commit terakhir, perubahannya tetap ada
```

## 5. Issue

Setiap pekerjaan dimulai dari issue di GitHub: **Issues → New issue**, lalu pilih template.

| Template | Dipakai untuk | Label |
|---|---|---|
| `Fitur` | menambah fitur/endpoint/layar | `enhancement` |
| `Bug` | perilaku yang tidak sesuai kontrak | `bug` |
| `Tugas` | dokumentasi, konfigurasi, pekerjaan kecil | `documentation` |

Judul memakai awalan area: `[db]`, `[api]`, `[mobile]`, `[web]`, `[docs]`, `[deploy]`.
Contoh: `[api] endpoint booking penyewa`.

Hubungan issue dengan branch dan PR:

- Sebutkan nama branch fitur di issue, lalu di setiap commit tambahkan `Refs #<nomor>`.
- Di deskripsi PR tulis `Closes #<nomor>` supaya issue tertutup otomatis saat PR di-merge.

## 6. Pull request

Buat PR dari `feature/*` ke `develop`:

```bash
git push -u origin feature/api-auth
gh pr create --base develop --head feature/api-auth --fill
```

Atau lewat web: setelah push, GitHub menampilkan tombol **Compare & pull request** di halaman repo.

Isi PR memakai `.github/pull_request_template.md` (otomatis muncul di web; `--fill` mengisinya
dari judul commit):

- judul format Conventional Commits, contoh `feat(api): add booking endpoints`;
- `Closes #12`;
- daftar perubahan utama;
- cara menguji dan **hasil pengujian yang sebenarnya** — bila belum diuji, tulis "belum diuji"
  beserta alasannya;
- checklist dicentang hanya kalau benar.

Branch fitur boleh tetap hidup setelah PR di-merge; PR-nya tetap tercatat di riwayat.

## 7. Tutorial: menerima PR di GitHub

Yang di-merge selalu kamu sendiri, lewat GitHub. Agen tidak pernah merge.

### 7.1 PR fitur → `develop`

1. Buka repo di GitHub → tab **Pull requests**.
2. Klik PR yang akan diterima. Baca tab **Conversation** dan **Files changed**.
3. Pastikan:
   - base branch di kiri tertulis **`develop`** dan compare branch di kanan **`feature/...`**;
   - tidak ada rahasia (`ca.pem`, `.env`, key) di `Files changed`;
   - tidak ada `node_modules/` atau `uploads/`;
   - hasil pengujian di deskripsi sudah diisi.
4. Kalau ada yang perlu diperbaiki, tulis komentar (atau **Request changes**), lalu perbaiki di
   branch fitur:
   ```bash
   git switch feature/api-auth
   # perbaiki, commit, lalu
   git push
   ```
   PR ikut diperbarui otomatis.
5. Kalau tulisan **"This branch has conflicts that must be resolved"** muncul:
   ```bash
   git switch feature/api-auth
   git fetch origin
   git merge origin/develop
   # selesaikan konflik, lalu
   git add <file>
   git commit
   git push
   ```
   Tombol hijau akan aktif kembali.
6. Setelah semuanya hijau, klik tombol panah di samping **Merge pull request** → pilih
   **Create a merge commit** (jangan "Squash and merge" — riwayat commit per langkah harus
   terlihat). Klik **Merge pull request**, lalu **Confirm merge**.
7. **Jangan** klik **Delete branch**. Branch fitur dibiarkan hidup.
8. Issue yang disebut `Closes #12` otomatis berstatus **Closed**.

`.github` di repo ini sudah menyiapkan branch `main` dan `develop`; agar PR mau di-merge, branch
proteksinya tidak meminta review orang lain (karena proyek ini dikerjakan sendiri).

### 7.2 PR rilis `develop` → `main`

Dilakukan **hanya** setelah kamu yakin `develop` sudah fix (semua fitur yang mau dinilai sudah
masuk dan pengujian lolos).

1. Tab **Pull requests** → **New pull request**.
2. Base: **`main`**, compare: **`develop`**.
3. Judul: `chore(release): merge develop into main` (atau `feat(release): ...` bila ada fitur
   besar yang dirilis).
4. Deskripsi: daftar fitur yang ikut rilis dan bukti pengujian terakhir.
5. Klik **Merge pull request** → **Create a merge commit** → **Confirm merge**.

Setelah itu `develop` dan `main` berisi kode yang sama. Mulai fitur baru lagi dari `develop`.

### 7.3 Kalau PR salah arah

- PR fitur ke `main`: tutup PR-nya (**Close pull request**), buat PR baru dengan base `develop`.
- PR dari branch yang salah: perbaiki dengan PR baru; jangan merge yang salah karena `main` harus
  selalu bersih.

## 8. Perlindungan branch di GitHub

Pengaturan yang dipakai (atur di **Settings → Branches** kalau perlu diubah):

- `main`: wajib lewat pull request, **tidak** boleh dihapus, tidak boleh force-push.
- `develop`: wajib lewat pull request, tidak boleh dihapus.
- Jumlah review yang wajib: **0** — karena dikerjakan sendiri; ganti ke 1 bila nanti ada reviewer.

## 9. Ringkasan satu hari kerja

```bash
git switch develop && git pull origin develop
git switch -c feature/api-bookings
# ... kerjakan, commit per langkah ...
git push -u origin feature/api-bookings
gh pr create --base develop --head feature/api-bookings --fill
# buka GitHub, review, Merge pull request → Create a merge commit
```
