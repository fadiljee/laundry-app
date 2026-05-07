import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../../../core/providers/auth_provider.dart';
import '../../../laundry_management/data/datasources/order_remote_datasource.dart';
import '../../../laundry_management/data/models/order_model.dart';
import 'courier_order_detail_page.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const accentDark  = Color(0xFF1D4ED8); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const success     = Color(0xFF10B981); 
  static const warning     = Color(0xFFF59E0B); 
  static const danger      = Color(0xFFEF4444); 
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
  bool _hasNotifiedInitial = false; // Flag agar pengingat cuma bunyi sekali saat masuk

  @override
  void initState() {
    super.initState();
    _fetchData(); 

    // Auto-refresh setiap 10 detik untuk cek tugas baru dari Admin
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
      final allOrders = await OrderRemoteDataSource().getOrders();
      
      if (!mounted) return;

      // FILTER: Hanya tugas yang perlu tindakan kurir di lapangan
      final taskForCourier = allOrders.where((o) {
        return o.status == 'Lunas - Siap Jemput' || 
               o.status == 'Proses Jemput' || 
               o.status == 'Proses Antar';
      }).toList();

      // ─────────────────────────────────────────────────────────────
      //  LOGIKA NOTIFIKASI (SUARA & SNACKBAR)
      // ─────────────────────────────────────────────────────────────
      
      // 1. PENGINGAT: Jika baru masuk halaman & ada tugas mangkrak
      if (!isAutoRefresh && taskForCourier.isNotEmpty && !_hasNotifiedInitial) {
        _hasNotifiedInitial = true; 
        Future.delayed(const Duration(milliseconds: 800), () {
           _playNotificationSound(isReminder: true, count: taskForCourier.length);
        });
      }

      // 2. TUGAS BARU: Jika sedang buka halaman & Admin nambah tugas baru
      if (isAutoRefresh && taskForCourier.length > _lastTaskCount) {
        _playNotificationSound(isReminder: false);
      }

      setState(() {
        _orders = taskForCourier;
        _lastTaskCount = taskForCourier.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!isAutoRefresh && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playNotificationSound({bool isReminder = false, int count = 0}) {
    // Bunyi notifikasi sistem
    FlutterRingtonePlayer().playNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isReminder ? Icons.assignment_late_rounded : Icons.notifications_active_rounded, 
              color: Colors.white
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isReminder 
                  ? "PENGINGAT: Kamu masih punya $count tugas aktif!" 
                  : "ADA TUGAS BARU!\nCek daftar penjemputan/pengantaran.",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isReminder ? _T.danger : _T.warning, 
        duration: const Duration(seconds: 4),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          title: Text(
            "Tugas Aktif Kurir", 
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18)
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: _T.danger),
              onPressed: _handleLogout,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final bool? isUpdated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CourierOrderDetailPage(order: order)),
            );
            
            if (isUpdated == true) {
              _fetchData();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: _T.bg,
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _T.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        order.status == 'Proses Antar' 
                          ? Icons.local_shipping_rounded 
                          : Icons.shopping_basket_rounded, 
                        color: _T.accent, 
                        size: 24
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName, 
                            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 15, fontWeight: FontWeight.w600)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.address, 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _T.border, size: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status.toLowerCase().contains('siap') ? _T.danger 
                : status.toLowerCase().contains('proses') ? _T.warning 
                : _T.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
            decoration: const BoxDecoration(color: _T.surface, shape: BoxShape.circle),
            child: const Icon(Icons.assignment_turned_in_rounded, size: 80, color: _T.success),
          ),
          const SizedBox(height: 24),
          Text(
            "Semua Tugas Beres!", 
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 18, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 8),
          Text(
            "Istirahat dulu, belum ada jemputan/antaran baru.", 
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13)
          ),
        ],
      ),
    );
  }
}