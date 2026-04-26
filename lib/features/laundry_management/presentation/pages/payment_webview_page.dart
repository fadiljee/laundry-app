import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahan Google Fonts
import 'package:webview_flutter/webview_flutter.dart';

// Import halaman landing untuk navigasi balik
import '../../../../main.dart'; // Sesuaikan path jika CustomerLandingPage ada di file terpisah

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
  static const danger      = Color(0xFFEF4444); // Red
}

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
      ..setBackgroundColor(_T.bg) // Menggunakan background terang
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loadingPercentage = 0);
          },
          onProgress: (progress) {
            setState(() => _loadingPercentage = progress);
          },
          onPageFinished: (url) {
            setState(() => _loadingPercentage = 100);
            
            // Logika Auto-Close & Redirect yang sudah diperbaiki
            if (url.contains('finish')) {
              // Beri delay sebentar agar user lihat status "Berhasil" di web
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                   // Kembali ke landing page utama customer
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              });
            } else if (url.contains('error') || url.contains('pdf')) { 
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.pop(context);
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint("Webview Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Ikon status bar menjadi gelap
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pembayaran Aman",
                style: GoogleFonts.poppins(
                  fontSize: 16, 
                  fontWeight: FontWeight.w700, 
                  color: _T.textMain
                ),
              ),
              Text(
                widget.url.contains('sandbox') ? "Mode Testing Midtrans" : "Secure Checkout",
                style: GoogleFonts.inter(
                  fontSize: 11, 
                  color: _T.textMuted,
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
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
            onPressed: () => _showExitConfirmation(),
          ),
        ),
        body: Stack(
          children: [
            // WebView Utama
            WebViewWidget(controller: _controller),
            
            // Progress Bar (Hanya muncul saat loading < 100)
            if (_loadingPercentage < 100)
              LinearProgressIndicator(
                value: _loadingPercentage / 100.0,
                backgroundColor: _T.bg,
                color: _T.accent, // Warna Royal Blue
                minHeight: 4, // Sedikit ditebalkan agar jelas terlihat
              ),
          ],
        ),
      ),
    );
  }

  // Fungsi tambahan agar user tidak sengaja menutup saat bayar
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _T.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: _T.textMain),
            const SizedBox(width: 10),
            Text(
              "Batalkan Pembayaran?", 
              style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 16)
            ),
          ],
        ),
        content: Text(
          "Jika Anda sudah scan QRIS atau transfer, mohon tunggu di halaman ini hingga proses selesai.",
          style: GoogleFonts.inter(color: _T.textMuted, height: 1.5, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Tutup WebView
            },
            style: TextButton.styleFrom(
              foregroundColor: _T.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Keluar", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.accent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Lanjut Bayar", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}