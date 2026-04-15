import 'package:flutter/material.dart';

class TrackingPage extends StatelessWidget {
  final String orderId; // ID yang didapat dari link WA atau Scan

  const TrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lacak Pesanan #$orderId"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Bagian Atas: MAP (Tuntutan: Live Tracking)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 50, color: Colors.grey),
                    Text("Peta Live Tracking Kurir"),
                    Text("(Integrasi Google Maps)", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Bagian Bawah: STATUS (Tuntutan: Update Status)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status Cucian",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Progress Timeline
                  _buildStatusStep("Pesanan Diterima", "10:00 WIB", true),
                  _buildStatusStep("Sedang Dicuci", "11:30 WIB", true),
                  _buildStatusStep("Dalam Pengantaran", "Sedang Berjalan...", true, isCurrent: true),
                  _buildStatusStep("Selesai", "-", false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, String time, bool isDone, {bool isCurrent = false}) {
    return Row(
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCurrent ? Colors.blue : (isDone ? Colors.green : Colors.grey),
            ),
            Container(height: 30, width: 2, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? Colors.blue : Colors.black,
              ),
            ),
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}