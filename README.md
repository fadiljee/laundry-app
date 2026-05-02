🧺 Lyra Laundry - Smart Management System

Lyra Laundry adalah aplikasi manajemen laundry modern yang menghubungkan **Admin/Kurir** dan **Pelanggan** dalam satu ekosistem digital. Aplikasi ini mempermudah pencatatan pesanan, dokumentasi timbangan, hingga pembayaran otomatis melalui QRIS.

## 🚀 Fitur Utama

### 📱 Mobile (Flutter)
- **Manajemen Pesanan:** Input pesanan baru dengan sistem kode unik.
- **Upload Timbangan:** Fitur kamera untuk mengunggah bukti foto timbangan (Auto-compressed).
- **QR Code Generator:** Menghasilkan QR Code untuk pelacakan pelanggan.
- **Pelacakan Real-time:** Status cucian yang diperbarui secara instan dari Kurir ke Pelanggan.
- **Modern UI:** Desain bersih menggunakan Google Fonts (Poppins & Inter).

### 🖥️ Backend (Laravel)
- **RESTful API:** Integrasi mulus dengan aplikasi mobile menggunakan Laravel Sanctum.
- **Sistem Pembayaran:** Integrasi Midtrans Payment Gateway (QRIS, GoPay, Bank Transfer).
- **Keamanan:** Autentikasi berbasis Bearer Token.
- **Laporan:** Fitur laporan keuangan harian dan bulanan.

---

## 🛠️ Teknologi yang Digunakan

| Komponen | Teknologi |
| :--- | :--- |
| **Mobile** | Flutter (Dart) |
| **Backend** | Laravel 11 (PHP) |
| **Database** | MySQL |
| **Payment Gateway** | Midtrans (Sandbox Mode) |
| **Auth** | Laravel Sanctum |
| **Tunneling** | Ngrok (Development) |

---

## ⚙️ Cara Instalasi

### 1. Konfigurasi Backend (Laravel)
\`\`\`bash
composer install
php artisan key:generate
php artisan migrate
php artisan storage:link
php artisan serve --host=0.0.0.0
\`\`\`
*Aktifkan Ngrok:* \`ngrok http 8000\`

### 2. Konfigurasi Mobile (Flutter)
1. Jalankan \`flutter pub get\`.
2. Buka \`order_remote_datasource.dart\`.
3. Ganti \`baseUrl\` dengan URL **Ngrok** yang sedang aktif.
4. Jalankan \`flutter run\`.

---

## 🛰️ Alur Pembayaran (Testing)
1. Pastikan URL Callback di Dashboard Midtrans sudah diatur ke:
   \`https://[URL-NGROK-KAMU]/api/payment/callback\`.
2. Gunakan Midtrans Payment Simulator untuk simulasi sukses pembayaran.

---
**Developed by Lyra Laundry Team**