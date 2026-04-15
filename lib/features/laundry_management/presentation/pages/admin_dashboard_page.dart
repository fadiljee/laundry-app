import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        actions: [
          // Tombol logout balik ke Landing Page (Login Page)
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'), 
            icon: const Icon(Icons.logout_rounded)
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tuntutan No. 5: Ringkasan Laporan Keuangan
            _buildFinancialSummary(),
            const SizedBox(height: 30),
            const Text(
              "Operasional",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // Tombol Input Pesanan Baru
            _buildMenuCard(
              context,
              title: "Input Pesanan Baru",
              subtitle: "Input berat & foto timbangan",
              icon: Icons.add_a_photo_rounded,
              color: Colors.blue,
              onTap: () {
                // FIXED: Navigasi ke Form Input Pesanan
                Navigator.pushNamed(context, '/add-order');
              },
            ),

            // Tombol Daftar Pesanan
            _buildMenuCard(
                context,
                title: "Daftar Pesanan",
                subtitle: "Kelola status & verifikasi bayar",
                icon: Icons.list_alt_rounded,
                color: Colors.orange,
                onTap: () {
                    // SEKARANG SUDAH BISA PINDAH PAGE
                    Navigator.pushNamed(context, '/order-list');
                },
                ),

            // Tambahan: Menu Lacak (Testing Tracking Page)
            _buildMenuCard(
              context,
              title: "Cek Tracking Pelanggan",
              subtitle: "Simulasi tampilan di HP pelanggan",
              icon: Icons.map_rounded,
              color: Colors.green,
              onTap: () {
                // FIXED: Navigasi ke Tracking Page
                Navigator.pushNamed(context, '/tracking');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Pendapatan (Bulan Ini)", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 10),
          Text(
            "Rp 4.500.000",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Divider(color: Colors.white30, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cucian Selesai: 120", style: TextStyle(color: Colors.white)),
              Text("Proses: 15", style: TextStyle(color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}