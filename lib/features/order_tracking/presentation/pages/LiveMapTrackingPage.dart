import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart'; // Package peta gratis
import 'package:latlong2/latlong.dart';        // Package kordinat gratis
import 'package:http/http.dart' as http;

class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
}

class LiveMapTrackingPage extends StatefulWidget {
  final String orderCode;
  
  const LiveMapTrackingPage({super.key, required this.orderCode});

  @override
  State<LiveMapTrackingPage> createState() => _LiveMapTrackingPageState();
}

class _LiveMapTrackingPageState extends State<LiveMapTrackingPage> {
  final MapController _mapController = MapController();
  
  Timer? _pollingTimer;
  bool _isLoading = true;
  
  // Posisi Default (Bandung)
  final LatLng _initialPosition = const LatLng(-6.914744, 107.609810);

  List<Marker> _markers = [];
  
  LatLng? _courierPosition;
  LatLng? _customerPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocations(); 
    
    // Auto-refresh lokasi kurir setiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLocations(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); 
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations({bool isBackground = false}) async {
    try {
      // GANTI IP DENGAN IP LAPTOP KAMU
      final url = Uri.parse('http://192.168.1.9:8000/api/orders/${widget.orderCode}');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        
        final double? courierLat = double.tryParse(data['courier_lat']?.toString() ?? '');
        final double? courierLng = double.tryParse(data['courier_lng']?.toString() ?? '');
        
        final double? customerLat = double.tryParse(data['customer_lat']?.toString() ?? '');
        final double? customerLng = double.tryParse(data['customer_lng']?.toString() ?? '');

        if (courierLat != null && courierLng != null) {
          _courierPosition = LatLng(courierLat, courierLng);
        }
        
        if (customerLat != null && customerLng != null) {
          _customerPosition = LatLng(customerLat, customerLng);
        }

        _updateMarkers();
        
        if (!isBackground) {
          setState(() => _isLoading = false);
          // Kasih jeda sedikit agar map selesai di-render sebelum digeser
          Future.delayed(const Duration(milliseconds: 500), _moveCameraToFit);
        }
      }
    } catch (e) {
      debugPrint("Gagal update lokasi: $e");
    }
  }

  void _updateMarkers() {
    final List<Marker> newMarkers = [];

    // Marker Pelanggan (Rumah)
    if (_customerPosition != null) {
      newMarkers.add(
        Marker(
          width: 50.0, height: 50.0,
          point: _customerPosition!,
          child: const Column(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 35),
            ],
          ),
        ),
      );
    }

    // Marker Kurir (Motor)
    if (_courierPosition != null) {
      newMarkers.add(
        Marker(
          width: 60.0, height: 60.0,
          point: _courierPosition!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: _T.accent, size: 30),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _moveCameraToFit() {
    // 1. Jika kordinat Kurir DAN Pelanggan ada, posisikan kamera di tengah-tengah keduanya
    if (_courierPosition != null && _customerPosition != null) {
      final bounds = LatLngBounds.fromPoints([_courierPosition!, _customerPosition!]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60.0), 
        ),
      );
    } 
    // 2. Jika cuma kordinat Kurir yang ada, ikuti kurirnya saja (Zoom level 16)
    else if (_courierPosition != null) {
      _mapController.move(_courierPosition!, 16.0);
    } 
    // 3. Jika cuma kordinat Pelanggan yang ada, fokus ke rumah pelanggan
    else if (_customerPosition != null) {
      _mapController.move(_customerPosition!, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _T.surface,
        iconTheme: const IconThemeData(color: _T.textMain),
        title: Text("Live Tracking Kurir", style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _T.accent))
        : Stack(
            children: [
              // WIDGET PETA OPENSTREETMAP (100% GRATIS)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _customerPosition ?? _initialPosition,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.laundry_app.app', // Ganti sesuai nama package aplikasi kamu
                  ),
                  MarkerLayer(
                    markers: _markers,
                  ),
                ],
              ),
              
              // Kartu Status di bawah
              Positioned(
                bottom: 30, left: 20, right: 20,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.two_wheeler_rounded, color: _T.accent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Kurir Menuju Lokasi Anda", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Posisi diperbarui otomatis secara real-time.", style: GoogleFonts.inter(fontSize: 11, color: _T.textMuted)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _T.surface,
        onPressed: _moveCameraToFit,
        child: const Icon(Icons.center_focus_strong_rounded, color: _T.accent),
      ),
    );
  }
}