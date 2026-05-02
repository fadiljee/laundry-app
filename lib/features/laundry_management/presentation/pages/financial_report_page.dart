import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider.dart';

// --- DESIGN TOKENS ---
class _T {
  static const bg          = Color(0xFFF1F5F9);
  static const surface     = Color(0xFFFFFFFF);
  static const accent      = Color(0xFF2563EB);
  static const border      = Color(0xFFE2E8F0);
  static const textMain    = Color(0xFF0F172A);
  static const textMuted   = Color(0xFF64748B);
  static const success     = Color(0xFF10B981);
}

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? reportData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      String? token = await AuthStorage.getToken();
      
      // ✅ Menggunakan endpoint ASLI bawaan kamu
      final response = await http.get(
        Uri.parse('http://192.168.1.9:8000/api/reports/financial'), 
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          reportData = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data (Status: ${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        title: Text("Analisis Keuangan", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _T.textMain, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _T.accent,
          unselectedLabelColor: _T.textMuted,
          indicatorColor: _T.accent,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: "Harian"),
            Tab(text: "Mingguan"),
            Tab(text: "Bulanan"),
          ],
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: _T.accent)) 
        : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage, style: GoogleFonts.inter(color: Colors.red)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailedTab("daily"),
                  _buildDetailedTab("weekly"),
                  _buildDetailedTab("monthly"),
                ],
              ),
    );
  }

  Widget _buildDetailedTab(String type) {
    // ✅ FITUR AMAN: Cek otomatis apakah data dari server berupa angka tunggal atau rincian detail
    final rawData = reportData?[type];
    
    double totalRevenue = 0;
    int totalOrders = 0;
    List breakdown = [];

    if (rawData is num) {
      // Jika server cuma ngirim angka (misal: 150000)
      totalRevenue = rawData.toDouble();
    } else if (rawData is Map<String, dynamic>) {
      // Jika suatu saat server diupdate ngirim rincian
      totalRevenue = (rawData['total_revenue'] ?? rawData['revenue'] ?? 0).toDouble();
      totalOrders = rawData['total_orders'] ?? rawData['orders'] ?? 0;
      breakdown = rawData['breakdown'] ?? rawData['recent_transactions'] ?? [];
    }

    return RefreshIndicator(
      onRefresh: _fetchReport,
      color: _T.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Kartu Total Pendapatan
          _buildSummaryHeader(totalRevenue, totalOrders, type),
          
          const SizedBox(height: 24),
          
          // 2. Judul Rincian
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Riwayat Transaksi", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
              if (breakdown.isNotEmpty)
                Text("${breakdown.length} Catatan", style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),

          // 3. List Breakdown
          breakdown.isEmpty 
            ? _buildEmptyState()
            : Column(
                children: breakdown.map((item) => _buildBreakdownItem(item)).toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double total, int orders, String type) {
    String label = type == "daily" ? "Hari Ini" : type == "weekly" ? "Minggu Ini" : "Bulan Ini";
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.accent, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _T.accent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Pendapatan $label", style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 8),
          Text(formatRupiah(total), style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniInfo(Icons.check_circle_outline, "Data Tersinkron"),
              // Jika order > 0 (karena server mengirim data order), tampilkan
              if (orders > 0) ...[
                const SizedBox(width: 16),
                _buildMiniInfo(Icons.shopping_bag_outlined, "$orders Order"),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(dynamic item) {
    // Antisipasi format data item dari server
    String label = item['label'] ?? item['date'] ?? item['id'] ?? 'Transaksi';
    double revenue = (item['revenue'] ?? item['amount'] ?? 0).toDouble();
    String orders = item['orders'] != null ? "${item['orders']} Transaksi" : "Selesai";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          Container(
            height: 48, width: 48,
            decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.receipt_long_rounded, color: _T.accent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _T.textMain)),
                const SizedBox(height: 2),
                Text(orders, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(formatRupiah(revenue), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _T.success)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: _T.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("Detail transaksi dari server belum tersedia.", 
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13), textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}