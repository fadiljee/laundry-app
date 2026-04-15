import 'package:flutter/material.dart';
import 'qr_scanner_page.dart'; // Pastikan file scanner sudah dibuat

class CustomerLandingPage extends StatelessWidget {
  const CustomerLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bagian Atas: Ikon dan Branding
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Lyra Laundry",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Lacak cucian Anda secara real-time.\nCukup scan nota tanpa perlu login.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Bagian Tengah: Tombol Aksi Utama (Scan)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Navigasi ke halaman scanner
                    final String? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QrScannerPage(),
                      ),
                    );

                    // Logika jika hasil scan didapat
                    if (result != null && context.mounted) {
                      _showResultDialog(context, result);
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                  label: const Text(
                    "SCAN NOTA SEKARANG",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.blue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bagian Bawah: Opsi Login Admin/Kurir
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Bukan pelanggan? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Masuk Staff",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog sementara untuk testing hasil scan
  void _showResultDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Berhasil!"),
          ],
        ),
        content: Text("ID Pesanan ditemukan: $code\n\nMenghubungkan ke sistem tracking..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}