import 'dart:async';
import 'dart:convert'; // Untuk decode JSON API
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Package baru
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const accentFaint = Color(0x1A2563EB); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const danger      = Color(0xFFEF4444); 
  static const success     = Color(0xFF10B981); 
}

class CustomerLandingPage extends StatefulWidget {
  const CustomerLandingPage({super.key});

  @override
  State<CustomerLandingPage> createState() => _CustomerLandingPageState();
}

class _CustomerLandingPageState extends State<CustomerLandingPage>
    with TickerProviderStateMixin {
      
  final MobileScannerController _scannerCtrl = MobileScannerController();
  bool _hasScanned = false;
  bool _torchOn = false;

  // --- VARIABEL STATUS CUCIAN ---
  String? _lastOrderCode;
  String _lastOrderStatus = "Memuat data...";
  bool _hasLastOrder = false;

  // Animations
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAll;
  late final Animation<Offset> _slideText;
  late final Animation<Offset> _slideScanner;
  late final Animation<Offset> _slideStatus;

  late final AnimationController _successAnimCtrl;
  late final Animation<double> _scaleSuccessAnim;

  @override
  void initState() {
    super.initState();
    _loadLastOrder(); // Panggil data pesanan terakhir saat halaman dibuka

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAll = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _slideText = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic)));
    _slideScanner = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)));
    _slideStatus = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)));

    _successAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleSuccessAnim = CurvedAnimation(parent: _successAnimCtrl, curve: Curves.elasticOut);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _entryCtrl.dispose();
    _successAnimCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  LOGIC: AMBIL DATA PESANAN TERAKHIR (REAL STATUS)
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadLastOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('last_order_code');
    
    // Ambil status nyata terakhir yang tersimpan (jika kosong, beri teks default)
    final savedStatus = prefs.getString('last_order_status') ?? "Memuat data..."; 

    if (savedCode != null && savedCode.isNotEmpty) {
      setState(() {
        _hasLastOrder = true;
        _lastOrderCode = savedCode;
        // Tampilkan status nyata dari memori lokal duluan biar UI tidak kosong
        _lastOrderStatus = savedStatus; 
      });

      try {
        final url = Uri.parse('http://192.168.1.9:8000/api/orders/$savedCode');
        final response = await http.get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body)['data'];
          
          String statusText = data['status'];
          if (statusText == 'pending') statusText = "Menunggu Konfirmasi";
          if (statusText == 'pickup') statusText = "Kurir Menuju Lokasi";
          if (statusText == 'processing') statusText = "Sedang Dicuci";
          if (statusText == 'completed') statusText = "Selesai & Siap Diantar";

          // SIMPAN STATUS NYATA TERBARU KE MEMORI HP
          await prefs.setString('last_order_status', statusText);

          if (mounted) setState(() => _lastOrderStatus = statusText);
        }
        // Jika response gagal (bukan 200), KITA DIAMKAN SAJA. 
        // UI akan tetap menampilkan _lastOrderStatus dari SharedPreferences (data nyata terakhir).
        
      } catch (e) {
        // Jika koneksi internet mati/timeout, KITA DIAMKAN SAJA.
        // UI tetap aman menampilkan status nyata terakhir dari memori.
      }
    } else {
      if (mounted) {
        setState(() {
          _hasLastOrder = false;
          _lastOrderStatus = "Belum ada pesanan";
        });
      }
    }
  }

  // HELPER: TAMPILKAN ERROR SNACKBAR
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: _T.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // LOGIC: SCAN DARI GALERI
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: _T.accent)),
      );

      try {
        await _scannerCtrl.stop(); 
        final BarcodeCapture? capture = await _scannerCtrl.analyzeImage(image.path);
        
        if (!mounted) return;
        Navigator.pop(context); 

        if (capture != null && capture.barcodes.isNotEmpty) {
          final String? scannedCode = capture.barcodes.first.rawValue;
          if (scannedCode != null) _navigateToTracking(scannedCode);
        } else {
          _showErrorSnackBar("QR Code tidak ditemukan di foto ini.");
          _scannerCtrl.start(); 
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorSnackBar("Gagal membaca gambar: $e");
        _scannerCtrl.start();
      }
    }
  }

  // LOGIC: NAVIGASI DAN SIMPAN KODE
  Future<void> _navigateToTracking(String code) async {
    if (_hasScanned) return;
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    setState(() => _hasScanned = true);
    HapticFeedback.lightImpact();
    _scannerCtrl.stop();
    _successAnimCtrl.forward();

    // Simpan kode nota ke memori lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_order_code', cleanCode);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    
    // Pindah halaman dengan melempar argumen cleanCode
    await Navigator.pushNamed(context, '/tracking', arguments: cleanCode);

    // Refresh status saat user kembali (Back) ke halaman ini
    if (mounted) {
      setState(() => _hasScanned = false);
      _successAnimCtrl.reverse();
      _scannerCtrl.start();
      _loadLastOrder(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: FadeTransition(
          opacity: _fadeAll,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildScannerBox(),
                  const SizedBox(height: 24),
                  _buildNewOrderButton(),
                  const SizedBox(height: 32),
                  _buildStatusNotification(),
                  const SizedBox(height: 32),
                  _buildFooterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _slideText,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: _T.accentFaint, borderRadius: BorderRadius.circular(20)),
            child: Text('EXPRESS & CLEAN', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _T.accent, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(text: 'QQ ', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: _T.textMain, letterSpacing: -1)),
                TextSpan(text: 'Laundry', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w400, color: _T.accent, letterSpacing: -1)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Arahkan kamera ke QR Code pada nota Anda', style: GoogleFonts.inter(fontSize: 13, color: _T.textMuted)),
        ],
      ),
    );
  }

  Widget _buildScannerBox() {
    return SlideTransition(
      position: _slideScanner,
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _T.accent.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.hardEdge, 
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerCtrl,
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) _navigateToTracking(barcode.rawValue!);
              },
            ),
            Container(color: Colors.black.withOpacity(0.1)),
            const _ScanLineFull(),
            ScaleTransition(
              scale: _scaleSuccessAnim,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: _T.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 12, right: 12,
              child: Row(
                children: [
                  _buildFloatingIconButton(
                    icon: Icons.image_rounded, 
                    onTap: _pickImageFromGallery,
                  ),
                  const SizedBox(width: 8),
                  // PERBAIKAN SENTER LEBIH AMAN
                  _buildFloatingIconButton(
                    icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, 
                    color: _torchOn ? Colors.amber : Colors.white,
                    onTap: () async {
                      try {
                        await _scannerCtrl.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      } catch (e) {
                        _showErrorSnackBar("Gagal mengaktifkan senter");
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusNotification() {
    return SlideTransition(
      position: _slideStatus,
      child: GestureDetector(
        onTap: () {
          // CEK APAKAH ADA DATA UNTUK DILACAK
          if (_hasLastOrder && _lastOrderCode != null) {
            Navigator.pushNamed(context, '/tracking', arguments: _lastOrderCode).then((_) {
              _loadLastOrder(); // Refresh kalau user kembali
            });
          } else {
            _showErrorSnackBar("Belum ada riwayat pesanan yang tersimpan.");
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: _T.accent, shape: BoxShape.circle),
                child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasLastOrder ? "Resi: $_lastOrderCode" : "Status Cucian Terakhir", 
                      style: GoogleFonts.inter(fontSize: 12, color: _T.accent, fontWeight: FontWeight.w600)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastOrderStatus, 
                      style: GoogleFonts.poppins(fontSize: 15, color: _T.textMain, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _T.accent.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIconButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildNewOrderButton() {
    return SlideTransition(
      position: _slideScanner,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/add-order').then((_) => _loadLastOrder()),
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.surface,
          foregroundColor: _T.accent,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _T.border)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_shopping_cart_rounded, size: 20),
            const SizedBox(width: 12),
            Text("Belum punya nota? Buat Pesanan", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Bukan pelanggan?  ', style: GoogleFonts.inter(fontSize: 13, color: _T.textMuted)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/login'),
          child: Text('Masuk Staff', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _T.accent)),
        ),
      ],
    );
  }
}

class _ScanLineFull extends StatefulWidget {
  const _ScanLineFull();
  @override
  State<_ScanLineFull> createState() => _ScanLineFullState();
}

class _ScanLineFullState extends State<_ScanLineFull> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: 40 + (_anim.value * 200), 
        left: 0, right: 0,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: _T.accent.withOpacity(0.5), blurRadius: 15)],
            gradient: const LinearGradient(colors: [Colors.transparent, _T.accent, Colors.transparent]),
          ),
        ),
      ),
    );
  }
}