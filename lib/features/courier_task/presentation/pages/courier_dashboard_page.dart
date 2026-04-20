import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../laundry_management/presentation/pages/payment_page.dart';

class CourierDashboardPage extends StatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  State<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends State<CourierDashboardPage> {
  StreamSubscription<Position>? _positionStream;

  // 1. FUNGSI UNTUK MEMINTA IZIN GPS
  Future<void> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
  }

  // 2. FUNGSI KIRIM LOKASI KE FIREBASE (REAL-TIME)
  void _startSharingLocation(String orderId) async {
    await _checkPermission();
    
    // Setting: Update setiap pindah 10 meter
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, 
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'courier_lat': position.latitude,
          'courier_lng': position.longitude,
          'status': 'Sedang Diantar', // Otomatis ganti status
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GPS Aktif: Mengirim lokasi ke pelanggan..."), duration: Duration(seconds: 1)),
        );
      },
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Berhenti kirim GPS jika halaman ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Tugas Kurir Live", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? "Pending";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['customer_name'] ?? "Pelanggan", 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        _buildBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(data['address'] ?? "Alamat belum diatur", style: const TextStyle(color: Colors.white60)),
                    const Divider(color: Colors.white10, height: 30),
                    
                    Row(
                      children: [
                        // TOMBOL 1: MULAI ANTAR (AKTIFKAN MAP)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                            onPressed: () => _startSharingLocation(doc.id),
                            icon: const Icon(Icons.directions_bike),
                            label: const Text("Mulai Antar"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // TOMBOL 2: BAYAR (QRIS)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => PaymentPage(
                                  orderId: doc.id,
                                  weight: (data['weight'] as num).toDouble(),
                                  customerName: data['customer_name'],
                                ),
                              ));
                            },
                            icon: const Icon(Icons.qr_code),
                            label: const Text("Bayar"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
      child: Text(status, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}