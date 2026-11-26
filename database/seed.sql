-- =====================================================================
-- Rewang - Data awal (master & role). Jalankan setelah schema.sql.
-- Aman dijalankan ulang (INSERT IGNORE). Tidak membuat user/password.
-- =====================================================================

SET NAMES utf8mb4;

-- Role -----------------------------------------------------------------
INSERT IGNORE INTO roles (kode, nama, level) VALUES
  ('super_admin', 'Super Admin',  1),
  ('admin_rw',    'Admin RW',     2),
  ('pengurus_rw', 'Pengurus RW',  3),
  ('pengurus_rt', 'Pengurus RT',  4),
  ('seksi',       'Seksi',        5),
  ('warga',       'Warga',        9);

-- Permission -------------------------------------------------------------
INSERT IGNORE INTO permissions (kode, nama) VALUES
  ('dashboard.view',        'Lihat dashboard'),
  ('wilayah.manage',        'Kelola komplek, RW, RT, blok, rumah'),
  ('master.manage',         'Kelola master data (pekerjaan, jabatan, kategori, jenis surat)'),
  ('user.manage',           'Kelola user & role'),
  ('warga.view',            'Lihat data warga'),
  ('warga.manage',          'Tambah/ubah data warga & KK'),
  ('warga.export',          'Export data warga'),
  ('registrasi.verify',     'Verifikasi registrasi akun'),
  ('profil.verify',         'Verifikasi perubahan profil'),
  ('rumah.verify',          'Verifikasi data rumah'),
  ('laporan.view',          'Lihat laporan warga'),
  ('laporan.process',       'Proses laporan warga'),
  ('laporan.create',        'Buat laporan'),
  ('surat.view',            'Lihat pengajuan surat'),
  ('surat.process',         'Proses pengajuan surat'),
  ('surat.create',          'Ajukan surat'),
  ('ipl.view',              'Lihat tagihan IPL'),
  ('ipl.manage',            'Atur tarif & buat tagihan IPL'),
  ('ipl.verify',            'Verifikasi pembayaran IPL'),
  ('ipl.pay',               'Bayar/upload bukti IPL'),
  ('pengumuman.view',       'Lihat pengumuman'),
  ('pengumuman.manage',     'Buat pengumuman'),
  ('organisasi.manage',     'Kelola periode, pengurus, profil, galeri'),
  ('konten.manage',         'Kelola banner, FAQ, info aplikasi'),
  ('pengaturan.manage',     'Ubah pengaturan aplikasi');

-- super_admin: semua permission
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.kode = 'super_admin';

-- admin_rw: semua kecuali pengaturan platform
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.kode = 'admin_rw' AND p.kode NOT IN ('pengaturan.manage', 'laporan.create', 'surat.create', 'ipl.pay');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
WHERE r.kode = 'pengurus_rw' AND p.kode IN (
  'dashboard.view','warga.view','warga.export','registrasi.verify','profil.verify','rumah.verify',
  'laporan.view','laporan.process','surat.view','surat.process','ipl.view','ipl.verify',
  'pengumuman.view','pengumuman.manage','organisasi.manage');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
WHERE r.kode = 'pengurus_rt' AND p.kode IN (
  'dashboard.view','warga.view','warga.manage','registrasi.verify','profil.verify','rumah.verify',
  'laporan.view','laporan.process','surat.view','surat.process','ipl.view',
  'pengumuman.view','pengumuman.manage','organisasi.manage');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
WHERE r.kode = 'seksi' AND p.kode IN ('dashboard.view','laporan.view','laporan.process','pengumuman.view');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
WHERE r.kode = 'warga' AND p.kode IN ('laporan.create','surat.create','ipl.pay','pengumuman.view');

-- Master data ------------------------------------------------------------
INSERT IGNORE INTO tipe_property (nama) VALUES
  ('Perumahan'), ('Apartemen'), ('Ruko'), ('Kampung');

INSERT IGNORE INTO status_hubungan (nama, urutan) VALUES
  ('Kepala Keluarga', 1), ('Suami', 2), ('Istri', 3), ('Anak', 4), ('Menantu', 5),
  ('Cucu', 6), ('Orang Tua', 7), ('Mertua', 8), ('Famili Lain', 9), ('Pembantu', 10), ('Lainnya', 11);

INSERT IGNORE INTO pekerjaan (nama) VALUES
  ('Belum/Tidak Bekerja'), ('Mengurus Rumah Tangga'), ('Pelajar/Mahasiswa'), ('Pensiunan'),
  ('PNS'), ('TNI/Polri'), ('Karyawan Swasta'), ('Karyawan BUMN'), ('Wiraswasta'),
  ('Pedagang'), ('Profesional (Dokter, Pengacara, dll.)'), ('Guru/Dosen'), ('Lainnya');

INSERT IGNORE INTO jabatan (level, nama, tipe, is_inti, urutan) VALUES
  ('rw', 'Ketua RW',          'ketua',         1, 1),
  ('rw', 'Wakil Ketua RW',    'wakil',         1, 2),
  ('rw', 'Sekretaris RW',     'sekretaris',    1, 3),
  ('rw', 'Bendahara RW',      'bendahara',     1, 4),
  ('rw', 'Ketua Seksi',       'ketua_seksi',   0, 5),
  ('rw', 'Anggota Seksi',     'anggota_seksi', 0, 6),
  ('rt', 'Ketua RT',          'ketua',         1, 1),
  ('rt', 'Wakil Ketua RT',    'wakil',         1, 2),
  ('rt', 'Sekretaris RT',     'sekretaris',    1, 3),
  ('rt', 'Bendahara RT',      'bendahara',     1, 4);

INSERT IGNORE INTO kategori_pengumuman (nama) VALUES
  ('Umum'), ('Kegiatan'), ('Keamanan'), ('Kebersihan'), ('Keuangan'), ('Duka Cita');

INSERT INTO kategori_laporan (rw_id, nama, teruskan_ke_rt, teruskan_ke_seksi)
SELECT NULL, x.nama, 1, 0 FROM (
  SELECT 'Kebersihan' AS nama UNION ALL SELECT 'Keamanan' UNION ALL SELECT 'Fasilitas Umum'
  UNION ALL SELECT 'Jalan & Drainase' UNION ALL SELECT 'Penerangan' UNION ALL SELECT 'Lainnya'
) x
WHERE NOT EXISTS (SELECT 1 FROM kategori_laporan k WHERE k.rw_id IS NULL AND k.nama = x.nama);

INSERT IGNORE INTO jenis_surat (nama, kode) VALUES
  ('Surat Keterangan Domisili',        'SKD'),
  ('Surat Pengantar KTP/KK',           'SPK'),
  ('Surat Keterangan Tidak Mampu',     'SKTM'),
  ('Surat Keterangan Kematian',        'SKK'),
  ('Surat Keterangan Usaha',           'SKU'),
  ('Surat Pengantar Nikah',            'SPN');

INSERT IGNORE INTO pengaturan (kunci, nilai) VALUES
  ('app.nama',              'Rewang'),
  ('app.tagline',           'Aplikasi Rukun Warga'),
  ('app.tentang',           NULL),
  ('app.syarat_ketentuan',  NULL),
  ('app.kontak_cs',         NULL),
  ('ipl.hari_jatuh_tempo',  '10');
