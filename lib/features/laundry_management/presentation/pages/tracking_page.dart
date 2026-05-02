import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';
import 'payment_page.dart';
import 'package:laundry_app/features/order_tracking/presentation/pages/LiveMapTrackingPage.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
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
      setState(() { _isLoading = false; _errorMessage = "Kode Pesanan Kosong"; });
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
        setState(() { _isLoading = false; _errorMessage = "Pesanan tidak ditemukan"; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) return Scaffold(backgroundColor: _T.bg, body: const Center(child: CircularProgressIndicator(color: _T.accent)));
    if (_errorMessage != null && _orderData == null) return Scaffold(backgroundColor: _T.bg, body: _buildEmptyState(_errorMessage!));

    final String payStatus = _orderData!.statusPembayaran.toLowerCase();
    final String mainStatus = _orderData!.status.toLowerCase();

    final bool isPaid = payStatus.contains('lunas') || mainStatus.contains('lunas');
    final bool isFinished = mainStatus.contains('selesai');

    bool showPaymentButton = !isPaid && !isFinished;

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        title: Text("Lacak Pesanan", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.textMain, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _buildTrackingDetails(_orderData!),
      bottomNavigationBar: showPaymentButton ? _buildPaymentAction(_orderData!) : null,
    );
  }

  Widget _buildTrackingDetails(OrderModel order) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainOrderCard(order),
          
          // --- TOMBOL MAPS MUNCUL DI BAWAH KARTU RESI ---
          _buildLiveTrackingMapButton(order),

          const SizedBox(height: 24),
          _buildPhotoWeightCard(order),
          const SizedBox(height: 32),
          Text("Riwayat Proses", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildTimelineCard(order),
        ],
      ),
    );
  }

  // --- WIDGET BARU: TOMBOL MENUJU LIVE MAP ---
  Widget _buildLiveTrackingMapButton(OrderModel order) {
    final String mainStatus = order.status.toLowerCase();
    // Tombol hanya muncul kalau kurir sedang bergerak
    final bool isCourierMoving = mainStatus.contains('proses jemput') || mainStatus.contains('proses antar');

    if (!isCourierMoving) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: _T.warning.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
          ]
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Lempar kode pesanan ke halaman Map
                builder: (context) => LiveMapTrackingPage(orderCode: order.orderCode),
              ),
            );
          },
          icon: const Icon(Icons.map_rounded, color: Colors.white),
          label: Text(
            "Lihat Posisi Kurir di Peta", 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.warning, // Pakai warna warning (Orange/Kuning) agar mencolok
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildMainOrderCard(OrderModel order) {
    final bool isPaid = order.statusPembayaran.trim().toLowerCase() == 'lunas';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Status Cucian", style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              _buildBadge(order.status),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: _T.border, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("No: ${order.orderCode}", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _T.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 12, color: _T.success),
                      const SizedBox(width: 4),
                      Text("LUNAS", style: GoogleFonts.inter(color: _T.success, fontWeight: FontWeight.w800, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text("Pelanggan: ${order.customerName}", style: GoogleFonts.inter(color: _T.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPhotoWeightCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.scale_rounded, color: _T.accent, size: 20),
              const SizedBox(width: 8),
              Text("Bukti Timbangan", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text("${order.weight} Kg", style: GoogleFonts.poppins(color: _T.accent, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: order.imageUrl != null && order.imageUrl!.isNotEmpty
                ? Image.network(
                    order.imageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder("Gagal memuat bukti foto"),
                  )
                : _buildImagePlaceholder("Foto timbangan belum tersedia"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(OrderModel order) {
    if (order.logs.isEmpty) return const Center(child: Text("Belum ada riwayat"));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _T.border)),
      child: Column(
        children: order.logs.map((log) {
          return _buildTimelineItem(
            title: log.status,
            message: log.message,
            time: DateFormat('dd MMM, HH:mm').format(log.createdAt),
            isLatest: order.logs.indexOf(log) == 0,
            isLast: order.logs.indexOf(log) == order.logs.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentAction(OrderModel order) {
    final double calculatedTotal = order.weight * 7000;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: _T.surface,
        border: const Border(top: BorderSide(color: _T.border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Tagihan:", style: GoogleFonts.inter(color: _T.textMuted, fontWeight: FontWeight.w500)),
                Text("Rp ${NumberFormat("#,###", "id_ID").format(calculatedTotal)}", style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(orderId: order.id, orderCode: order.orderCode, weight: order.weight, customerName: order.customerName))),
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                label: Text("BAYAR SEKARANG", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: _T.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String label) {
    return Container(height: 150, width: double.infinity, color: _T.bg, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.image_not_supported_rounded, color: _T.border, size: 40), const SizedBox(height: 8), Text(label, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12))]));
  }

  Widget _buildTimelineItem({required String title, required String message, required String time, bool isLatest = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(width: isLatest ? 16 : 12, height: isLatest ? 16 : 12, margin: EdgeInsets.only(top: isLatest ? 2 : 4), decoration: BoxDecoration(shape: BoxShape.circle, color: isLatest ? _T.accent : _T.border, border: isLatest ? Border.all(color: _T.accent.withOpacity(0.3), width: 4) : null)),
            if (!isLast) Expanded(child: Container(width: 2, color: _T.border, margin: const EdgeInsets.symmetric(vertical: 4))),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(time, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.poppins(fontWeight: isLatest ? FontWeight.w600 : FontWeight.w500, color: isLatest ? _T.textMain : _T.textMuted, fontSize: 14)),
            const SizedBox(height: 4),
            Text(message, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13, height: 1.4)),
          ]))),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color color = status.toLowerCase().contains('selesai') ? _T.success : status.toLowerCase().contains('proses') ? _T.warning : _T.accent;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))), child: Text(status.toUpperCase(), style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 11)));
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: _T.surface, shape: BoxShape.circle), child: const Icon(Icons.search_off_rounded, size: 64, color: _T.border)), const SizedBox(height: 24), Text(msg, textAlign: TextAlign.center, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 14)), const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _T.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: Text("Scan Ulang", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)))]));
  }
}