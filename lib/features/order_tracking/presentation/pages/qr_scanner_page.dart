import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:laundry_app/features/laundry_management/presentation/pages/tracking_page.dart';

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

  void _navigateToTracking(String code) {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);

    _successAnim.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => TrackingPage(orderIdFromScanner: code),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  void _handleManualInput() {
    final code = _manualController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Masukkan kode nota terlebih dahulu"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    _navigateToTracking(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF94A3B8), size: 20),
          ),
        ),
        title: const Text(
          "Scan QR Nota",
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _torchOn
                    ? const Color(0xFF6366F1).withOpacity(0.2)
                    : Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _torchOn
                      ? const Color(0xFF6366F1).withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn
                    ? const Color(0xFF818CF8)
                    : const Color(0xFF64748B),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Viewfinder
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _navigateToTracking(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                // Overlay + scanner frame
                Center(
                  child: _ScannerFrame(successAnim: _scaleAnim),
                ),
                // Hint text
                const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Arahkan kamera ke QR code nota",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom panel
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  Row(
                    children: [
                      _PulseDot(),
                      const SizedBox(width: 10),
                      const Text(
                        "Kamera aktif — siap memindai",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    color: Color(0x12FFFFFF),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "ATAU MASUKKAN KODE MANUAL",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: "Contoh: LDR-2024-001",
                            hintStyle:
                                const TextStyle(color: Color(0xFF334155)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF6366F1), width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => _handleManualInput(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _handleManualInput,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cari",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTip(
                    Icons.center_focus_strong_rounded,
                    "Pastikan QR code terlihat jelas dan tidak buram",
                  ),
                  const SizedBox(height: 8),
                  _buildTip(
                    Icons.edit_rounded,
                    "Gunakan kode manual jika QR rusak atau tidak terbaca",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF818CF8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
}

// Scanner frame widget dengan animasi
class _ScannerFrame extends StatelessWidget {
  final Animation<double> successAnim;
  const _ScannerFrame({required this.successAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        children: [
          // Corner decorations
          ..._corners(),
          // Scan line
          const _ScanLine(),
          // Success check
          ScaleTransition(
            scale: successAnim,
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF22C55E), size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() => [
        _Corner(top: 0, left: 0, borderSide: {
          'top': true, 'left': true, 'right': false, 'bottom': false
        }),
        _Corner(top: 0, right: 0, borderSide: {
          'top': true, 'right': true, 'left': false, 'bottom': false
        }),
        _Corner(bottom: 0, left: 0, borderSide: {
          'bottom': true, 'left': true, 'top': false, 'right': false
        }),
        _Corner(bottom: 0, right: 0, borderSide: {
          'bottom': true, 'right': true, 'top': false, 'left': false
        }),
      ];
}

class _Corner extends StatelessWidget {
  final double? top, left, right, bottom;
  final Map<String, bool> borderSide;
  const _Corner({this.top, this.left, this.right, this.bottom,
    required this.borderSide});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: borderSide['top'] == true
                ? const BorderSide(color: Color(0xFF6366F1), width: 3)
                : BorderSide.none,
            left: borderSide['left'] == true
                ? const BorderSide(color: Color(0xFF6366F1), width: 3)
                : BorderSide.none,
            right: borderSide['right'] == true
                ? const BorderSide(color: Color(0xFF6366F1), width: 3)
                : BorderSide.none,
            bottom: borderSide['bottom'] == true
                ? const BorderSide(color: Color(0xFF6366F1), width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: 4 + (_anim.value * 208),
        left: 6,
        right: 6,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.85),
            borderRadius: BorderRadius.circular(2),
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

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF22C55E),
          ),
        ),
      ),
    );
  }
}