import 'dart:convert';
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
  static const bg          = Color(0xFFF8FAFC); // Off-white/Slate-50
  static const surface     = Color(0xFFFFFFFF); // Pure White
  static const accent      = Color(0xFF2563EB); // Royal Blue
  static const accentDark  = Color(0xFF1D4ED8); // Darker Blue
  static const border      = Color(0xFFE2E8F0); // Light Slate
  static const textMain    = Color(0xFF0F172A); // Very Dark Slate
  static const textMuted   = Color(0xFF64748B); // Medium Slate
  static const danger      = Color(0xFFEF4444); // Red
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // --- State untuk Data Dashboard ---
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    // Panggil API saat halaman pertama kali dibuka
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // --- Fetch Data API ---
  Future<void> _fetchDashboardData() async {
    try {
      String? token = await AuthStorage.getToken();
      // SESUAIKAN IP ADDRESS DENGAN LARAVEL KAMU
      final response = await http.get(
        Uri.parse('https://prize-pancake-spore.ngrok-free.dev/api/reports/financial'), 
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          dashboardData = json.decode(response.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print("Error fetching dashboard data: $e");
    }
  }

  Future<void> _handleLogout() async {
    await AuthStorage.clearToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Berhasil Logout", 
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        backgroundColor: _T.accentDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper Format Rupiah
  String formatRupiah(dynamic amount) {
    if (amount == null) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Membuat ikon baterai/sinyal jadi gelap
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
            "Admin Dashboard",
            style: GoogleFonts.poppins(
              color: _T.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: _T.danger),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: _T.accent,
          backgroundColor: _T.surface,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFinancialSummary(),
                    const SizedBox(height: 32),
                    
                    // --- SECTION: OPERASIONAL ---
                    Text(
                      "Operasional",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _T.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      title: "Input Pesanan Baru",
                      subtitle: "Input berat & foto timbangan",
                      icon: Icons.add_a_photo_rounded,
                      color: const Color(0xFF6366F1), // Indigo
                      onTap: () => Navigator.pushNamed(context, '/add-order'),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Daftar Pesanan",
                      subtitle: "Kelola status & verifikasi bayar",
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFFF59E0B), // Amber
                      onTap: () => Navigator.pushNamed(context, '/order-list'),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Cek Tracking Pelanggan",
                      subtitle: "Simulasi tampilan di HP pelanggan",
                      icon: Icons.map_rounded,
                      color: const Color(0xFF10B981), // Emerald
                      onTap: () => Navigator.pushNamed(context, '/tracking', arguments: null),
                    ),

                    const SizedBox(height: 32),

                    // --- SECTION: MANAJEMEN ---
                    Text(
                      "Manajemen",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _T.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      title: "Laporan Keuangan",
                      subtitle: "Rekap harian, mingguan, bulanan & tahunan",
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF14B8A6), // Teal
                      onTap: () => Navigator.pushNamed(context, '/financial-report'),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Kelola Data Kurir",
                      subtitle: "Tambah, hapus, & pantau akun kurir",
                      icon: Icons.motorcycle_rounded, 
                      color: const Color(0xFFEC4899), // Pink
                      onTap: () => Navigator.pushNamed(context, '/manage-couriers'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final double monthlyRevenue = dashboardData?['monthly']?.toDouble() ?? 0.0;
    final int completedCount = dashboardData?['completed_count'] ?? 0;
    final int processCount = dashboardData?['process_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.accent, _T.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _T.accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Pendapatan (Bulan Ini)",
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          isLoading 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 24, height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                ),
              )
            : Text(
                formatRupiah(monthlyRevenue),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white.withOpacity(0.2), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cucian Selesai: $completedCount",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                "Proses: $processCount",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: _T.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _T.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: _T.textMain,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: _T.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _T.textMuted.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}