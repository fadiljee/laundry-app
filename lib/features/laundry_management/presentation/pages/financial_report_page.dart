import 'dart:convert';
import 'dart:math' as math; // Tambahan untuk kalkulasi grafik
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahan Google Fonts
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC);
  static const surface     = Color(0xFFFFFFFF);
  static const accent      = Color(0xFF2563EB); // Royal Blue
  static const border      = Color(0xFFE2E8F0);
  static const textMain    = Color(0xFF0F172A);
  static const textMuted   = Color(0xFF64748B);
  
  // Warna khusus untuk metrik laporan
  static const cDaily      = Color(0xFF10B981); // Emerald Green
  static const cWeekly     = Color(0xFF3B82F6); // Blue
  static const cMonthly    = Color(0xFF8B5CF6); // Purple
  static const cYearly     = Color(0xFFF59E0B); // Amber
}

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  Map<String, dynamic>? reportData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      String? token = await AuthStorage.getToken();
      final response = await http.get(
        Uri.parse('https://prize-pancake-spore.ngrok-free.dev/api/reports/financial'), 
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          reportData = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        print("STATUS CODE LARAVEL: ${response.statusCode}");
        print("ERROR ASLI LARAVEL: ${response.body}");
        throw Exception('Gagal memuat laporan. Cek Terminal!');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Format Rupiah
  String formatRupiah(dynamic amount) {
    if (amount == null) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  // Format Angka Singkat untuk Label Grafik (Misal: 1.5M, 500K)
  String formatCompactIndicator(dynamic amount) {
    if (amount == null || amount == 0) return "0";
    final formatter = NumberFormat.compact(locale: 'id_ID');
    return formatter.format(amount);
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
            "Laporan Keuangan", 
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 18, fontWeight: FontWeight.w700)
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: _T.textMain),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: _T.accent))
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage, style: GoogleFonts.inter(color: Colors.red)))
                : RefreshIndicator(
                    onRefresh: _fetchReport,
                    color: _T.accent,
                    backgroundColor: _T.surface,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // --- VISUALISASI GRAFIK BATANG ---
                        _buildNativeBarChart(),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          "Rincian Pendapatan",
                          style: GoogleFonts.poppins(color: _T.textMain, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        
                        // --- LIST KARTU ---
                        _buildReportCard("Harian (Hari Ini)", reportData!['daily'], Icons.today_rounded, _T.cDaily),
                        _buildReportCard("Mingguan (Senin-Minggu)", reportData!['weekly'], Icons.view_week_rounded, _T.cWeekly),
                        _buildReportCard("Bulanan (Bulan Ini)", reportData!['monthly'], Icons.calendar_month_rounded, _T.cMonthly),
                        _buildReportCard("Tahunan (Tahun Ini)", reportData!['yearly'], Icons.auto_graph_rounded, _T.cYearly),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  // --- KOMPONEN GRAFIK KUSTOM ---
  Widget _buildNativeBarChart() {
    // 1. Ambil nilai data (pastikan double agar bisa dikalkulasi)
    final double vDaily = (reportData!['daily'] ?? 0).toDouble();
    final double vWeekly = (reportData!['weekly'] ?? 0).toDouble();
    final double vMonthly = (reportData!['monthly'] ?? 0).toDouble();
    final double vYearly = (reportData!['yearly'] ?? 0).toDouble();

    // 2. Cari nilai tertinggi untuk menentukan batas atas grafik (skala 100%)
    double maxVal = [vDaily, vWeekly, vMonthly, vYearly].reduce(math.max);
    if (maxVal == 0) maxVal = 1; // Cegah pembagian dengan nol jika data kosong

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Grafik Pertumbuhan",
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Perbandingan skala pendapatan",
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 32),
          
          // Area Batang Grafik
          SizedBox(
            height: 160, // Tinggi maksimal grafik
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSingleBar("Hari", vDaily, maxVal, _T.cDaily),
                _buildSingleBar("Mgg", vWeekly, maxVal, _T.cWeekly),
                _buildSingleBar("Bln", vMonthly, maxVal, _T.cMonthly),
                _buildSingleBar("Thn", vYearly, maxVal, _T.cYearly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBar(String label, double value, double maxVal, Color color) {
    // Hitung tinggi proporsional (0.0 sampai 1.0)
    double percentage = value / maxVal;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Label nilai di atas batang (misal: 1.5M, 500K)
        Text(
          formatCompactIndicator(value),
          style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        
        // Batang Grafik
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Minimal tinggi batang adalah 4 pixel agar tetap terlihat meski nilainya 0
              final double barHeight = math.max(4.0, constraints.maxHeight * percentage);
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                width: 36,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.85),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
              );
            }
          ),
        ),
        
        const SizedBox(height: 12),
        // Label rentang waktu di bawah batang
        Text(
          label,
          style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- KOMPONEN KARTU RINCIAN ---
  Widget _buildReportCard(String title, dynamic amount, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(amount),
                  style: GoogleFonts.poppins(color: _T.textMain, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}