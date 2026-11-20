# CLAUDE.md — Aturan Git untuk proyek HUNIKOS (mobile)

> File ini dibaca otomatis setiap sesi. Salin juga ke `AGENTS.md` bila memakai tool AI lain.
> Panduan lengkap untuk manusia ada di `docs/GIT_WORKFLOW.md`.

## 1. Model branch

| Branch | Fungsi | Boleh commit langsung? |
|---|---|---|
| `main` | Hanya kode yang sudah fix dan siap dirilis/dinilai | **Tidak pernah** |
| `develop` | Tempat fitur-fitur yang sudah selesai digabung | **Tidak pernah** (hanya lewat PR) |
| `feature/<area>-<nama-fitur>` | Satu fitur = satu branch, dibuat dari `develop` | Ya, di sinilah semua pekerjaan dilakukan |

Aturan nama: huruf kecil, kebab-case, diawali area (`mobile`, `docs`, `deploy`).
Contoh: `feature/mobile-foundation`, `feature/mobile-auth`, `feature/mobile-tenant`,
`feature/mobile-owner`, `feature/mobile-admin`.

Alur: `feature/* --PR--> develop --PR--> main`. Merge PR selalu dilakukan pengguna lewat
GitHub; AI tidak pernah merge dan tidak pernah memasukkan perubahan ke `develop`/`main`
dengan cara lain.

## 2. Aturan commit (Conventional Commits 1.0.0)

```
<type>(<scope>): <subject>
```

- Bahasa Inggris, mood perintah (`add`, `fix`, `remove`), subject huruf kecil, tanpa titik,
  maksimal 72 karakter.
- Satu commit = satu langkah logis. Jangan campur perubahan yang tidak berhubungan.
- Scope yang dipakai di repo ini: `mobile`, `mobile-auth`, `mobile-tenant`, `mobile-owner`,
  `mobile-admin`, `repo`, `docs`, `deploy`.

Type: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`,
`revert`.

Setiap penambahan/perubahan/penghapusan kode di-commit sendiri-sendiri setelah langkah itu
selesai, tanpa menunggu diminta. Contoh urutan satu fitur:

```
chore(mobile): add flutter scaffold for android, ios, and web
build(mobile): add provider, dio, and go_router dependencies
feat(mobile): add app configuration and design system
feat(mobile): add api client with token interceptor
test(mobile): cover models, validators, and formatters
```

Cara stage: `git status` → `git add <path spesifik>` → `git diff --staged` →
`git commit -m "..."`. Jangan `git add .` / `git add -A` membabi buta.

## 3. Jangan pernah di-commit

`.env` dan rahasia apa pun, `build/`, `.dart_tool/`, file hasil generate, dump database.
Jika menemukan rahasia sudah ter-stage, keluarkan dan beri tahu pengguna.

## 4. Kualitas sebelum commit

`flutter analyze` harus bersih dan `flutter test` harus lolos untuk bagian yang berubah.
Jangan commit kode yang jelas tidak jalan dan jangan memakai `--no-verify`.

## 5. Larangan mutlak

- Commit/push langsung ke `main` atau `develop`.
- Merge PR atau mengubah pengaturan branch protection.
- `git push --force` ke branch bersama, `git reset --hard` pada commit yang sudah di-push.
- Mengarang isi PR/issue (hasil test, screenshot, nomor issue).

## 6. Konteks proyek

Mobile HUNIKOS adalah client Flutter dari REST API HUNIKOS. Sumber kebenaran API dan database
ada di `docs/00_KONTRAK_BERSAMA.md`. Backend berada di repo `HuniKos-Backend`, aplikasi ini
tidak menambah endpoint atau field di luar kontrak.
