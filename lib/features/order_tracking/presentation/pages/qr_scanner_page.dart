import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahan Google Fonts
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

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
  static const success     = Color(0xFF10B981); // Emerald Green
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  bool _hasScanned = false;
  bool _torchOn = false;

  late AnimationController _successAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successAnim,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  // --- PERBAIKAN LOGIKA NAVIGASI ---
  void _navigateToTracking(String code) {
    if (_hasScanned) return;

    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    setState(() => _hasScanned = true);
    
    // Matikan kamera & jalankan animasi sukses
    _controller.stop();
    _successAnim.forward();

    // Beri feedback visual sebentar sebelum pindah halaman
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      // Mengembalikan kode ke halaman sebelumnya (pop) 
      // agar halaman landing yang menangani navigasi ke TrackingPage
      Navigator.pop(context, cleanCode);
    });
  }

  void _handleManualInput() {
    final code = _manualController.text.trim();
    if (code.isEmpty) {
      _showErrorSnackBar("Masukkan kode nota terlebih dahulu");
      return;
    }
    _navigateToTracking(code);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        backgroundColor: _T.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Tampilkan loading saat menganalisis gambar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: _T.accent),
        ),
      );

      try {
        final BarcodeCapture? capture = await _controller.analyzeImage(image.path);

        if (!mounted) return;
        Navigator.pop(context); // Tutup loading

        if (capture == null || capture.barcodes.isEmpty) {
          _showErrorSnackBar("Tidak ada QR Code yang terdeteksi di gambar.");
          return;
        }

        final String? scannedCode = capture.barcodes.first.rawValue;
        if (scannedCode != null) {
          _navigateToTracking(scannedCode);
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorSnackBar("Error membaca gambar: $e");
      }
    }
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
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.textMain, size: 20),
          ),
          title: Text(
            "Scan Nota Laundry",
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.image_search_rounded, color: _T.textMain),
              tooltip: "Ambil dari Galeri",
            ),
            IconButton(
              onPressed: () {
                _controller.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? const Color(0xFFF59E0B) : _T.textMain, // Warna Amber kalau nyala
              ),
              tooltip: "Senter",
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // SCANNER VIEW
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.first;
                      if (barcode.rawValue != null) {
                        _navigateToTracking(barcode.rawValue!);
                      }
                    },
                  ),
                  // Overlay Frame
                  Center(child: _ScannerFrame(successAnim: _scaleAnim)),
                  // Instruksi melayang (Tetap gelap agar kontras dengan kamera)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Posisikan QR Code di dalam kotak",
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // INPUT PANEL
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _PulseDot(),
                          const SizedBox(width: 10),
                          Text(
                            "Scanner siap digunakan",
                            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "ATAU MASUKKAN KODE NOTA",
                        style: GoogleFonts.inter(
                          color: _T.textMuted, 
                          fontSize: 11, 
                          fontWeight: FontWeight.w700, 
                          letterSpacing: 1.0
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _manualController,
                                style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                                decoration: InputDecoration(
                                  hintText: "Contoh: LDR-12345",
                                  hintStyle: GoogleFonts.inter(color: _T.textMuted.withOpacity(0.5), fontWeight: FontWeight.w400, letterSpacing: 0),
                                  filled: true,
                                  fillColor: _T.bg,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _T.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _T.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _T.accent, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            width: 52,
                            child: ElevatedButton(
                              onPressed: _handleManualInput,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _T.accent,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTip(Icons.lightbulb_outline_rounded, "QR Code biasanya ada di pojok kanan bawah pada nota fisik yang kami berikan."),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _T.accent.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.accent.withOpacity(0.1)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _T.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text, 
            style: GoogleFonts.inter(fontSize: 12, color: _T.textMuted, height: 1.5)
          )
        ),
      ],
    ),
  );
}

// --- WIDGET PENDUKUNG (Scanner Frame, Line, Pulse) ---

class _ScannerFrame extends StatelessWidget {
  final Animation<double> successAnim;
  const _ScannerFrame({required this.successAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240, height: 240,
      child: Stack(
        children: [
          _buildCorners(),
          const _ScanLine(),
          ScaleTransition(
            scale: successAnim,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _T.success, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorners() {
    return Container(
      decoration: BoxDecoration(
        // Border putih karena overlay ini di atas tangkapan kamera asli (yang biasanya gelap)
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
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
        top: 20 + (_anim.value * 200),
        left: 20, right: 20,
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: _T.accent.withOpacity(0.6), blurRadius: 12)
            ],
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [Colors.transparent, _T.accent, Colors.transparent]
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10, 
        height: 10, 
        decoration: const BoxDecoration(color: _T.success, shape: BoxShape.circle)
      ),
    );
  }
}