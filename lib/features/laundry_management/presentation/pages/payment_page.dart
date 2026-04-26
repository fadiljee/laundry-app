import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahan Google Fonts
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

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

// --- WIDGET WEBVIEW (Untuk Pembayaran di Dalam App) ---
class PaymentWebViewPage extends StatefulWidget {
  final String url;
  const PaymentWebViewPage({super.key, required this.url});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  int _loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_T.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loadingPercentage = 0);
          },
          onProgress: (progress) {
            setState(() => _loadingPercentage = progress);
          },
          onPageFinished: (String url) {
            setState(() => _loadingPercentage = 100);
            if (url.contains('finish') || url.contains('error') || url.contains('unstatus')) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.pop(context);
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          title: Text(
            "Proses Pembayaran", 
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 16)
          ),
          backgroundColor: _T.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: _T.textMain),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loadingPercentage < 100)
              LinearProgressIndicator(
                value: _loadingPercentage / 100.0,
                backgroundColor: _T.bg,
                color: _T.accent,
                minHeight: 4,
              ),
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN UTAMA PAYMENT PAGE ---
class PaymentPage extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final double weight;
  final String customerName;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.weight,
    required this.customerName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final double _pricePerKg = 7000;

  @override
  Widget build(BuildContext context) {
    double total = widget.weight * _pricePerKg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          title: Text(
            "Detail Pembayaran",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _T.textMain, fontSize: 18),
          ),
          centerTitle: true,
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSummaryCard(total),
                    const SizedBox(height: 32),
                    Text(
                      "Metode Pembayaran",
                      style: GoogleFonts.poppins(
                        color: _T.textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hanya menampilkan QRIS
                    _buildMethodOption("QRIS", Icons.qr_code_scanner_rounded, "Bayar instan pakai aplikasi bank/e-wallet"),
                    const SizedBox(height: 48),
                    _buildPaymentInstruction(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomAction(total),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.accent, _T.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _T.accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              widget.orderCode,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.customerName,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            "Rp ${total.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallInfo("Berat", "${widget.weight} Kg"),
                Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2)),
                _buildSmallInfo("Harga/Kg", "Rp 7.000"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildMethodOption(String method, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _T.accent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _T.accent.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _T.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method, style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: _T.accent, size: 26),
        ],
      ),
    );
  }

  Widget _buildPaymentInstruction() {
    return Center(
      child: Column(
        children: [
          Text(
            "Siapkan aplikasi Bank atau E-Wallet Anda", 
            style: GoogleFonts.inter(color: _T.textMain, fontSize: 14, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _T.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _T.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
              ],
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: _T.border, size: 80),
          ),
          const SizedBox(height: 20),
          Text(
            "Gambar QRIS asli akan muncul\nsetelah Anda menekan tombol di bawah", 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12, height: 1.5)
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(double total) {
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
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: _T.accent)
                ),
              );

              try {
                final response = await http.post(
                  Uri.parse('https://prize-pancake-spore.ngrok-free.dev/api/payment/token'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'total_harga': total.toInt(),
                    'nama': widget.customerName,
                    'email': 'customer@lyra.com',
                  }),
                );

                if (!mounted) return;
                Navigator.pop(context);

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  String snapToken = data['token'];
                  String paymentUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentWebViewPage(url: paymentUrl),
                    ),
                  );
                } else {
                  throw "Gagal mendapatkan akses pembayaran";
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e", style: GoogleFonts.inter(color: Colors.white)), 
                    backgroundColor: _T.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              "BAYAR QRIS SEKARANG", 
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1.0)
            ),
          ),
        ),
      ),
    );
  }
}