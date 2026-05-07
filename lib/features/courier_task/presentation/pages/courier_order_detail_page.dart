import 'dart:async'; // <-- TAMBAHAN UNTUK TIMER
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // <-- TAMBAHAN GEOLOCATOR
import 'package:http/http.dart' as http; // <-- TAMBAHAN HTTP

import '../../../laundry_management/data/datasources/order_remote_datasource.dart';
import '../../../laundry_management/data/models/order_model.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const success     = Color(0xFF10B981); 
  static const warning     = Color(0xFFF59E0B); 
  static const danger      = Color(0xFFEF4444); 
}

class CourierOrderDetailPage extends StatefulWidget {
  final OrderModel order;

  const CourierOrderDetailPage({super.key, required this.order});

  @override
  State<CourierOrderDetailPage> createState() => _CourierOrderDetailPageState();
}

class _CourierOrderDetailPageState extends State<CourierOrderDetailPage> {
  late String _currentStatus;
  bool _isUpdating = false;
  
  // Variabel untuk menyimpan Timer Broadcast Lokasi
  Timer? _locationTimer;

  final List<String> _statusOptions = [
    'Lunas - Siap Jemput',
    'Proses Jemput',
    'Tiba di Laundry',
    'Proses Cuci',
    'Proses Antar',
    'Selesai'
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    
    // Mulai fungsi broadcast saat halaman dibuka
    _startBroadcastingLocation();
  }

  @override
  void dispose() {
    // WAJIB DIMATIKAN AGAR TIDAK BERJALAN TERUS DI BACKGROUND & BIKIN HP PANAS
    _locationTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  LOGIC: KIRIM LOKASI KURIR KE SERVER (Setiap 10 Detik)
  // ─────────────────────────────────────────────────────────────
  void _startBroadcastingLocation() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_currentStatus == 'Proses Jemput' || _currentStatus == 'Proses Antar') {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) return;

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) return;
          }

          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

          final url = Uri.parse('https://lyra.biz.id/api/orders/${widget.order.orderCode}/update-location');
          
          // --- REVISI PENTING DI SINI ---
          final response = await http.put(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json', // Wajib ada agar Laravel bisa baca method PUT
            },
            body: jsonEncode({ // Wajib di-encode ke JSON
              'lat': position.latitude,
              'lng': position.longitude,
            }),
          );
          
          // Cek jawaban dari Laravel
          if (response.statusCode == 200) {
            debugPrint("Sukses masuk Database! Kordinat: ${position.latitude}, ${position.longitude}");
          } else {
            debugPrint("Ditolak Laravel (Error ${response.statusCode}): ${response.body}");
          }

        } catch (e) {
          debugPrint("Gagal kirim lokasi: $e");
        }
      }
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_currentStatus == newStatus) return;

    setState(() => _isUpdating = true);

    try {
      await OrderRemoteDataSource().updateOrderStatus(widget.order.id, newStatus);
      
      if (!mounted) return;
      setState(() {
        _currentStatus = newStatus;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status berhasil diubah ke: $newStatus", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: _T.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal ubah status: $e", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: _T.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openMap(String addressText) async {
    String cleanAddress = addressText.replaceAll(RegExp(r'\(?http:\/\/googleusercontent[^\s]+\)?'), '').trim();

    final RegExp mapsUrlRegExp = RegExp(
      r'(https?:\/\/(?:maps\.app\.goo\.gl|goo\.gl\/maps|maps\.google\.com|www\.google\.com\/maps)[^\s]+)',
      caseSensitive: false,
    );
    
    final match = mapsUrlRegExp.firstMatch(cleanAddress);
    Uri mapUri;

    if (match != null) {
      mapUri = Uri.parse(match.group(0)!);
    } else {
      final encodedAddress = Uri.encodeComponent(cleanAddress);
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    }

    try {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps. Pastikan aplikasi terinstal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _T.textMain),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, true), 
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          title: Text(
            "Detail Pesanan", 
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18)
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUpdateStatusCard(),
              const SizedBox(height: 24),
              
              Text("Informasi Pelanggan", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              
              _buildCustomerInfoCard(),
              const SizedBox(height: 24),

              Text("Detail Cucian", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              
              _buildLaundryInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateStatusCard() {
    bool isDone = _currentStatus.toLowerCase() == 'selesai';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.orderCode,
                style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              _buildStatusBadge(_currentStatus),
            ],
          ),
          // INDIKATOR LIVE TRACKING (Muncul kalau kurir sedang OTW)
          if (_currentStatus == 'Proses Jemput' || _currentStatus == 'Proses Antar') ...[
             const SizedBox(height: 12),
             Row(
               children: [
                 const SizedBox(
                   width: 12, height: 12,
                   child: CircularProgressIndicator(strokeWidth: 2, color: _T.warning),
                 ),
                 const SizedBox(width: 8),
                 Text("Membagikan lokasi ke pelanggan...", style: GoogleFonts.inter(fontSize: 11, color: _T.warning, fontWeight: FontWeight.w600)),
               ],
             ),
          ],
          if (!isDone) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: _T.border, height: 1),
            ),
            Text(
              "UPDATE STATUS PESANAN", 
              style: GoogleFonts.inter(color: _T.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _T.bg, 
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _T.border)
              ),
              child: _isUpdating
                  ? const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _T.accent))),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusOptions.contains(_currentStatus) ? _currentStatus : _statusOptions[0],
                        isExpanded: true,
                        dropdownColor: _T.surface,
                        icon: const Icon(Icons.expand_more_rounded, color: _T.textMuted),
                        style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w600, fontSize: 15),
                        items: _statusOptions.map((String status) {
                          return DropdownMenuItem<String>(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) _updateStatus(newValue);
                        },
                      ),
                    ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.person_rounded, "Nama", widget.order.customerName),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: _T.border, height: 1)),
          
          _buildDetailRow(Icons.phone_rounded, "WhatsApp", widget.order.waNumber ?? "-"),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: _T.border, height: 1)),
          
          _buildDetailRow(Icons.location_on_rounded, "Alamat", widget.order.address, isAddress: true),
          
          const SizedBox(height: 20),
          
          GestureDetector(
            onTap: () => _openMap(widget.order.address),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _T.accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _T.accent.withOpacity(0.2), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: -10,
                    bottom: -20,
                    child: Icon(
                      Icons.map_rounded, 
                      size: 100, 
                      color: _T.accent.withOpacity(0.1)
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _T.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _T.accent.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_rounded, color: _T.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Buka Navigasi Maps", 
                          style: GoogleFonts.inter(color: _T.accent, fontWeight: FontWeight.w600, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaundryInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.local_laundry_service_rounded, "Layanan", widget.order.service),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: _T.border, height: 1)),
          _buildDetailRow(Icons.scale_rounded, "Berat", "${widget.order.weight} Kg"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isAddress = false}) {
    return Row(
      crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _T.accent.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: _T.accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value, 
                style: GoogleFonts.inter(color: _T.textMain, fontSize: 14, fontWeight: FontWeight.w600, height: isAddress ? 1.5 : 1.0)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status.toLowerCase().contains('selesai') ? _T.success 
                : status.toLowerCase().contains('proses') ? _T.warning 
                : _T.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(status, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}