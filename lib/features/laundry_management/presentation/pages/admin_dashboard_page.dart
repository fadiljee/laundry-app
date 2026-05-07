import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// ⚠️ MOCK AUTH PROVIDER - HAPUS INI JIKA ANDA MENGGUNAKAN PROVIDER ASLI ⚠️
// ─────────────────────────────────────────────────────────────
// Untuk keperluan demonstrasi agar kode ini bisa dijalankan tanpa file eksternal.
// Jika Anda mengintegrasikannya kembali, hapus blok ini dan aktifkan impor asli di atas.

class AuthStorage {
  static Future<String?> getToken() async {
    // Mock token untuk keperluan testing UI. Ganti dengan implementasi asli Anda.
    return "mock_token"; 
  }
  static Future<void> clearToken() async {
    // Mock clear token. Ganti dengan implementasi asli Anda.
    print("Mock Logout: Token cleared.");
  }
}

// Aktifkan impor asli Anda dan hapus kelas tiruan di atas saat Anda siap.
// import '../../../../core/providers/auth_provider.dart'; 

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF1F5F9); // Slate 100 - lebih cerah untuk background
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); // Blue 600
  static const accentDark  = Color(0xFF1D4ED8); // Blue 700
  static const accentLight = Color(0xFFDBEAFE); // Blue 100
  static const border      = Color(0xFFE2E8F0); // Slate 200
  static const textMain    = Color(0xFF0F172A); // Slate 900
  static const textMuted   = Color(0xFF64748B); // Slate 500
  static const danger      = Color(0xFFEF4444); // Red 500
  static const dangerLight = Color(0xFFFEE2E2); // Red 100
  static const success     = Color(0xFF10B981); // Emerald 500
  static const successLight= Color(0xFFD1FAE5); // Emerald 100
  static const warning     = Color(0xFFF59E0B); // Amber 500
  static const warningLight= Color(0xFFFEF3C7); // Amber 100
  static const teal        = Color(0xFF14B8A6); // Teal 500
  static const tealLight   = Color(0xFFCCFBF1); // Teal 100
  static const pink        = Color(0xFFEC4899); // Pink 500
  static const pinkLight   = Color(0xFFFCE7F3); // Pink 100

  // Spacing & Radius
  static const radius      = 20.0;
  static const cardRadius  = 16.0;
  static const spacing     = 24.0;
  static const spacingLg   = 32.0;

  // Shadows
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: accent.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
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
      begin: const Offset(0, 0.05),
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
    setState(() => isLoading = true);
    try {
      String? token = await AuthStorage.getToken();
      // SESUAIKAN IP ADDRESS DENGAN LARAVEL KAMU (Atau pakai domain https://lyra.biz.id jika sudah di hosting)
      final response = await http.get(
        // Uri.parse('http://192.168.1.9:8000/api/reports/financial'), 
        Uri.parse('https://lyra.biz.id/api/reports/financial'), 
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
      } else {
        // Handle error response
        if (!mounted) return;
        setState(() => isLoading = false);
        print("Error fetching data: ${response.statusCode}");
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
        backgroundColor: _T.danger, // Lebih konsisten untuk logout
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String formatRupiah(dynamic amount) {
    if (amount == null) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Tarik angka pesanan yang sedang diproses dari API untuk dijadikan Notif Bubble
    final int processCount = dashboardData?['process_count'] ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, 
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.bg, // Gunakan bg cerah
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              backgroundColor: _T.accentLight,
              child: Icon(Icons.person_rounded, color: _T.accent, size: 20),
            ),
          ),
          title: Text(
            "Halo, Admin 👋",
            style: GoogleFonts.poppins(
              color: _T.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: _T.danger),
            ),
            const SizedBox(width: 8),
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
                padding: const EdgeInsets.all(_T.spacing),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFinancialSummary(),
                    const SizedBox(height: _T.spacingLg),
                    
                    // --- SECTION: OPERASIONAL ---
                    Text(
                      "Operasional",
                      style: GoogleFonts.poppins(
                        fontSize: 16, // Sedikit lebih kecil untuk keseimbangan
                        fontWeight: FontWeight.w700,
                        color: _T.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      title: "Daftar Pesanan",
                      subtitle: "Kelola status & verifikasi bayar",
                      icon: Icons.local_shipping_rounded, // Lebih spesifik operasional
                      color: _T.warning, 
                      colorLight: _T.warningLight,
                      badgeCount: processCount, 
                      onTap: () => Navigator.pushNamed(context, '/order-list'),
                    ),
                    
                    // --- MENU "CEK TRACKING PELANGGAN" TELAH DIHAPUS ---

                    const SizedBox(height: _T.spacingLg),

                    // --- SECTION: MANAJEMEN ---
                    Text(
                      "Manajemen",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _T.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      title: "Laporan Keuangan",
                      subtitle: "Harian, mingguan, bulanan & tahunan",
                      icon: Icons.analytics_rounded, // Lebih modern
                      color: _T.teal, 
                      colorLight: _T.tealLight,
                      onTap: () => Navigator.pushNamed(context, '/financial-report'),
                    ),
                    _buildMenuCard(
                      context,
                      title: "Kelola Data Kurir",
                      subtitle: "Tambah, hapus, & pantau akun kurir",
                      icon: Icons.motorcycle_rounded, 
                      color: _T.pink, 
                      colorLight: _T.pinkLight,
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
    double monthlyRevenue = 0.0;
    final monthlyData = dashboardData?['monthly'];

    if (monthlyData is num) {
      monthlyRevenue = monthlyData.toDouble();
    } else if (monthlyData is Map) {
      monthlyRevenue = (monthlyData['total_revenue'] ?? 0).toDouble();
    }

    final int completedCount = dashboardData?['completed_count'] ?? 0;
    final int processCount = dashboardData?['process_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(_T.spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.accentDark, _T.accent.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_T.radius),
        boxShadow: _T.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Pendapatan (Bulan Ini)",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.monetization_on_rounded, color: _T.successLight, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          
          isLoading 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: 24, height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                ),
              )
            : Text(
                formatRupiah(monthlyRevenue),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 30, // Sedikit lebih besar
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              
          Padding(
            padding: const EdgeInsets.symmetric(vertical: _T.spacing),
            child: Divider(color: Colors.white.withOpacity(0.15), height: 1),
          ),
          
          // Metrik Tambahan dengan Tata Letak yang Lebih Bersih
          Row(
            children: [
              _buildSimpleMetrik(
                icon: Icons.done_all_rounded, 
                label: "Cucian Selesai", 
                value: completedCount.toString(),
                color: _T.successLight,
              ),
              const SizedBox(width: 20),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.15)),
              const SizedBox(width: 20),
              _buildSimpleMetrik(
                icon: Icons.autorenew_rounded, 
                label: "Proses", 
                value: processCount.toString(),
                color: _T.warningLight,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSimpleMetrik({
    required IconData icon, 
    required String label, 
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isLoading ? 
                  const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white)) 
                  : Text(
                    value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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
    required Color colorLight,
    int badgeCount = 0, 
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: _T.shadowSm,
        ),
        child: Material(
          color: _T.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_T.cardRadius),
            side: const BorderSide(color: _T.border, width: 0.8), // Border lebih tipis
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_T.cardRadius),
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(18), // Padding dalam lebih proporsional
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14), // Sedikit lebih besar
                    decoration: BoxDecoration(
                      color: colorLight,
                      borderRadius: BorderRadius.circular(14),
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
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: _T.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badgeCount > 0 && !isLoading)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Lebih seimbang
                      decoration: BoxDecoration(
                        color: _T.danger, 
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _T.danger.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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