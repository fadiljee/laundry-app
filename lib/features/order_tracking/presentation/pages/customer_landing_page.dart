import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'qr_scanner_page.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (MODERN CLEAN LIGHT THEME)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); // Off-white/Slate-50
  static const surface     = Color(0xFFFFFFFF); // Pure White
  static const accent      = Color(0xFF2563EB); // Royal Blue (Primary)
  static const accentDark  = Color(0xFF1D4ED8); // Darker Blue for gradient
  static const accentFaint = Color(0x1A2563EB); // 10% Blue
  static const border      = Color(0xFFE2E8F0); // Light Slate for cards
  
  static const textMain    = Color(0xFF0F172A); // Very Dark Slate (Not pure black)
  static const textMuted   = Color(0xFF64748B); // Medium Slate for descriptions
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED CONCENTRIC RINGS PAINTER
// ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [size.width * 0.38, size.width * 0.46, size.width * 0.54];
    final opacities = [0.2, 0.1, 0.05]; // Lebih tipis untuk light theme
    final dashPhases = [0.0, 0.3, 0.6];

    for (int i = 0; i < radii.length; i++) {
      final paint = Paint()
        ..color = _T.accent.withOpacity(opacities[i] * (0.6 + 0.4 * math.sin(progress * math.pi * 2 + dashPhases[i])))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      if (i == 2) {
        _drawDashedCircle(canvas, center, radii[i], paint);
      } else {
        canvas.drawCircle(center, radii[i], paint);
      }
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 36;
    final step = (math.pi * 2) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final start = Offset(
          center.dx + radius * math.cos(i * step),
          center.dy + radius * math.sin(i * step),
        );
        final end = Offset(
          center.dx + radius * math.cos((i + 0.7) * step),
          center.dy + radius * math.sin((i + 0.7) * step),
        );
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────
class CustomerLandingPage extends StatefulWidget {
  const CustomerLandingPage({super.key});

  @override
  State<CustomerLandingPage> createState() => _CustomerLandingPageState();
}

class _CustomerLandingPageState extends State<CustomerLandingPage>
    with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _buttonCtrl;

  late final Animation<double> _fadeAll;
  late final Animation<Offset> _slideHero;
  late final Animation<double> _scaleHero;
  late final Animation<Offset> _slideText;
  late final Animation<Offset> _slideCards;
  late final Animation<Offset> _slideBtn;

  bool _buttonHeld = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _fadeAll = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _scaleHero = Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)));
    _slideHero = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)));
    _slideText = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic)));
    _slideCards = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)));
    _slideBtn = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic)));

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _buttonCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ringCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  Future<void> _onScanTap() async {
    HapticFeedback.lightImpact();
    await _buttonCtrl.forward();
    await _buttonCtrl.reverse();

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const QrScannerPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (result != null && mounted) {
      Navigator.pushNamed(context, '/tracking', arguments: result);
    }
  }

  static const _features = [
    (_FeatureIcon.clock,  'Lacak\nReal-time'),
    (_FeatureIcon.qr,     'Scan\nQR Nota'),
    (_FeatureIcon.spark,  'Tanpa\nDaftar'),
  ];

  @override
  Widget build(BuildContext context) {
    // Pakai dark overlay karena background kita sekarang terang
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: FadeTransition(
          opacity: _fadeAll,
          child: LayoutBuilder(
            builder: (ctx, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _buildBadge(),
                          const SizedBox(height: 36),
                          _buildHeroIcon(),
                          const SizedBox(height: 40),
                          _buildTypography(),
                          const SizedBox(height: 36),
                          _buildDivider(),
                          const SizedBox(height: 28),
                          _buildFeatureRow(),
                          const Spacer(flex: 3),
                          _buildCTAButton(),
                          const SizedBox(height: 20),
                          _buildFooterLink(),
                          const SizedBox(height: 8),
                          _buildHomeIndicator(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return SlideTransition(
      position: _slideText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _T.accentFaint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'EXPRESS & CLEAN',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _T.accent,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    return SlideTransition(
      position: _slideHero,
      child: ScaleTransition(
        scale: _scaleHero,
        child: AnimatedBuilder(
          animation: _ringCtrl,
          builder: (_, child) => SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _RingPainter(_ringCtrl.value),
                ),
                child!,
              ],
            ),
          ),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.surface,
              boxShadow: [
                BoxShadow(
                  color: _T.accent.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.local_laundry_service_rounded,
                size: 44,
                color: _T.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypography() {
    return SlideTransition(
      position: _slideText,
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'QQ ',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: _T.textMain,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: 'Laundry',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    color: _T.accent,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lacak progres cucian Anda dengan instan.\nScan nota sekarang, tanpa perlu repot daftar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _T.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return SlideTransition(
      position: _slideText,
      child: Center(
        child: Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: _T.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow() {
    return SlideTransition(
      position: _slideCards,
      child: Row(
        children: _features.map((f) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: f == _features.last ? 0 : 12,
            ),
            child: _FeatureCard(iconType: f.$1, label: f.$2),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCTAButton() {
    return SlideTransition(
      position: _slideBtn,
      child: AnimatedBuilder(
        animation: _buttonCtrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_buttonCtrl.value * 0.04),
          child: child,
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _buttonHeld = true),
          onTapUp: (_) => setState(() => _buttonHeld = false),
          onTapCancel: () => setState(() => _buttonHeld = false),
          onTap: _onScanTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: _buttonHeld
                    ? [_T.accentDark, const Color(0xFF1E3A8A)]
                    : [_T.accent, _T.accentDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: _buttonHeld
                  ? []
                  : [
                      BoxShadow(
                        color: _T.accent.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Scan Nota Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return SlideTransition(
      position: _slideBtn,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bukan pelanggan?  ',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _T.textMuted,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/login'),
            child: Text(
              'Masuk sebagai Staff',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FEATURE CARD
// ─────────────────────────────────────────────────────────────
enum _FeatureIcon { clock, qr, spark }

class _FeatureCard extends StatelessWidget {
  final _FeatureIcon iconType;
  final String label;
  const _FeatureCard({required this.iconType, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _T.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final icon = switch (iconType) {
      _FeatureIcon.clock => Icons.access_time_filled_rounded,
      _FeatureIcon.qr    => Icons.qr_code_2_rounded,
      _FeatureIcon.spark => Icons.bolt_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: _T.accentFaint,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: _T.accent),
    );
  }
}