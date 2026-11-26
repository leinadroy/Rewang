-- =====================================================================
-- Rewang - Skema database
-- Target: MySQL 5.7+ / MariaDB 10.3+ (InnoDB, utf8mb4)
-- Import: phpMyAdmin > database > Import, atau
--   mysql -u USER -p NAMA_DB < database/schema.sql
-- Urutan tabel sudah mengikuti dependensi foreign key.
-- Penjelasan desain: docs/skema-database.md
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '+07:00';

-- ---------------------------------------------------------------------
-- 1. Wilayah administratif (referensi, opsional diisi)
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS provinsi (
  id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode  VARCHAR(10)  NULL,
  nama  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_provinsi_kode (kode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kota_kab (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  provinsi_id INT UNSIGNED NOT NULL,
  kode        VARCHAR(10)  NULL,
  jenis       ENUM('kota','kabupaten') NOT NULL DEFAULT 'kota',
  nama        VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kota_kab_kode (kode),
  KEY idx_kota_kab_provinsi (provinsi_id),
  CONSTRAINT fk_kota_kab_provinsi FOREIGN KEY (provinsi_id) REFERENCES provinsi (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kecamatan (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  kota_kab_id INT UNSIGNED NOT NULL,
  kode        VARCHAR(15)  NULL,
  nama        VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kecamatan_kode (kode),
  KEY idx_kecamatan_kota (kota_kab_id),
  CONSTRAINT fk_kecamatan_kota FOREIGN KEY (kota_kab_id) REFERENCES kota_kab (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS desa_kel (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  kecamatan_id INT UNSIGNED NOT NULL,
  kode         VARCHAR(20)  NULL,
  jenis        ENUM('desa','kelurahan') NOT NULL DEFAULT 'kelurahan',
  nama         VARCHAR(100) NOT NULL,
  kode_pos     VARCHAR(10)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_desa_kel_kode (kode),
  KEY idx_desa_kel_kecamatan (kecamatan_id),
  CONSTRAINT fk_desa_kel_kecamatan FOREIGN KEY (kecamatan_id) REFERENCES kecamatan (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Komplek & unit lingkungan: komplek > rw > rt > blok > rumah
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tipe_property (
  id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama VARCHAR(50) NOT NULL,              -- Perumahan, Apartemen, Ruko, ...
  PRIMARY KEY (id),
  UNIQUE KEY uq_tipe_property_nama (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS komplek (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipe_property_id SMALLINT UNSIGNED NULL,
  desa_kel_id      INT UNSIGNED NULL,
  nama             VARCHAR(150) NOT NULL,
  alamat           TEXT NULL,
  logo_path        VARCHAR(255) NULL,
  is_active        TINYINT(1) NOT NULL DEFAULT 1,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_komplek_tipe (tipe_property_id),
  KEY idx_komplek_desa (desa_kel_id),
  CONSTRAINT fk_komplek_tipe FOREIGN KEY (tipe_property_id) REFERENCES tipe_property (id) ON DELETE SET NULL,
  CONSTRAINT fk_komplek_desa FOREIGN KEY (desa_kel_id) REFERENCES desa_kel (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rw (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  komplek_id  INT UNSIGNED NOT NULL,
  desa_kel_id INT UNSIGNED NULL,
  nomor       VARCHAR(10)  NOT NULL,      -- "008"
  nama        VARCHAR(100) NULL,          -- nama tampilan opsional
  kode_pos    VARCHAR(10)  NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rw_komplek_nomor (komplek_id, nomor),
  KEY idx_rw_desa (desa_kel_id),
  CONSTRAINT fk_rw_komplek FOREIGN KEY (komplek_id) REFERENCES komplek (id),
  CONSTRAINT fk_rw_desa FOREIGN KEY (desa_kel_id) REFERENCES desa_kel (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rt (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rw_id      INT UNSIGNED NOT NULL,
  nomor      VARCHAR(10)  NOT NULL,       -- "003"
  nama       VARCHAR(100) NULL,
  is_active  TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rt_rw_nomor (rw_id, nomor),
  CONSTRAINT fk_rt_rw FOREIGN KEY (rw_id) REFERENCES rw (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS blok (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rt_id      INT UNSIGNED NOT NULL,
  kode       VARCHAR(20) NOT NULL,        -- "A1", "Tower B"
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_blok_rt_kode (rt_id, kode),
  CONSTRAINT fk_blok_rt FOREIGN KEY (rt_id) REFERENCES rt (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tipe_rumah (
  id         SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  komplek_id INT UNSIGNED NULL,           -- NULL = berlaku umum
  nama       VARCHAR(80) NOT NULL,        -- Rumah Kecil, Studio, Ruko, ...
  PRIMARY KEY (id),
  KEY idx_tipe_rumah_komplek (komplek_id),
  CONSTRAINT fk_tipe_rumah_komplek FOREIGN KEY (komplek_id) REFERENCES komplek (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rumah (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  blok_id        INT UNSIGNED NOT NULL,
  nomor          VARCHAR(20) NOT NULL,
  tipe_rumah_id  SMALLINT UNSIGNED NULL,
  alamat         TEXT NULL,
  luas_tanah     DECIMAL(10,2) NULL,      -- m2
  luas_bangunan  DECIMAL(10,2) NULL,      -- m2
  status_hunian  ENUM('huni','kosong','disewakan') NOT NULL DEFAULT 'huni',
  is_verified    TINYINT(1) NOT NULL DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rumah_blok_nomor (blok_id, nomor),
  KEY idx_rumah_tipe (tipe_rumah_id),
  CONSTRAINT fk_rumah_blok FOREIGN KEY (blok_id) REFERENCES blok (id),
  CONSTRAINT fk_rumah_tipe FOREIGN KEY (tipe_rumah_id) REFERENCES tipe_rumah (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Login, role & hak akses
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name           VARCHAR(150) NOT NULL,
  email          VARCHAR(150) NULL,
  phone          VARCHAR(20)  NULL,
  username       VARCHAR(50)  NULL,
  password_hash  VARCHAR(255) NOT NULL,   -- password_hash() PHP, tidak pernah plain text
  status         ENUM('pending','active','suspended') NOT NULL DEFAULT 'pending',
  last_login_at  DATETIME NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_phone (phone),
  UNIQUE KEY uq_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles (
  id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode  VARCHAR(30) NOT NULL,             -- super_admin, admin_rw, pengurus_rw, pengurus_rt, seksi, warga
  nama  VARCHAR(50) NOT NULL,
  level TINYINT UNSIGNED NOT NULL,        -- makin kecil makin tinggi
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_kode (kode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
  id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode  VARCHAR(60) NOT NULL,             -- mis. warga.view, laporan.verify
  nama  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_permissions_kode (kode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id       SMALLINT UNSIGNED NOT NULL,
  permission_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES permissions (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Role selalu punya cakupan wilayah: komplek / rw / rt (NULL = seluruh platform, untuk super_admin)
CREATE TABLE IF NOT EXISTS user_roles (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NOT NULL,
  role_id    SMALLINT UNSIGNED NOT NULL,
  komplek_id INT UNSIGNED NULL,
  rw_id      INT UNSIGNED NULL,
  rt_id      INT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_user_roles_user (user_id),
  KEY idx_user_roles_role (role_id),
  KEY idx_user_roles_rw (rw_id),
  KEY idx_user_roles_rt (rt_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles (id),
  CONSTRAINT fk_ur_komplek FOREIGN KEY (komplek_id) REFERENCES komplek (id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Token untuk aplikasi mobile (Bearer). Yang disimpan hanya hash SHA-256 token.
CREATE TABLE IF NOT EXISTS api_tokens (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      INT UNSIGNED NOT NULL,
  token_hash   CHAR(64) NOT NULL,
  device_name  VARCHAR(100) NULL,
  push_token   VARCHAR(255) NULL,         -- FCM token untuk notifikasi
  last_used_at DATETIME NULL,
  expires_at   DATETIME NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_api_tokens_hash (token_hash),
  KEY idx_api_tokens_user (user_id),
  CONSTRAINT fk_api_tokens_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS password_resets (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at    DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_password_resets_hash (token_hash),
  KEY idx_password_resets_user (user_id),
  CONSTRAINT fk_pr_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 4. Master data warga
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pekerjaan (
  id        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama      VARCHAR(80) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pekerjaan_nama (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS status_hubungan (
  id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama   VARCHAR(50) NOT NULL,            -- Kepala Keluarga, Istri, Anak, ...
  urutan TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_status_hubungan_nama (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 5. Warga & Kartu Keluarga
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warga (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id             INT UNSIGNED NULL,  -- terisi kalau warga punya akun aplikasi
  rumah_id            INT UNSIGNED NULL,  -- tempat tinggal saat ini
  nik                 CHAR(16)     NULL,
  nama_lengkap        VARCHAR(150) NOT NULL,
  nama_panggilan      VARCHAR(50)  NULL,
  tempat_lahir        VARCHAR(80)  NULL,
  tanggal_lahir       DATE         NULL,
  jenis_kelamin       ENUM('L','P') NULL,
  agama               ENUM('islam','kristen','katolik','hindu','buddha','konghucu','lainnya') NULL,
  status_perkawinan   ENUM('belum_kawin','kawin','cerai_hidup','cerai_mati') NULL,
  pendidikan          VARCHAR(50)  NULL,
  pekerjaan_id        SMALLINT UNSIGNED NULL,
  kewarganegaraan     ENUM('WNI','WNA') NOT NULL DEFAULT 'WNI',
  phone               VARCHAR(20)  NULL,
  email               VARCHAR(150) NULL,
  status_ktp          ENUM('setempat','luar','belum') NULL,  -- KTP alamat RW setempat / luar RW
  status_tinggal      ENUM('pemilik','penyewa','keluarga','lainnya') NULL,
  foto_ktp_path       VARCHAR(255) NULL,
  foto_selfie_path    VARCHAR(255) NULL,
  foto_selfie_ktp_path VARCHAR(255) NULL,
  is_active           TINYINT(1) NOT NULL DEFAULT 1,       -- 0 = pindah / meninggal
  keterangan_nonaktif VARCHAR(100) NULL,
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_warga_user (user_id),
  UNIQUE KEY uq_warga_nik (nik),
  KEY idx_warga_rumah (rumah_id),
  KEY idx_warga_nama (nama_lengkap),
  KEY idx_warga_pekerjaan (pekerjaan_id),
  CONSTRAINT fk_warga_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT fk_warga_rumah FOREIGN KEY (rumah_id) REFERENCES rumah (id) ON DELETE SET NULL,
  CONSTRAINT fk_warga_pekerjaan FOREIGN KEY (pekerjaan_id) REFERENCES pekerjaan (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kartu_keluarga (
  id                     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_kk               CHAR(16) NOT NULL,
  rumah_id               INT UNSIGNED NULL,
  alamat_kk              TEXT NULL,         -- alamat sesuai KK
  alamat_domisili        TEXT NULL,
  dokumen_kk_path        VARCHAR(255) NULL,
  is_barcode             TINYINT(1) NULL,   -- KK model baru ber-barcode
  punya_akta_nikah       TINYINT(1) NULL,
  nomor_akta_nikah       VARCHAR(50) NULL,
  nomor_buku_nikah       VARCHAR(50) NULL,
  tanggal_nikah          DATE NULL,
  punya_akta_cerai       TINYINT(1) NULL,
  nomor_akta_cerai       VARCHAR(50) NULL,
  tanggal_cerai          DATE NULL,
  status_akta_kelahiran  ENUM('semua','sebagian','belum') NULL,
  status_ktp_anggota     ENUM('semua','sebagian','belum') NULL,
  status_kia_anggota     ENUM('semua','sebagian','belum') NULL,
  ada_anggota_meninggal  TINYINT(1) NULL,
  created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kk_nomor (nomor_kk),
  KEY idx_kk_rumah (rumah_id),
  CONSTRAINT fk_kk_rumah FOREIGN KEY (rumah_id) REFERENCES rumah (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kk_anggota (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  kk_id              INT UNSIGNED NOT NULL,
  warga_id           INT UNSIGNED NOT NULL,
  status_hubungan_id SMALLINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kk_anggota (kk_id, warga_id),
  KEY idx_kk_anggota_warga (warga_id),
  CONSTRAINT fk_kka_kk FOREIGN KEY (kk_id) REFERENCES kartu_keluarga (id) ON DELETE CASCADE,
  CONSTRAINT fk_kka_warga FOREIGN KEY (warga_id) REFERENCES warga (id) ON DELETE CASCADE,
  CONSTRAINT fk_kka_hub FOREIGN KEY (status_hubungan_id) REFERENCES status_hubungan (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pendaftaran akun dari aplikasi mobile, menunggu verifikasi pengurus
CREATE TABLE IF NOT EXISTS registrasi (
  id                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id              INT UNSIGNED NOT NULL,
  rt_id                INT UNSIGNED NOT NULL,
  rumah_id             INT UNSIGNED NULL,  -- dipilih kalau rumah sudah terdaftar
  blok_kode            VARCHAR(20)  NULL,  -- isian bebas kalau rumah belum terdaftar
  nomor_rumah          VARCHAR(20)  NULL,
  nik                  CHAR(16)     NULL,
  nama_lengkap         VARCHAR(150) NOT NULL,
  phone                VARCHAR(20)  NULL,
  foto_ktp_path        VARCHAR(255) NULL,
  foto_selfie_path     VARCHAR(255) NULL,
  foto_selfie_ktp_path VARCHAR(255) NULL,
  setuju_ketentuan_at  DATETIME NULL,
  status               ENUM('baru','disetujui','ditolak') NOT NULL DEFAULT 'baru',
  warga_id             INT UNSIGNED NULL,  -- warga yang ditautkan saat disetujui
  diverifikasi_oleh    INT UNSIGNED NULL,
  diverifikasi_at      DATETIME NULL,
  catatan              VARCHAR(255) NULL,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_registrasi_status (status, rt_id),
  KEY idx_registrasi_user (user_id),
  CONSTRAINT fk_reg_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_reg_rt FOREIGN KEY (rt_id) REFERENCES rt (id),
  CONSTRAINT fk_reg_rumah FOREIGN KEY (rumah_id) REFERENCES rumah (id) ON DELETE SET NULL,
  CONSTRAINT fk_reg_warga FOREIGN KEY (warga_id) REFERENCES warga (id) ON DELETE SET NULL,
  CONSTRAINT fk_reg_verifier FOREIGN KEY (diverifikasi_oleh) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permintaan perubahan data profil warga, berlaku setelah disetujui
CREATE TABLE IF NOT EXISTS perubahan_profil (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  warga_id          INT UNSIGNED NOT NULL,
  data_baru         JSON NOT NULL,        -- {"phone": "...", "pekerjaan_id": 3, ...}
  data_lama         JSON NULL,
  status            ENUM('menunggu','disetujui','ditolak') NOT NULL DEFAULT 'menunggu',
  diajukan_oleh     INT UNSIGNED NULL,
  diverifikasi_oleh INT UNSIGNED NULL,
  diverifikasi_at   DATETIME NULL,
  catatan           VARCHAR(255) NULL,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pp_status (status),
  KEY idx_pp_warga (warga_id),
  CONSTRAINT fk_pp_warga FOREIGN KEY (warga_id) REFERENCES warga (id) ON DELETE CASCADE,
  CONSTRAINT fk_pp_pengaju FOREIGN KEY (diajukan_oleh) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT fk_pp_verifier FOREIGN KEY (diverifikasi_oleh) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 6. Organisasi: seksi, jabatan, periode, pengurus (RW & RT dalam satu tabel)
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS seksi (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rw_id      INT UNSIGNED NOT NULL,
  nama       VARCHAR(80) NOT NULL,        -- Keamanan, Kebersihan, Sosial, ...
  is_active  TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_seksi_rw_nama (rw_id, nama),
  CONSTRAINT fk_seksi_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS jabatan (
  id      SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  level   ENUM('rw','rt') NOT NULL,
  nama    VARCHAR(80) NOT NULL,           -- Ketua RW, Sekretaris RT, Ketua Seksi, ...
  tipe    ENUM('ketua','wakil','sekretaris','bendahara','ketua_seksi','anggota_seksi','lainnya') NOT NULL,
  is_inti TINYINT(1) NOT NULL DEFAULT 0,  -- pengurus inti
  urutan  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_jabatan_level_nama (level, nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS periode (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  level         ENUM('rw','rt') NOT NULL,
  rw_id         INT UNSIGNED NOT NULL,
  rt_id         INT UNSIGNED NULL,        -- wajib diisi kalau level = rt
  nama          VARCHAR(100) NOT NULL,    -- "Periode 2024 - 2027"
  tanggal_awal  DATE NOT NULL,
  tanggal_akhir DATE NULL,
  is_aktif      TINYINT(1) NOT NULL DEFAULT 0,
  sambutan      TEXT NULL,                -- kata sambutan untuk halaman profil RW/RT
  foto_path     VARCHAR(255) NULL,
  sk_path       VARCHAR(255) NULL,        -- surat pengangkatan
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_periode_unit (level, rw_id, rt_id, is_aktif),
  CONSTRAINT fk_periode_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE,
  CONSTRAINT fk_periode_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pengurus (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  periode_id INT UNSIGNED NOT NULL,
  warga_id   INT UNSIGNED NOT NULL,
  jabatan_id SMALLINT UNSIGNED NOT NULL,
  seksi_id   INT UNSIGNED NULL,
  is_aktif   TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pengurus (periode_id, warga_id, jabatan_id),
  KEY idx_pengurus_warga (warga_id),
  CONSTRAINT fk_pengurus_periode FOREIGN KEY (periode_id) REFERENCES periode (id) ON DELETE CASCADE,
  CONSTRAINT fk_pengurus_warga FOREIGN KEY (warga_id) REFERENCES warga (id),
  CONSTRAINT fk_pengurus_jabatan FOREIGN KEY (jabatan_id) REFERENCES jabatan (id),
  CONSTRAINT fk_pengurus_seksi FOREIGN KEY (seksi_id) REFERENCES seksi (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS galeri (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  level            ENUM('rw','rt') NOT NULL,
  rw_id            INT UNSIGNED NOT NULL,
  rt_id            INT UNSIGNED NULL,
  judul            VARCHAR(150) NOT NULL,
  tanggal_kegiatan DATE NULL,
  cover_path       VARCHAR(255) NULL,
  is_publish       TINYINT(1) NOT NULL DEFAULT 0,
  created_by       INT UNSIGNED NULL,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_galeri_unit (rw_id, rt_id, is_publish),
  CONSTRAINT fk_galeri_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE,
  CONSTRAINT fk_galeri_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE CASCADE,
  CONSTRAINT fk_galeri_user FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS galeri_foto (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  galeri_id  INT UNSIGNED NOT NULL,
  path       VARCHAR(255) NOT NULL,
  caption    VARCHAR(255) NULL,
  urutan     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_galeri_foto (galeri_id, urutan),
  CONSTRAINT fk_gf_galeri FOREIGN KEY (galeri_id) REFERENCES galeri (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 7. Laporan / keluhan warga
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS kategori_laporan (
  id                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rw_id             INT UNSIGNED NULL,    -- NULL = kategori umum
  nama              VARCHAR(80) NOT NULL, -- Kebersihan, Keamanan, Fasilitas, ...
  teruskan_ke_rt    TINYINT(1) NOT NULL DEFAULT 1,
  teruskan_ke_seksi TINYINT(1) NOT NULL DEFAULT 0,
  seksi_id          INT UNSIGNED NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  KEY idx_kategori_laporan_rw (rw_id),
  CONSTRAINT fk_kl_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE,
  CONSTRAINT fk_kl_seksi FOREIGN KEY (seksi_id) REFERENCES seksi (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS laporan (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor       VARCHAR(30) NOT NULL,       -- LAP/2026/11/0001
  warga_id    INT UNSIGNED NOT NULL,      -- pelapor
  rw_id       INT UNSIGNED NOT NULL,
  rt_id       INT UNSIGNED NULL,
  kategori_id SMALLINT UNSIGNED NULL,
  seksi_id    INT UNSIGNED NULL,          -- ditugaskan ke seksi
  jenis       ENUM('keluhan','informasi') NOT NULL DEFAULT 'keluhan',
  prioritas   ENUM('normal','darurat') NOT NULL DEFAULT 'normal',
  sumber      ENUM('web','mobile') NOT NULL DEFAULT 'mobile',
  judul       VARCHAR(150) NOT NULL,
  isi         TEXT NOT NULL,
  lokasi      VARCHAR(255) NULL,
  latitude    DECIMAL(10,7) NULL,
  longitude   DECIMAL(10,7) NULL,
  status      ENUM('baru','diproses','selesai','ditolak') NOT NULL DEFAULT 'baru',
  selesai_at  DATETIME NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_laporan_nomor (nomor),
  KEY idx_laporan_unit_status (rw_id, rt_id, status),
  KEY idx_laporan_warga (warga_id),
  CONSTRAINT fk_laporan_warga FOREIGN KEY (warga_id) REFERENCES warga (id),
  CONSTRAINT fk_laporan_rw FOREIGN KEY (rw_id) REFERENCES rw (id),
  CONSTRAINT fk_laporan_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE SET NULL,
  CONSTRAINT fk_laporan_kategori FOREIGN KEY (kategori_id) REFERENCES kategori_laporan (id) ON DELETE SET NULL,
  CONSTRAINT fk_laporan_seksi FOREIGN KEY (seksi_id) REFERENCES seksi (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS laporan_lampiran (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  laporan_id INT UNSIGNED NOT NULL,
  path       VARCHAR(255) NOT NULL,
  tahap      ENUM('laporan','penyelesaian') NOT NULL DEFAULT 'laporan', -- foto awal vs foto realisasi
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ll_laporan (laporan_id),
  CONSTRAINT fk_ll_laporan FOREIGN KEY (laporan_id) REFERENCES laporan (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 8. Pengajuan surat keterangan
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS jenis_surat (
  id            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama          VARCHAR(100) NOT NULL,    -- Surat Keterangan Domisili, Kematian, ...
  kode          VARCHAR(20)  NULL,        -- untuk penomoran surat
  template_path VARCHAR(255) NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_jenis_surat_nama (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS jenis_surat_syarat (
  id             SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  jenis_surat_id SMALLINT UNSIGNED NOT NULL,
  nama           VARCHAR(100) NOT NULL,   -- Fotokopi KTP, Fotokopi KK, ...
  is_wajib       TINYINT(1) NOT NULL DEFAULT 1,
  urutan         TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_jss_jenis (jenis_surat_id),
  CONSTRAINT fk_jss_jenis FOREIGN KEY (jenis_surat_id) REFERENCES jenis_surat (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pengajuan_surat (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_antrian    VARCHAR(30) NOT NULL,  -- SRT/2026/11/0001
  nomor_surat      VARCHAR(60) NULL,      -- diisi saat surat terbit
  warga_id         INT UNSIGNED NOT NULL, -- pemohon
  untuk_warga_id   INT UNSIGNED NULL,     -- kalau diurus untuk anggota keluarga lain
  jenis_surat_id   SMALLINT UNSIGNED NOT NULL,
  rw_id            INT UNSIGNED NOT NULL,
  rt_id            INT UNSIGNED NULL,
  keperluan        VARCHAR(255) NOT NULL,
  keterangan       TEXT NULL,
  status           ENUM('baru','diproses','selesai','ditolak') NOT NULL DEFAULT 'baru',
  dokumen_hasil_path VARCHAR(255) NULL,
  selesai_at       DATETIME NULL,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ps_antrian (nomor_antrian),
  KEY idx_ps_unit_status (rw_id, rt_id, status),
  KEY idx_ps_warga (warga_id),
  CONSTRAINT fk_ps_warga FOREIGN KEY (warga_id) REFERENCES warga (id),
  CONSTRAINT fk_ps_untuk FOREIGN KEY (untuk_warga_id) REFERENCES warga (id) ON DELETE SET NULL,
  CONSTRAINT fk_ps_jenis FOREIGN KEY (jenis_surat_id) REFERENCES jenis_surat (id),
  CONSTRAINT fk_ps_rw FOREIGN KEY (rw_id) REFERENCES rw (id),
  CONSTRAINT fk_ps_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pengajuan_surat_lampiran (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pengajuan_id INT UNSIGNED NOT NULL,
  syarat_id   SMALLINT UNSIGNED NULL,
  path        VARCHAR(255) NOT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_psl_pengajuan (pengajuan_id),
  CONSTRAINT fk_psl_pengajuan FOREIGN KEY (pengajuan_id) REFERENCES pengajuan_surat (id) ON DELETE CASCADE,
  CONSTRAINT fk_psl_syarat FOREIGN KEY (syarat_id) REFERENCES jenis_surat_syarat (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 9. IPL (iuran pengelolaan lingkungan)
--    Satu sumber tarif: komponen_ipl per komplek.
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS komponen_ipl (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  komplek_id     INT UNSIGNED NOT NULL,
  nama           VARCHAR(80) NOT NULL,    -- Keamanan, Kebersihan, Sampah, ...
  metode         ENUM('flat','per_m2_tanah','per_m2_bangunan','per_tipe_rumah') NOT NULL DEFAULT 'flat',
  nilai          DECIMAL(14,2) NOT NULL DEFAULT 0,  -- rupiah, atau rupiah per m2
  berlaku_mulai  DATE NOT NULL,
  berlaku_sampai DATE NULL,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_komponen_komplek (komplek_id, is_active),
  CONSTRAINT fk_komponen_komplek FOREIGN KEY (komplek_id) REFERENCES komplek (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tarif per tipe rumah, dipakai komponen dengan metode 'per_tipe_rumah'
CREATE TABLE IF NOT EXISTS komponen_ipl_tarif (
  komponen_id   INT UNSIGNED NOT NULL,
  tipe_rumah_id SMALLINT UNSIGNED NOT NULL,
  nilai         DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (komponen_id, tipe_rumah_id),
  CONSTRAINT fk_kit_komponen FOREIGN KEY (komponen_id) REFERENCES komponen_ipl (id) ON DELETE CASCADE,
  CONSTRAINT fk_kit_tipe FOREIGN KEY (tipe_rumah_id) REFERENCES tipe_rumah (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ipl_tagihan (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor        VARCHAR(30) NOT NULL,      -- IPL/2026/11/000123
  rumah_id     INT UNSIGNED NOT NULL,
  warga_id     INT UNSIGNED NULL,         -- penanggung jawab saat tagihan dibuat
  tahun        SMALLINT UNSIGNED NOT NULL,
  bulan        TINYINT UNSIGNED NOT NULL,
  total        DECIMAL(14,2) NOT NULL DEFAULT 0,
  terbayar     DECIMAL(14,2) NOT NULL DEFAULT 0,
  jatuh_tempo  DATE NOT NULL,
  status       ENUM('belum_bayar','menunggu_verifikasi','sebagian','lunas','batal') NOT NULL DEFAULT 'belum_bayar',
  dikirim_at   DATETIME NULL,             -- notifikasi tagihan terkirim
  lunas_at     DATETIME NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ipl_nomor (nomor),
  UNIQUE KEY uq_ipl_rumah_periode (rumah_id, tahun, bulan),
  KEY idx_ipl_status (status, jatuh_tempo),
  KEY idx_ipl_warga (warga_id),
  CONSTRAINT fk_ipl_rumah FOREIGN KEY (rumah_id) REFERENCES rumah (id),
  CONSTRAINT fk_ipl_warga FOREIGN KEY (warga_id) REFERENCES warga (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Rincian tagihan: snapshot perhitungan saat tagihan dibuat
CREATE TABLE IF NOT EXISTS ipl_tagihan_item (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tagihan_id  INT UNSIGNED NOT NULL,
  komponen_id INT UNSIGNED NULL,
  keterangan  VARCHAR(150) NOT NULL,      -- "Keamanan (120 m2 x Rp 2.000)"
  jumlah      DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_iti_tagihan (tagihan_id),
  CONSTRAINT fk_iti_tagihan FOREIGN KEY (tagihan_id) REFERENCES ipl_tagihan (id) ON DELETE CASCADE,
  CONSTRAINT fk_iti_komponen FOREIGN KEY (komponen_id) REFERENCES komponen_ipl (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ipl_pembayaran (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tagihan_id        INT UNSIGNED NOT NULL,
  jumlah            DECIMAL(14,2) NOT NULL,
  tanggal_bayar     DATE NOT NULL,
  metode            ENUM('transfer','tunai','virtual_account','qris','lainnya') NOT NULL DEFAULT 'transfer',
  bukti_path        VARCHAR(255) NULL,
  referensi         VARCHAR(100) NULL,    -- no. referensi bank / payment gateway
  status            ENUM('menunggu','diterima','ditolak') NOT NULL DEFAULT 'menunggu',
  dibayar_oleh      INT UNSIGNED NULL,    -- user yang upload
  diverifikasi_oleh INT UNSIGNED NULL,
  diverifikasi_at   DATETIME NULL,
  catatan           VARCHAR(255) NULL,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ipb_tagihan (tagihan_id),
  KEY idx_ipb_status (status),
  CONSTRAINT fk_ipb_tagihan FOREIGN KEY (tagihan_id) REFERENCES ipl_tagihan (id) ON DELETE CASCADE,
  CONSTRAINT fk_ipb_payer FOREIGN KEY (dibayar_oleh) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT fk_ipb_verifier FOREIGN KEY (diverifikasi_oleh) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 10. Pengumuman & konten aplikasi
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS kategori_pengumuman (
  id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_kategori_pengumuman_nama (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Satu tabel untuk RW->RT, RW->Warga, RT->Warga
CREATE TABLE IF NOT EXISTS pengumuman (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  dari_level   ENUM('rw','rt') NOT NULL,
  rw_id        INT UNSIGNED NOT NULL,
  rt_id        INT UNSIGNED NULL,         -- pengirim RT, atau RT tujuan (NULL = semua RT di RW)
  target       ENUM('pengurus_rt','warga') NOT NULL,
  kategori_id  SMALLINT UNSIGNED NULL,
  judul        VARCHAR(200) NOT NULL,
  isi          MEDIUMTEXT NOT NULL,
  gambar_path  VARCHAR(255) NULL,
  is_penting   TINYINT(1) NOT NULL DEFAULT 0,  -- Pengumuman Penting vs Umum
  is_publish   TINYINT(1) NOT NULL DEFAULT 0,
  published_at DATETIME NULL,
  created_by   INT UNSIGNED NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pengumuman_feed (rw_id, rt_id, target, is_publish, published_at),
  CONSTRAINT fk_peng_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE,
  CONSTRAINT fk_peng_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE CASCADE,
  CONSTRAINT fk_peng_kategori FOREIGN KEY (kategori_id) REFERENCES kategori_pengumuman (id) ON DELETE SET NULL,
  CONSTRAINT fk_peng_user FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS banner (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rw_id       INT UNSIGNED NULL,          -- NULL = tampil di semua RW
  rt_id       INT UNSIGNED NULL,
  judul       VARCHAR(150) NULL,
  gambar_path VARCHAR(255) NOT NULL,
  link_url    VARCHAR(255) NULL,
  urutan      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  mulai_at    DATETIME NULL,
  selesai_at  DATETIME NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_banner_unit (rw_id, rt_id, is_active, urutan),
  CONSTRAINT fk_banner_rw FOREIGN KEY (rw_id) REFERENCES rw (id) ON DELETE CASCADE,
  CONSTRAINT fk_banner_rt FOREIGN KEY (rt_id) REFERENCES rt (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faq_kategori (
  id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama   VARCHAR(80) NOT NULL,
  urutan TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faq (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  kategori_id SMALLINT UNSIGNED NULL,
  pertanyaan  VARCHAR(255) NOT NULL,
  jawaban     TEXT NOT NULL,
  urutan      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  is_publish  TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  KEY idx_faq_kategori (kategori_id, urutan),
  CONSTRAINT fk_faq_kategori FOREIGN KEY (kategori_id) REFERENCES faq_kategori (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_rilis (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  versi               VARCHAR(20) NOT NULL,
  platform            ENUM('android','ios','web') NOT NULL DEFAULT 'android',
  file_path           VARCHAR(255) NULL,   -- APK
  minimum_requirement TEXT NULL,
  catatan_rilis       TEXT NULL,
  is_wajib_update     TINYINT(1) NOT NULL DEFAULT 0,
  is_publish          TINYINT(1) NOT NULL DEFAULT 0,
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_app_rilis (platform, versi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pengaturan aplikasi (teks Tentang, S&K, kontak CS, URL, dll).
-- Rahasia (password SMTP, API key) TIDAK disimpan di sini, tapi di api/config.php.
CREATE TABLE IF NOT EXISTS pengaturan (
  kunci      VARCHAR(80) NOT NULL,
  nilai      MEDIUMTEXT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (kunci)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 11. Notifikasi, riwayat status & audit
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS notifikasi (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NOT NULL,
  tipe       ENUM('transaksi','info') NOT NULL DEFAULT 'info',
  judul      VARCHAR(150) NOT NULL,
  isi        VARCHAR(500) NULL,
  entitas    VARCHAR(30) NULL,            -- laporan, pengajuan_surat, ipl_tagihan, registrasi, ...
  entitas_id INT UNSIGNED NULL,
  read_at    DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notif_user (user_id, read_at, created_at),
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Timeline status untuk laporan, surat, registrasi, IPL, perubahan profil
CREATE TABLE IF NOT EXISTS status_log (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entitas     VARCHAR(30) NOT NULL,
  entitas_id  INT UNSIGNED NOT NULL,
  status_dari VARCHAR(30) NULL,
  status_ke   VARCHAR(30) NOT NULL,
  catatan     TEXT NULL,
  user_id     INT UNSIGNED NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_status_log_entitas (entitas, entitas_id, created_at),
  CONSTRAINT fk_status_log_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Jejak perubahan data penting oleh admin/pengurus
CREATE TABLE IF NOT EXISTS audit_log (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NULL,
  aksi       VARCHAR(30) NOT NULL,        -- create, update, delete, login, export
  entitas    VARCHAR(30) NULL,
  entitas_id INT UNSIGNED NULL,
  data       JSON NULL,
  ip         VARCHAR(45) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_entitas (entitas, entitas_id),
  KEY idx_audit_user (user_id, created_at),
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
