-- ============================================================================
-- SKEMA BASIS DATA & SEEDER: MODUL PRESENSI PERKULIAHAN MAHASISWA
-- Database      : si_kampus_db
-- Engine        : MySQL / MariaDB (InnoDB, UTF8mb4)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `si_kampus_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `si_kampus_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- Drop view & tabel jika sudah ada sebelumnya (urutan child ke parent)
DROP VIEW IF EXISTS `v_matriks_presensi_16_pertemuan`;
DROP VIEW IF EXISTS `v_rekap_presensi_mahasiswa`;
DROP TABLE IF EXISTS `presensi_mahasiswa`;
DROP TABLE IF EXISTS `sesi_kuliah`;
DROP TABLE IF EXISTS `peserta_kelas`;
DROP TABLE IF EXISTS `jadwal_kuliah`;
DROP TABLE IF EXISTS `mata_kuliah`;
DROP TABLE IF EXISTS `mahasiswa`;
DROP TABLE IF EXISTS `dosen`;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. TABEL MASTER / REFERENSI
-- ============================================================================

-- 1.1 Tabel Master Dosen
CREATE TABLE `dosen` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nidn` VARCHAR(20) NOT NULL UNIQUE,
    `nama_dosen` VARCHAR(150) NOT NULL,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `no_hp` VARCHAR(20) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.2 Tabel Master Mahasiswa
CREATE TABLE `mahasiswa` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nim` VARCHAR(20) NOT NULL UNIQUE,
    `nama_mahasiswa` VARCHAR(150) NOT NULL,
    `prodi` VARCHAR(100) NOT NULL DEFAULT 'Teknik Informatika',
    `angkatan` VARCHAR(10) NOT NULL DEFAULT '2024',
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `no_hp` VARCHAR(20) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.3 Tabel Master Mata Kuliah
CREATE TABLE `mata_kuliah` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `kode_mk` VARCHAR(20) NOT NULL UNIQUE,
    `nama_mk` VARCHAR(150) NOT NULL,
    `sks` TINYINT NOT NULL DEFAULT 3,
    `semester` TINYINT NOT NULL DEFAULT 4,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.4 Tabel Jadwal Kuliah
CREATE TABLE `jadwal_kuliah` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `mata_kuliah_id` INT NOT NULL,
    `dosen_id` INT NOT NULL,
    `kelas` VARCHAR(20) NOT NULL,
    `hari` ENUM('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu') NOT NULL,
    `jam_mulai` TIME NOT NULL,
    `jam_selesai` TIME NOT NULL,
    `ruangan` VARCHAR(50) NOT NULL,
    `tahun_akademik` VARCHAR(20) NOT NULL DEFAULT '2026/2027',
    `semester_akademik` ENUM('Ganjil', 'Genap') NOT NULL DEFAULT 'Genap',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_jadwal_mk` FOREIGN KEY (`mata_kuliah_id`) 
        REFERENCES `mata_kuliah` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_jadwal_dosen` FOREIGN KEY (`dosen_id`) 
        REFERENCES `dosen` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1.5 Tabel Peserta Kelas
CREATE TABLE `peserta_kelas` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `jadwal_id` INT NOT NULL,
    `mahasiswa_id` INT NOT NULL,
    `status_krs` ENUM('Disetujui', 'Pending', 'Batal') NOT NULL DEFAULT 'Disetujui',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `unique_peserta_kelas` UNIQUE (`jadwal_id`, `mahasiswa_id`),
    CONSTRAINT `fk_peserta_jadwal` FOREIGN KEY (`jadwal_id`) 
        REFERENCES `jadwal_kuliah` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_peserta_mahasiswa` FOREIGN KEY (`mahasiswa_id`) 
        REFERENCES `mahasiswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. TABEL UTAMA MODUL PRESENSI
-- ============================================================================

-- 2.1 Tabel Header: Sesi Kuliah
CREATE TABLE `sesi_kuliah` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `jadwal_id` INT NOT NULL,
    `dosen_id` INT NOT NULL,
    `pertemuan_ke` TINYINT NOT NULL COMMENT 'Nomor pertemuan (1 s/d 16)',
    `tanggal_pertemuan` DATE NOT NULL,
    `jam_mulai` TIME NOT NULL,
    `jam_selesai` TIME NOT NULL,
    `metode_kuliah` ENUM('Tatap Muka', 'Daring') NOT NULL DEFAULT 'Tatap Muka',
    `materi_perkuliahan` TEXT NOT NULL COMMENT 'Pokok bahasan materi yang diajarkan',
    `status_sesi` ENUM('dibuka', 'selesai', 'dibatalkan') NOT NULL DEFAULT 'selesai',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `unique_jadwal_pertemuan` UNIQUE (`jadwal_id`, `pertemuan_ke`),
    CONSTRAINT `fk_sesi_jadwal` FOREIGN KEY (`jadwal_id`) 
        REFERENCES `jadwal_kuliah` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_sesi_dosen` FOREIGN KEY (`dosen_id`) 
        REFERENCES `dosen` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.2 Tabel Detail: Presensi Mahasiswa
CREATE TABLE `presensi_mahasiswa` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `sesi_id` INT NOT NULL,
    `mahasiswa_id` INT NOT NULL,
    `status_kehadiran` ENUM('H', 'I', 'S', 'A') NOT NULL DEFAULT 'H',
    `catatan_keterangan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan izin/sakit, nomor surat dokter, dispensasi, dsb.',
    `waktu_input` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `unique_sesi_mahasiswa` UNIQUE (`sesi_id`, `mahasiswa_id`),
    CONSTRAINT `fk_presensi_sesi` FOREIGN KEY (`sesi_id`) 
        REFERENCES `sesi_kuliah` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_presensi_mahasiswa` FOREIGN KEY (`mahasiswa_id`) 
        REFERENCES `mahasiswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. VIEWS UNTUK REKAPITULASI KEHADIRAN
-- ============================================================================

-- 3.1 View Rekapitulasi Kehadiran & Kalkulasi Persentase Syarat UAS (>= 75%)
CREATE OR REPLACE VIEW `v_rekap_presensi_mahasiswa` AS
SELECT 
    jk.id AS jadwal_id,
    jk.kelas,
    jk.tahun_akademik,
    jk.semester_akademik,
    mk.kode_mk,
    mk.nama_mk,
    d.nama_dosen,
    m.id AS mahasiswa_id,
    m.nim,
    m.nama_mahasiswa,
    COUNT(DISTINCT sk.id) AS total_pertemuan_berjalan,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'H' THEN 1 ELSE 0 END), 0) AS total_hadir,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'I' THEN 1 ELSE 0 END), 0) AS total_izin,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'S' THEN 1 ELSE 0 END), 0) AS total_sakit,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'A' THEN 1 ELSE 0 END), 0) AS total_alpa,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT sk.id) = 0 THEN 0.00
            ELSE (COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'H' THEN 1 ELSE 0 END), 0) / COUNT(DISTINCT sk.id)) * 100 
        END, 2
    ) AS persentase_kehadiran,
    CASE 
        WHEN COUNT(DISTINCT sk.id) = 0 THEN 'Belum Ada Pertemuan'
        WHEN (COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'H' THEN 1 ELSE 0 END), 0) / COUNT(DISTINCT sk.id)) * 100 >= 75.00 
            THEN 'Memenuhi Syarat UAS'
        ELSE 'Warning: Kehadiran < 75%'
    END AS status_kelayakan_uas
FROM peserta_kelas pk
JOIN jadwal_kuliah jk ON pk.jadwal_id = jk.id
JOIN mata_kuliah mk ON jk.mata_kuliah_id = mk.id
JOIN dosen d ON jk.dosen_id = d.id
JOIN mahasiswa m ON pk.mahasiswa_id = m.id
LEFT JOIN sesi_kuliah sk ON jk.id = sk.jadwal_id AND sk.status_sesi = 'selesai'
LEFT JOIN presensi_mahasiswa pm ON sk.id = pm.sesi_id AND m.id = pm.mahasiswa_id
WHERE pk.status_krs = 'Disetujui'
GROUP BY 
    jk.id, jk.kelas, jk.tahun_akademik, jk.semester_akademik,
    mk.kode_mk, mk.nama_mk, d.nama_dosen,
    m.id, m.nim, m.nama_mahasiswa;

-- 3.2 View Matriks Rekapitulasi Kehadiran Horizontal (P1 s/d P16)
CREATE OR REPLACE VIEW `v_matriks_presensi_16_pertemuan` AS
SELECT 
    jk.id AS jadwal_id,
    jk.kelas,
    mk.kode_mk,
    mk.nama_mk,
    m.nim,
    m.nama_mahasiswa,
    MAX(CASE WHEN sk.pertemuan_ke = 1  THEN pm.status_kehadiran ELSE '-' END) AS P1,
    MAX(CASE WHEN sk.pertemuan_ke = 2  THEN pm.status_kehadiran ELSE '-' END) AS P2,
    MAX(CASE WHEN sk.pertemuan_ke = 3  THEN pm.status_kehadiran ELSE '-' END) AS P3,
    MAX(CASE WHEN sk.pertemuan_ke = 4  THEN pm.status_kehadiran ELSE '-' END) AS P4,
    MAX(CASE WHEN sk.pertemuan_ke = 5  THEN pm.status_kehadiran ELSE '-' END) AS P5,
    MAX(CASE WHEN sk.pertemuan_ke = 6  THEN pm.status_kehadiran ELSE '-' END) AS P6,
    MAX(CASE WHEN sk.pertemuan_ke = 7  THEN pm.status_kehadiran ELSE '-' END) AS P7,
    MAX(CASE WHEN sk.pertemuan_ke = 8  THEN pm.status_kehadiran ELSE '-' END) AS P8,
    MAX(CASE WHEN sk.pertemuan_ke = 9  THEN pm.status_kehadiran ELSE '-' END) AS P9,
    MAX(CASE WHEN sk.pertemuan_ke = 10 THEN pm.status_kehadiran ELSE '-' END) AS P10,
    MAX(CASE WHEN sk.pertemuan_ke = 11 THEN pm.status_kehadiran ELSE '-' END) AS P11,
    MAX(CASE WHEN sk.pertemuan_ke = 12 THEN pm.status_kehadiran ELSE '-' END) AS P12,
    MAX(CASE WHEN sk.pertemuan_ke = 13 THEN pm.status_kehadiran ELSE '-' END) AS P13,
    MAX(CASE WHEN sk.pertemuan_ke = 14 THEN pm.status_kehadiran ELSE '-' END) AS P14,
    MAX(CASE WHEN sk.pertemuan_ke = 15 THEN pm.status_kehadiran ELSE '-' END) AS P15,
    MAX(CASE WHEN sk.pertemuan_ke = 16 THEN pm.status_kehadiran ELSE '-' END) AS P16,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'H' THEN 1 ELSE 0 END), 0) AS total_h,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'I' THEN 1 ELSE 0 END), 0) AS total_i,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'S' THEN 1 ELSE 0 END), 0) AS total_s,
    COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'A' THEN 1 ELSE 0 END), 0) AS total_a,
    COUNT(DISTINCT sk.id) AS total_pertemuan,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT sk.id) = 0 THEN 0.00
            ELSE (COALESCE(SUM(CASE WHEN pm.status_kehadiran = 'H' THEN 1 ELSE 0 END), 0) / COUNT(DISTINCT sk.id)) * 100 
        END, 2
    ) AS persentase_kehadiran
FROM peserta_kelas pk
JOIN jadwal_kuliah jk ON pk.jadwal_id = jk.id
JOIN mata_kuliah mk ON jk.mata_kuliah_id = mk.id
JOIN mahasiswa m ON pk.mahasiswa_id = m.id
LEFT JOIN sesi_kuliah sk ON jk.id = sk.jadwal_id AND sk.status_sesi = 'selesai'
LEFT JOIN presensi_mahasiswa pm ON sk.id = pm.sesi_id AND m.id = pm.mahasiswa_id
WHERE pk.status_krs = 'Disetujui'
GROUP BY 
    jk.id, jk.kelas, mk.kode_mk, mk.nama_mk,
    m.id, m.nim, m.nama_mahasiswa;

-- ============================================================================
-- 4. SEEDER DATA REALISTIS
-- ============================================================================

INSERT INTO `dosen` (`id`, `nidn`, `nama_dosen`, `email`, `no_hp`) VALUES
(1, '0012058801', 'Adhim Zulfa Maulana, M.Kom.', 'adhim@kampus.ac.id', '081234567890'),
(2, '0024088502', 'Dr. Siti Nurhaliza, S.T., M.T.', 'siti.nurhaliza@kampus.ac.id', '081298765432');

INSERT INTO `mata_kuliah` (`id`, `kode_mk`, `nama_mk`, `sks`, `semester`) VALUES
(1, 'TIF2026', 'Pemrograman Web Lanjut', 3, 4),
(2, 'TIF2027', 'Rekayasa Perangkat Lunak', 3, 4),
(3, 'TIF2028', 'Basis Data Terdistribusi', 3, 4);

INSERT INTO `mahasiswa` (`id`, `nim`, `nama_mahasiswa`, `prodi`, `angkatan`, `email`, `no_hp`) VALUES
(1,  '202401001', 'Ahmad Fauzul Adhim',   'Informatika', '2024', 'fauzul.adhim@student.ac.id',  '08210001001'),
(2,  '202401002', 'Budi Santoso',         'Informatika', '2024', 'budi.santoso@student.ac.id',  '08210001002'),
(3,  '202401003', 'Citra Dewi Lestari',   'Informatika', '2024', 'citra.dewi@student.ac.id',    '08210001003'),
(4,  '202401004', 'Deni Setiawan',        'Informatika', '2024', 'deni.setiawan@student.ac.id', '08210001004'),
(5,  '202401005', 'Eka Putri Rahayu',     'Informatika', '2024', 'eka.putri@student.ac.id',     '08210001005'),
(6,  '202401006', 'Fajar Ramadhan',       'Informatika', '2024', 'fajar.ramadhan@student.ac.id','08210001006'),
(7,  '202401007', 'Gita Permatasari',     'Informatika', '2024', 'gita.permata@student.ac.id',  '08210001007'),
(8,  '202401008', 'Hadi Wijaya',          'Informatika', '2024', 'hadi.wijaya@student.ac.id',   '08210001008'),
(9,  '202401009', 'Indah Kusuma Wardani', 'Informatika', '2024', 'indah.wardani@student.ac.id', '08210001009'),
(10, '202401010', 'Joko Tri Prasetyo',    'Informatika', '2024', 'joko.prasetyo@student.ac.id', '08210001010');

INSERT INTO `jadwal_kuliah` (`id`, `mata_kuliah_id`, `dosen_id`, `kelas`, `hari`, `jam_mulai`, `jam_selesai`, `ruangan`, `tahun_akademik`, `semester_akademik`) VALUES
(1, 1, 1, 'TI-4A', 'Senin', '08:00:00', '10:30:00', 'Lab Komputer 3', '2026/2027', 'Genap'),
(2, 2, 2, 'TI-4A', 'Rabu',  '10:30:00', '13:00:00', 'Ruang Teori 204', '2026/2027', 'Genap');

INSERT INTO `peserta_kelas` (`jadwal_id`, `mahasiswa_id`, `status_krs`) VALUES
(1, 1,  'Disetujui'),
(1, 2,  'Disetujui'),
(1, 3,  'Disetujui'),
(1, 4,  'Disetujui'),
(1, 5,  'Disetujui'),
(1, 6,  'Disetujui'),
(1, 7,  'Disetujui'),
(1, 8,  'Disetujui'),
(1, 9,  'Disetujui'),
(1, 10, 'Disetujui'),
(2, 1,  'Disetujui'),
(2, 2,  'Disetujui'),
(2, 3,  'Disetujui'),
(2, 4,  'Disetujui'),
(2, 5,  'Disetujui');

INSERT INTO `sesi_kuliah` (`id`, `jadwal_id`, `dosen_id`, `pertemuan_ke`, `tanggal_pertemuan`, `jam_mulai`, `jam_selesai`, `metode_kuliah`, `materi_perkuliahan`, `status_sesi`) VALUES
(1, 1, 1, 1, '2026-03-02', '08:00:00', '10:30:00', 'Tatap Muka', 'Kontrak Kuliah & Arsitektur Web Modern (MVC & RESTful API)', 'selesai'),
(2, 1, 1, 2, '2026-03-09', '08:00:00', '10:30:00', 'Tatap Muka', 'Review PHP OOP, Namespace, dan Composer Dependency Manager', 'selesai'),
(3, 1, 1, 3, '2026-03-16', '08:00:00', '10:30:00', 'Tatap Muka', 'Database Modeling & Query Optimization (MySQL Indexing)', 'selesai'),
(4, 1, 1, 4, '2026-03-23', '08:00:00', '10:30:00', 'Daring',     'Implementasi Router & Controller Architecture', 'selesai'),
(5, 1, 1, 5, '2026-03-30', '08:00:00', '10:30:00', 'Tatap Muka', 'Autentikasi & Otorisasi Pengguna (Session, JWT, Bcrypt)', 'selesai'),
(6, 1, 1, 6, '2026-04-06', '08:00:00', '10:30:00', 'Tatap Muka', 'Mekanisme CRUD Lanjut & Validasi Input Request', 'selesai'),
(7, 1, 1, 7, '2026-04-13', '08:00:00', '10:30:00', 'Daring',     'Pengolahan Data Dinamis & Integrasi Ajax / Fetch API', 'selesai'),
(8, 1, 1, 8, '2026-04-20', '08:00:00', '10:30:00', 'Tatap Muka', 'Review Pra-UTS & Evaluasi Proyek Tengah Semester', 'selesai'),
(9, 1, 1, 9, '2026-04-27', '08:00:00', '10:30:00', 'Tatap Muka', 'Integrasi Export PDF/Excel & Reporting Module', 'dibuka');

-- Pertemuan 1 s/d 9 Presensi Mahasiswa
INSERT INTO `presensi_mahasiswa` (`sesi_id`, `mahasiswa_id`, `status_kehadiran`, `catatan_keterangan`) VALUES
-- Pertemuan 1
(1, 1, 'H', NULL), (1, 2, 'H', NULL), (1, 3, 'H', NULL), (1, 4, 'H', NULL), (1, 5, 'H', NULL),
(1, 6, 'H', NULL), (1, 7, 'H', NULL), (1, 8, 'H', NULL), (1, 9, 'H', NULL), (1, 10, 'H', NULL),
-- Pertemuan 2
(2, 1, 'H', NULL), (2, 2, 'H', NULL), (2, 3, 'H', NULL), (2, 4, 'H', NULL),
(2, 5, 'I', 'Izin dispensasi kepanitiaan dies natalis kampus'),
(2, 6, 'H', NULL), (2, 7, 'H', NULL), (2, 8, 'H', NULL), (2, 9, 'H', NULL), (2, 10, 'H', NULL),
-- Pertemuan 3
(3, 1, 'H', NULL), (3, 2, 'H', NULL),
(3, 3, 'S', 'Surat Dokter No: 045/SKD/KLINIK/III/2026'),
(3, 4, 'H', NULL), (3, 5, 'H', NULL),
(3, 6, 'A', 'Tanpa keterangan / terlambat > 30 menit'),
(3, 7, 'H', NULL), (3, 8, 'H', NULL), (3, 9, 'H', NULL), (3, 10, 'H', NULL),
-- Pertemuan 4
(4, 1, 'H', NULL), (4, 2, 'H', NULL), (4, 3, 'H', NULL), (4, 4, 'H', NULL),
(4, 5, 'A', 'Tidak hadir perkuliahan online'),
(4, 6, 'A', 'Tidak hadir perkuliahan online'),
(4, 7, 'H', NULL), (4, 8, 'H', NULL), (4, 9, 'H', NULL), (4, 10, 'H', NULL),
-- Pertemuan 5
(5, 1, 'H', NULL), (5, 2, 'H', NULL), (5, 3, 'H', NULL),
(5, 4, 'I', 'Izin mendampingi keluarga opname'),
(5, 5, 'H', NULL),
(5, 6, 'S', 'Surat Keterangan Sakit Puskesmas'),
(5, 7, 'H', NULL), (5, 8, 'H', NULL), (5, 9, 'H', NULL), (5, 10, 'H', NULL),
-- Pertemuan 6
(6, 1, 'H', NULL), (6, 2, 'H', NULL), (6, 3, 'H', NULL), (6, 4, 'H', NULL),
(6, 5, 'A', 'Tanpa konfirmasi dosen'),
(6, 6, 'A', 'Tanpa konfirmasi dosen'),
(6, 7, 'H', NULL),
(6, 8, 'S', 'Surat Dokter No: 112/K-MED/IV/2026'),
(6, 9, 'H', NULL), (6, 10, 'H', NULL),
-- Pertemuan 7
(7, 1, 'H', NULL), (7, 2, 'H', NULL), (7, 3, 'H', NULL), (7, 4, 'H', NULL),
(7, 5, 'A', 'Alpa pertemuan daring ke-7'),
(7, 6, 'H', 'Hadir tepat waktu'),
(7, 7, 'H', NULL), (7, 8, 'H', NULL), (7, 9, 'H', NULL),
(7, 10, 'I', 'Izin mengikuti lomba debat mahasiswa'),
-- Pertemuan 8
(8, 1, 'H', NULL), (8, 2, 'H', NULL), (8, 3, 'H', NULL), (8, 4, 'H', NULL), (8, 5, 'H', NULL),
(8, 6, 'A', 'Tidak hadir sesi review UTS'),
(8, 7, 'H', NULL), (8, 8, 'H', NULL), (8, 9, 'H', NULL), (8, 10, 'H', NULL),
-- Pertemuan 9 (Sedang dibuka)
(9, 1, 'H', NULL), (9, 2, 'H', NULL), (9, 3, 'H', NULL), (9, 4, 'H', NULL), (9, 5, 'H', NULL),
(9, 6, 'H', NULL), (9, 7, 'H', NULL), (9, 8, 'H', NULL), (9, 9, 'H', NULL), (9, 10, 'H', NULL);

-- ============================================================================
-- 5. TAMPILKAN HASIL REKAPITULASI (AKTIF)
-- ============================================================================

-- Menampilkan Tabel Rekapitulasi & Status Kelayakan UAS
SELECT * FROM `v_rekap_presensi_mahasiswa`
WHERE `jadwal_id` = 1
ORDER BY `nim` ASC;

-- Menampilkan Tabel Matriks Pertemuan P1 - P16
SELECT * FROM `v_matriks_presensi_16_pertemuan`
WHERE `jadwal_id` = 1
ORDER BY `nim` ASC;