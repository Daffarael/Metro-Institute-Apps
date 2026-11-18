# 🚀 Metro Meet Auto Attendance - Chrome Extension

Ekstensi Chrome resmi khusus platform **Metro Institute** untuk mencatat presensi kehadiran Google Meet secara **100% Otomatis (Auto-POST)** langsung ke database server tanpa perlu mengunduh atau mengunggah file CSV manual.

---

## ⚡ Fitur Utama

1. **Auto-Detect Peserta Real-time**: Mendeteksi seluruh peserta Google Meet, baik dari video tiles maupun panel daftar orang (*People panel*).
2. **Durasi Aktif Presisi**: Menghitung lama menit tiap peserta aktif di dalam ruangan.
3. **Pencocokan Cerdas (Smart Matching)**:
   - Mencocokkan data via **Email Mentee** atau **Nama Lengkap / Display Name** yang terdaftar di Bootcamp & Webinar Metro Institute.
4. **100% Hands-Free Auto-POST**:
   - Begitu tombol **Tutup Panggilan (Leave Call)** diklik oleh mentor/admin atau tab ditutup, data presensi langsung di-POST ke Webhook API Metro Institute (`/api/v1/webhook/google-meet`) menggunakan browser `fetch` `keepalive`.
5. **Modern In-Meet Floating Widget**:
   - Muncul di sudut kiri bawah layar Google Meet dengan nuansa khas Metro Institute (Forest Green `#018556` & Neon Mint `#0df293`).
   - Menyediakan tombol manual **"🚀 Kirim Presensi Sekarang"** jika ingin mengirim sebelum keluar.
   - Menyediakan tombol cadangan **"📥 Download CSV"**.
6. **Uji Koneksi 1-Klik**:
   - Popup extension dilengkapi tombol test koneksi untuk memastikan server siap menerima data.

---

## 📦 Cara Memasang di Google Chrome (Hanya 30 Detik)

1. Buka browser **Google Chrome**.
2. Masuk ke halaman ekstensi dengan mengetikkan di address bar:
   ```text
   chrome://extensions
   ```
3. Di pojok kanan atas, aktifkan toggle **Mode Pengembang** (*Developer mode*).
4. Klik tombol **Muat yang belum dibongkar** (*Load unpacked*) di pojok kiri atas.
5. Pilih folder:
   ```text
   e:\Metro Institute Season 2\Metro Institute Apps\extensions\metro-meet-sync
   ```
6. Selesai! Ikon perisai **Metro Meet Sync** akan muncul di bar ekstensi Chrome Anda.

---

## ⚙️ Pengaturan Endpoint & Secret

Klik ikon **Metro Meet Sync** di bar ekstensi:
- **Production URL**: `https://api.metroinstitute.site/api/v1/webhook/google-meet` (Default)
- **Localhost URL**: `http://localhost:5000/api/v1/webhook/google-meet` (Untuk pengujian lokal)
- **Secret Key**: `metro-meet-secret-2026`
- **Auto-POST**: Centang (*default: aktif*)
- Klik **"⚡ Uji Koneksi"** untuk memverifikasi backend siap menerima webhook.

---

## 🛡️ Hak Akses & Privasi
Ekstensi ini dibuat khusus untuk keperluan internal Metro Institute dan hanya berjalan pada domain `https://meet.google.com/*` serta hanya mengirimkan data ke endpoint Metro Institute.
