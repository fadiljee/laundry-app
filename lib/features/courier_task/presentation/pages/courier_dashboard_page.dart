import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart'; // Pastikan package ini ada
import '../../../../core/providers/auth_provider.dart';
import '../../../laundry_management/data/datasources/order_remote_datasource.dart';
import '../../../laundry_management/data/models/order_model.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); // Off-white/Slate-50
  static const surface     = Color(0xFFFFFFFF); // Pure White
  static const accent      = Color(0xFF2563EB); // Royal Blue
  static const accentDark  = Color(0xFF1D4ED8); // Darker Blue
  static const border      = Color(0xFFE2E8F0); // Light Slate
  static const textMain    = Color(0xFF0F172A); // Very Dark Slate
  static const textMuted   = Color(0xFF64748B); // Medium Slate
  static const success     = Color(0xFF10B981); // Emerald Green
  static const warning     = Color(0xFFF59E0B); // Amber
  static const danger      = Color(0xFFEF4444); // Red
}

class CourierDashboardPage extends StatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  State<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends State<CourierDashboardPage> {
  Timer? _timer;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  int _lastTaskCount = 0; 

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
    _fetchData(); 

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchData(isAutoRefresh: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  Future<void> _fetchData({bool isAutoRefresh = false}) async {
    try {
      final orders = await OrderRemoteDataSource().getAllOrders();
      
      if (!mounted) return;

      int currentTaskCount = orders.where((o) => 
        o.status == 'Lunas - Siap Jemput' || 
        o.status == 'Proses Antar' || 
        o.status == 'Proses Jemput'
      ).length;

      if (isAutoRefresh && currentTaskCount > _lastTaskCount) {
        _playNotificationSound();
      }

      setState(() {
        _orders = orders;
        _lastTaskCount = currentTaskCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!isAutoRefresh && mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Gagal memuat data: $e", isError: true);
      }
    }
  }

  void _playNotificationSound() {
    FlutterRingtonePlayer().playNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "ADA TUGAS BARU!\nSilakan cek daftar pesanan.",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _T.warning, 
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AuthStorage.clearToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _updateStatus(int orderId, String currentStatus, String newStatus) async {
    if (currentStatus == newStatus) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: _T.accent)),
    );

    try {
      await OrderRemoteDataSource().updateOrderStatus(orderId, newStatus);
      if (!mounted) return;
      Navigator.pop(context); 
      
      _showSnackBar("Status diubah ke: $newStatus");
      _fetchData(); 
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Gagal ubah status: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: isError ? _T.danger : _T.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Ikon status bar gelap
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent, // Mencegah warna berubah saat di-scroll
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          title: Text(
            "Tugas Kurir", 
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18)
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: _T.danger),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _T.accent))
            : RefreshIndicator(
                onRefresh: () async => _fetchData(),
                color: _T.accent,
                backgroundColor: _T.surface,
                child: _orders.isEmpty 
                    ? _buildEmptyState() 
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          return _buildCourierCard(_orders[index]);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildCourierCard(OrderModel order) {
    bool isDone = order.status.toLowerCase() == 'selesai';

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID & Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _T.bg, // Sedikit abu-abu agar kontras dengan badan card putih
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderCode, 
                    style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 14)
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
            ),
            
            // Body: Customer Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, color: _T.accent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        order.customerName, 
                        style: GoogleFonts.inter(color: _T.textMain, fontSize: 15, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: _T.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          order.address, 
                          style: GoogleFonts.inter(color: _T.textMuted, height: 1.5, fontSize: 13)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer: Tombol Update Status (Hanya jika belum selesai)
            if (!isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _T.border))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "UPDATE STATUS PESANAN", 
                      style: GoogleFonts.inter(
                        color: _T.textMuted, 
                        fontSize: 10, 
                        fontWeight: FontWeight.w700, 
                        letterSpacing: 1.0
                      )
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _T.bg, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _T.border)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusOptions.contains(order.status) ? order.status : _statusOptions[0],
                          isExpanded: true,
                          dropdownColor: _T.surface,
                          icon: const Icon(Icons.expand_more_rounded, color: _T.textMuted),
                          style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w500),
                          items: _statusOptions.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status, 
                              child: Text(status)
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) _updateStatus(order.id, order.status, newValue);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(20), // Dibuat lebih membulat (pill shape)
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status, 
        style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.check_circle_outline_rounded, size: 80, color: _T.success),
          ),
          const SizedBox(height: 24),
          Text(
            "Kerjaan Beres!", 
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 18, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 8),
          Text(
            "Belum ada tugas penjemputan/pengantaran.", 
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13)
          ),
        ],
      ),
    );
  }
}