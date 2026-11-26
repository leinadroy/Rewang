# Rewang

Aplikasi Rukun Warga (Rewang).

Stack: **Svelte 5 (Vite)** untuk frontend, **PHP native** (tanpa framework/Composer) untuk API, **MySQL**.
Node.js hanya dipakai di komputer lokal untuk build. Hosting cukup PHP 8.1+ dan MySQL.

## Struktur

```
frontend/        Source Svelte (index.html, src/, public/)
api/             Backend PHP
  index.php      Entry point + router
  routes.php     Daftar endpoint  ← tambah endpoint di sini
  lib/           Config, Database (PDO), Request, Response, Router
  config.php     Kredensial lokal (tidak ikut git & build)
database/        schema.sql
scripts/         copy-api.mjs (dipakai saat build)
dist/            Hasil build → yang di-upload ke hosting
```

## Development (lokal, XAMPP)

1. Jalankan **MySQL** dari XAMPP Control Panel.
2. Buat database `rewang` dan import `database/schema.sql` (phpMyAdmin atau CLI):
   ```
   C:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE IF NOT EXISTS rewang CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
   C:\xampp\mysql\bin\mysql.exe -u root rewang < database/schema.sql
   ```
3. `npm install` (sekali saja)
4. `npm run dev` → buka http://localhost:5173

`npm run dev` menjalankan Vite (port 5173) dan PHP built-in server (port 8000) bersamaan.
Request ke `/api/*` dari Vite otomatis diteruskan ke PHP.

## Build & deploy ke shared hosting

1. Kalau dipasang di subfolder (mis. `domain.com/rewang/`), buat `.env` berisi `VITE_BASE=/rewang/`.
2. `npm run build` → hasil di `dist/` (frontend + folder `api/`).
3. Upload **isi** `dist/` ke `public_html` (atau subfolder tujuan). Pastikan file `.htaccess` ikut ter-upload.
4. Di hosting, salin `api/config.example.php` menjadi `api/config.php` dan isi kredensial database dari cPanel. `debug` biarkan `false`.
5. Buat database di cPanel lalu import `database/schema.sql` lewat phpMyAdmin.
6. Cek `https://domain.com/api/health` → harus `"database": "connected"`.

Butuh Apache/LiteSpeed dengan `mod_rewrite` (standar di hampir semua shared hosting).

## Menambah endpoint

Di `api/routes.php`:

```php
$router->get('/users/{id}', function (array $params) {
    $user = Database::one('SELECT id, name, email FROM users WHERE id = ?', [$params['id']]);
    $user ? Response::json($user) : Response::error('User tidak ditemukan', 404);
});
```

Di Svelte:

```js
import { api } from './lib/api.js';
const user = await api.get('/users/1');
```
