import 'package:flutter/material.dart';

class CourierDashboardPage extends StatelessWidget {
  const CourierDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tugas Kurir"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 3, // Dummy: Anggap ada 3 tugas jemput/antar
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 15), // Perbaikan di sini
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ExpansionTile(
              leading: const Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
              title: Text("Pesanan #LYR-00${index + 1}"),
              subtitle: const Text("Status: Menunggu Penjemputan"),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.location_on, color: Colors.red),
                        title: Text("Alamat Pelanggan"),
                        subtitle: Text("Jl. Merdeka No. 123, Pangkalpinang"),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Tuntutan No. 4: Mulai Live Tracking
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("GPS Aktif. Memulai Tracking...")),
                                );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text("MULAI JALAN"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}