import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahan Google Fonts
import 'package:intl/intl.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';
// Import halaman payment agar bisa navigasi ke sana
import 'payment_page.dart'; 

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); // Off-white/Slate-50
  static const surface     = Color(0xFFFFFFFF); // Pure White
  static const accent      = Color(0xFF2563EB); // Royal Blue
  static const border      = Color(0xFFE2E8F0); // Light Slate
  static const textMain    = Color(0xFF0F172A); // Very Dark Slate
  static const textMuted   = Color(0xFF64748B); // Medium Slate
  static const success     = Color(0xFF10B981); // Emerald Green
  static const warning     = Color(0xFFF59E0B); // Amber
  static const danger      = Color(0xFFEF4444); // Red
}

class TrackingPage extends StatefulWidget {
  final String? orderIdFromScanner;
  const TrackingPage({super.key, this.orderIdFromScanner});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  Timer? _timer;
  OrderModel? _orderData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  String _getOrderCode() {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    return args ?? widget.orderIdFromScanner ?? "";
  }

  void _startPolling() {
    _fetchOrderData(); 
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchOrderData();
    });
  }

  Future<void> _fetchOrderData() async {
    final String code = _getOrderCode().trim();
    
    if (code.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Kode Pesanan Kosong";
      });
      return;
    }

    try {
      final result = await OrderRemoteDataSource().getOrderDetail(code);
      if (!mounted) return;
      setState(() {
        _orderData = result;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_orderData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Pesanan tidak ditemukan atau koneksi bermasalah";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Ikon status bar menjadi gelap
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _T.bg,
        body: const Center(child: CircularProgressIndicator(color: _T.accent)),
      );
    }
    
    if (_errorMessage != null && _orderData == null) {
      return Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.textMain, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildEmptyState(_errorMessage!),
      );
    }

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _T.border, height: 1),
        ),
        title: Text(
          "Lacak Pesanan", 
          style: GoogleFonts.poppins(color: _T.textMain, fontSize: 17, fontWeight: FontWeight.w700)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildTrackingDetails(_orderData!),
      // --- MENAMBAHKAN TOMBOL BAYAR DI BAGIAN BAWAH (Jika Belum Lunas) ---
      bottomNavigationBar: _orderData != null && _orderData!.statusPembayaran != 'lunas'
          ? _buildPaymentAction(_orderData!)
          : null,
    );
  }

  // Widget Tombol Bayar yang melayang di bawah
 // Widget Tombol Bayar yang melayang di bawah
  Widget _buildPaymentAction(OrderModel order) {
    // KITA HITUNG MANUAL DI SINI SEPERTI DI PAYMENT PAGE
    final double hargaPerKg = 7000;
    final double calculatedTotal = order.weight * hargaPerKg;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: _T.surface,
        border: const Border(top: BorderSide(color: _T.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Tagihan:", style: GoogleFonts.inter(color: _T.textMuted, fontWeight: FontWeight.w500)),
                Text(
                  // Menggunakan calculatedTotal yang baru kita buat
                  "Rp ${NumberFormat("#,###", "id_ID").format(calculatedTotal)}",
                  style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        orderId: order.id,
                        orderCode: order.orderCode,
                        weight: order.weight,
                        customerName: order.customerName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                label: Text(
                  "BAYAR SEKARANG", 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, letterSpacing: 0.5)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingDetails(OrderModel order) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Beri padding bawah
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status Cucian", 
                      style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(order.status).withOpacity(0.2)),
                      ),
                      child: Text(
                        order.status.toUpperCase(), 
                        style: GoogleFonts.inter(color: _getStatusColor(order.status), fontWeight: FontWeight.w700, fontSize: 11)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: _T.border, height: 1),
                const SizedBox(height: 20),
                Text(
                  "No. Pesanan: ${order.orderCode}", 
                  style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700)
                ),
                const SizedBox(height: 6),
                Text(
                  "Pelanggan: ${order.customerName}",
                  style: GoogleFonts.inter(color: _T.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            "Riwayat Proses", 
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700)
          ),
          const SizedBox(height: 16),

          if (order.logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text("Belum ada update status", style: GoogleFonts.inter(color: _T.textMuted)),
              )
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: order.logs.map((log) {
                  bool isLatest = order.logs.indexOf(log) == 0;
                  bool isLast = order.logs.indexOf(log) == order.logs.length - 1;
                  String formattedTime = DateFormat('dd MMM, HH:mm').format(log.createdAt);

                  return _buildTimelineItem(
                    title: log.status,
                    message: log.message,
                    time: formattedTime,
                    isLatest: isLatest,
                    isLast: isLast,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return _T.success;
      case 'proses': return _T.warning;
      default: return _T.accent;
    }
  }

  Widget _buildTimelineItem({
    required String title, 
    required String message, 
    required String time, 
    bool isLatest = false, 
    bool isLast = false
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: isLatest ? 16 : 12,
                height: isLatest ? 16 : 12,
                margin: EdgeInsets.only(top: isLatest ? 2 : 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest ? _T.accent : _T.border,
                  border: isLatest 
                      ? Border.all(color: _T.accent.withOpacity(0.3), width: 4) 
                      : null, // Efek cincin luar pada node yang aktif
                ),
              ),
              if (!isLast) 
                Expanded(
                  child: Container(
                    width: 2, 
                    color: _T.border, // Garis penghubung terang
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  )
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time, 
                    style: GoogleFonts.inter(color: _T.textMuted, fontSize: 11, fontWeight: FontWeight.w500)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title, 
                    style: GoogleFonts.poppins(
                      fontWeight: isLatest ? FontWeight.w600 : FontWeight.w500, 
                      color: isLatest ? _T.textMain : _T.textMuted,
                      fontSize: 14
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message, 
                    style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13, height: 1.4)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _T.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 64, color: _T.border),
          ),
          const SizedBox(height: 24),
          Text(
            msg, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 14)
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), 
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.accent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
            ),
            child: Text("Scan Ulang", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600))
          )
        ],
      ),
    );
  }
}