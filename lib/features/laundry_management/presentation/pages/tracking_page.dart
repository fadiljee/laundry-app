import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingPage extends StatefulWidget {
  final String? orderIdFromScanner;
  const TrackingPage({super.key, this.orderIdFromScanner});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final String orderId = widget.orderIdFromScanner ?? "";

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          // Ambil koordinat kurir dari Firebase
          // Default ke Jakarta jika data koordinat belum ada
          double lat = data['courier_lat'] ?? -6.2000; 
          double lng = data['courier_lng'] ?? 106.8166;
          LatLng courierLocation = LatLng(lat, lng);

          // Pindahkan kamera map otomatis saat kurir bergerak
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(courierLocation));
          }

          return Stack(
            children: [
              // 1. LAYER MAP (BACKGROUND)
              GoogleMap(
                initialCameraPosition: CameraPosition(target: courierLocation, zoom: 15),
                onMapCreated: (controller) => _mapController = controller,
                markers: {
                  Marker(
                    markerId: const MarkerId("courier"),
                    position: courierLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    infoWindow: const InfoWindow(title: "Posisi Kurir"),
                  ),
                },
              ),

              // 2. LAYER DETAIL (DRAGGABLE SHEET) - Biar ala Shopee
              DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.15,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Center(child: Container(width: 50, height: 5, color: Colors.grey[300])),
                        const SizedBox(height: 20),
                        Text("Status: ${data['status']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFEE4D2D))),
                        const Divider(),
                        // Tambahkan widget _buildTrackingItem (Timeline Shopee) di sini
                        const Text("Lini Masa Pengiriman", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildSimpleTimeline(data['tracking_history'] ?? []),
                      ],
                    ),
                  );
                },
              ),

              // Tombol Kembali
              Positioned(
                top: 50,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleTimeline(List<dynamic> logs) {
    // Gunakan logika UI Shopee yang sudah kita buat sebelumnya di sini
    return const Text("Detail perjalanan akan muncul di sini...");
  }
}