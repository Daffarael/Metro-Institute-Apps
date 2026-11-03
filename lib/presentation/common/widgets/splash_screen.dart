import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';

/// SplashScreen — Staged Shield Construction & Typewriter Typography ("Metro Institute").
///
/// Urutan Animasi Sinematik & Sangat Mulus:
/// 1. [0.00 – 0.05] Ruang tenang, perisai MULAI PERSIS DI TITIK TENGAH LAYAR (Dead Center).
/// 2. [0.05 – 0.32] Garis kontur perisai digambar sangat halus, lembut, dan melingkar (easeInOutCubic).
/// 3. [0.32 – 0.46] Perisai terisi warna hijau zamrud solid (#063D2A) secara lembut mengalir.
/// 4. [0.46 – 0.64] 3 titik intan & 4 pilar kaligrafi "MI" terukir presisi menembus perisai ke warna putih.
/// 5. [0.64 – 0.75] Perisai meluncur mulus (easeInOutCubic) dari titik tengah ke posisi kiri lockup.
/// 6. [0.74 – 0.85] Teks "Metro" diketik huruf demi huruf (Typewriter Effect) dengan kursor berkedip.
/// 7. [0.84 – 0.96] Teks "Institute" diketik menyusul huruf demi huruf tepat di bawahnya.
/// 8. [0.96 – 1.00] Kursor menghilang, logo utuh yang seimbang di tengah layar dinikmati sebelum dissolve.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;

  // ── Tahap 1: Outline Tracing (Garis perisai) ──────────────────────────────
  late Animation<double> _outlineProgress;

  // ── Tahap 2: Pengisian Perisai Hijau Solid ────────────────────────────────
  late Animation<double> _shieldFillOpacity;

  // ── Tahap 3: Ukiran Elemen Dalam (Pure Clean Cutouts) ─────────────────────
  late Animation<double> _dot1Carve;
  late Animation<double> _dot2Carve;
  late Animation<double> _dot3Carve;
  late Animation<double> _pillarsCarve;

  // ── Tahap 4: Geser Perisai dari Tengah ke Kiri (Mulus) ───────────────────
  late Animation<double> _logoShiftProgress;

  // ── Tahap 5: Efek Mengetik (Typewriter Effect) ────────────────────────────
  late Animation<double> _metroTypeProgress;
  late Animation<double> _instituteTypeProgress;

  // ── Tahap 6: Exit Dissolve ────────────────────────────────────────────────
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  bool _hasTriggeredCarveHaptic = false;
  int _lastMetroChars = 0;
  int _lastInstituteChars = 0;

  // Warna Brand Utama Metro Institute
  static const Color _brandColor = Color(0xFF063D2A); // Hijau Zamrud Mewah & Kontras Tinggi

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runAnimationSequence();
  }

  void _initAnimations() {
    // 5800ms: Durasi sinematik yang tenang, lambat, dan sangat mulus
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5800),
    );

    // 1. Tracing Outline: Garis perisai digambar melingkar sangat halus (290ms – 1850ms)
    _outlineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.32, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Perisai hijau terisi secara lembut (1850ms – 2660ms)
    _shieldFillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.46, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tiga titik intan terukir bertahap dengan mulus (2660ms – 3480ms)
    _dot1Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.54, curve: Curves.easeOutCubic),
      ),
    );
    _dot2Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.58, curve: Curves.easeOutCubic),
      ),
    );
    _dot3Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.54, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    // Empat pilar kaligrafi terukir memotong perisai turun ke bawah (3000ms – 3710ms)
    _pillarsCarve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.64, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Perisai meluncur mulus dari titik tengah absolut ke posisi kiri (3710ms – 4350ms)
    _logoShiftProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.64, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Animasi Mengetik "Metro" huruf demi huruf (4290ms – 4930ms)
    _metroTypeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.74, 0.85, curve: Curves.linear),
      ),
    );

    // Animasi Mengetik "Institute" huruf demi huruf di bawahnya (4870ms – 5560ms)
    _instituteTypeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.84, 0.96, curve: Curves.linear),
      ),
    );

    // 6. Exit Controller (450ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    // Haptic feedback saat ukiran selesai & saat setiap huruf diketik
    _controller.addListener(() {
      if (_controller.value >= 0.64 && !_hasTriggeredCarveHaptic) {
        _hasTriggeredCarveHaptic = true;
        HapticFeedback.lightImpact();
      }

      // Haptic tactile click saat mengetik tiap karakter
      final currentMetroLen = _displayedMetroLength;
      if (currentMetroLen > _lastMetroChars) {
        _lastMetroChars = currentMetroLen;
        HapticFeedback.selectionClick();
      }

      final currentInstLen = _displayedInstituteLength;
      if (currentInstLen > _lastInstituteChars) {
        _lastInstituteChars = currentInstLen;
        HapticFeedback.selectionClick();
      }
    });
  }

  // Helper untuk mendapatkan panjang karakter terketik
  int get _displayedMetroLength {
    if (_metroTypeProgress.value <= 0.0) return 0;
    if (_metroTypeProgress.value >= 1.0) return 5;
    final chars = (_metroTypeProgress.value * 5).floor();
    return chars.clamp(0, 5);
  }

  int get _displayedInstituteLength {
    if (_instituteTypeProgress.value <= 0.0) return 0;
    if (_instituteTypeProgress.value >= 1.0) return 9;
    final chars = (_instituteTypeProgress.value * 9).floor();
    return chars.clamp(0, 9);
  }

  String get _displayedMetroText {
    const word = 'Metro';
    return word.substring(0, _displayedMetroLength);
  }

  String get _displayedInstituteText {
    const word = 'Institute';
    return word.substring(0, _displayedInstituteLength);
  }

  bool get _showMetroCursor {
    return _metroTypeProgress.value > 0.0 && _instituteTypeProgress.value < 0.08;
  }

  bool get _showInstituteCursor {
    return _instituteTypeProgress.value >= 0.08 && _instituteTypeProgress.value < 1.0;
  }

  Future<void> _runAnimationSequence() async {
    try {
      await _controller.forward();
      // Jeda sejenak untuk mengagumi tampilan logo utuh yang seimbang di tengah
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      await _exitController.forward();
      if (!mounted) return;

      final authRepo = sl<AuthRepository>();
      final loggedIn = await authRepo.isLoggedIn();
      if (!mounted) return;

      if (loggedIn) {
        try {
          await authRepo.refreshProfile();
          if (!mounted) return;
          context.go(AppRoutes.basecamp);
        } catch (_) {
          await authRepo.logout();
          if (!mounted) return;
          context.go(AppRoutes.login);
        }
      } else {
        context.go(AppRoutes.login);
      }
    } catch (_) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar Belakang Putih Bersih
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _exitController]),
        builder: (context, child) {
          return Center(
            child: Transform.scale(
              scale: _exitScale.value,
              child: Opacity(
                opacity: _exitOpacity.value,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const shieldWidth = 82.0;
                    const shieldHeight = 104.0;
                    const gap = 18.0;

                    // Mengukur lebar teks "Institute" secara presisi
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: 'Institute',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout();
                    final textWidth = textPainter.width;

                    // Jarak pergeseran perisai ke kiri dari titik tengah absolut
                    // Agar [Perisai + Gap + Teks] berada 100% presisi di tengah layar saat selesai:
                    final shiftDistance = (gap + textWidth) / 2;
                    final currentShieldOffset = -shiftDistance * _logoShiftProgress.value;

                    return SizedBox(
                      width: constraints.maxWidth,
                      height: shieldHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // ── 1. Perisai (Mulai 100% PERSIS DI TITIK TENGAH LAYAR) ──
                          Transform.translate(
                            offset: Offset(currentShieldOffset, 0),
                            child: SizedBox(
                              width: shieldWidth,
                              height: shieldHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Staged Carving Custom Painter
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _LogoCarvingPainter(
                                        outlineProgress: _outlineProgress.value,
                                        shieldFillOpacity: _shieldFillOpacity.value,
                                        dot1Carve: _dot1Carve.value,
                                        dot2Carve: _dot2Carve.value,
                                        dot3Carve: _dot3Carve.value,
                                        pillarsCarve: _pillarsCarve.value,
                                        logoColor: _brandColor,
                                      ),
                                    ),
                                  ),

                                  // Pixel-Perfect Crossfade ke Asset Resmi saat ukiran selesai
                                  if (_pillarsCarve.value >= 0.95)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: ((_pillarsCarve.value - 0.95) / 0.05).clamp(0.0, 1.0),
                                        child: Image.asset(
                                          'assets/images/metro_shield.png',
                                          color: _brandColor,
                                          colorBlendMode: BlendMode.srcIn,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                            'assets/images/logo_clean.png',
                                            color: _brandColor,
                                            colorBlendMode: BlendMode.srcIn,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) => Image.asset(
                                              'assets/images/logo.png',
                                              color: _brandColor,
                                              colorBlendMode: BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // ── 2. Tipografi Mengetik ("Metro Institute") ──
                          // Berada persis di sebelah kanan perisai: shieldRight + gap
                          if (_logoShiftProgress.value > 0.01)
                            Positioned(
                              left: (constraints.maxWidth / 2) + currentShieldOffset + (shieldWidth / 2) + gap,
                              child: Opacity(
                                opacity: _logoShiftProgress.value.clamp(0.0, 1.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Baris 1: "Metro"
                                    SizedBox(
                                      height: 38,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            _displayedMetroText,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.8,
                                              color: _brandColor,
                                              height: 1.05,
                                            ),
                                          ),
                                          if (_showMetroCursor)
                                            const _TypewriterCursor(color: _brandColor),
                                        ],
                                      ),
                                    ),

                                    // Baris 2: "Institute"
                                    SizedBox(
                                      height: 38,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            _displayedInstituteText,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.8,
                                              color: _brandColor,
                                              height: 1.05,
                                            ),
                                          ),
                                          if (_showInstituteCursor)
                                            const _TypewriterCursor(color: _brandColor),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget Kursor Ketikan Typewriter yang berkedip halus
class _TypewriterCursor extends StatefulWidget {
  final Color color;
  const _TypewriterCursor({required this.color});

  @override
  State<_TypewriterCursor> createState() => _TypewriterCursorState();
}

class _TypewriterCursorState extends State<_TypewriterCursor> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        return Opacity(
          opacity: _blinkController.value > 0.35 ? 1.0 : 0.0,
          child: Container(
            width: 3.2,
            height: 28.0,
            margin: const EdgeInsets.only(left: 3.0),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1.6),
            ),
          ),
        );
      },
    );
  }
}

/// Custom Painter yang menggambar garis perisai dan ukiran cutouts
class _LogoCarvingPainter extends CustomPainter {
  final double outlineProgress;
  final double shieldFillOpacity;
  final double dot1Carve;
  final double dot2Carve;
  final double dot3Carve;
  final double pillarsCarve;
  final Color logoColor;

  _LogoCarvingPainter({
    required this.outlineProgress,
    required this.shieldFillOpacity,
    required this.dot1Carve,
    required this.dot2Carve,
    required this.dot3Carve,
    required this.pillarsCarve,
    this.logoColor = const Color(0xFF063D2A),
  });

  // Normalized 3 Diamond Rhombuses
  static const List<Offset> _dot1 = [
    Offset(0.3203, 0.1435),
    Offset(0.2687, 0.1842),
    Offset(0.3203, 0.2250),
    Offset(0.3701, 0.1857),
  ];
  static const List<Offset> _dot2 = [
    Offset(0.4270, 0.1435),
    Offset(0.3754, 0.1842),
    Offset(0.4270, 0.2250),
    Offset(0.4786, 0.1857),
  ];
  static const List<Offset> _dot3 = [
    Offset(0.5356, 0.1435),
    Offset(0.4840, 0.1842),
    Offset(0.5338, 0.2250),
    Offset(0.5872, 0.1842),
  ];

  // Normalized 4 Pillars / Spire
  static const List<Offset> _pillar1 = [
    Offset(0.3132, 0.2588),
    Offset(0.2100, 0.2588),
    Offset(0.1655, 0.5471),
    Offset(0.1886, 0.6203),
    Offset(0.2367, 0.6779),
  ];
  static const List<Offset> _pillar2 = [
    Offset(0.4786, 0.2588),
    Offset(0.3737, 0.2672),
    Offset(0.2954, 0.7145),
    Offset(0.3790, 0.7384),
    Offset(0.3986, 0.7173),
  ];
  static const List<Offset> _pillar3 = [
    Offset(0.6459, 0.2588),
    Offset(0.5409, 0.2630),
    Offset(0.4502, 0.7722),
    Offset(0.4626, 0.8256),
    Offset(0.5196, 0.8565),
    Offset(0.5409, 0.8509),
  ];
  static const List<Offset> _rightSpire = [
    Offset(0.8327, 0.1406),
    Offset(0.7295, 0.1421),
    Offset(0.6335, 0.6779),
    Offset(0.7064, 0.6174),
    Offset(0.7598, 0.5331),
  ];

  /// Membuat path perisai dengan kurva Bezier mulus
  Path _createSmoothShieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.50, h * 0.005);
    path.quadraticBezierTo(w * 0.85, h * 0.015, w * 0.95, h * 0.05);
    path.quadraticBezierTo(w * 0.995, h * 0.08, w * 0.995, h * 0.15);
    path.lineTo(w * 0.995, h * 0.66);
    path.cubicTo(w * 0.98, h * 0.78, w * 0.78, h * 0.89, w * 0.50, h * 0.995);
    path.cubicTo(w * 0.22, h * 0.89, w * 0.02, h * 0.78, w * 0.005, h * 0.66);
    path.lineTo(w * 0.005, h * 0.15);
    path.quadraticBezierTo(w * 0.005, h * 0.08, w * 0.05, h * 0.05);
    path.quadraticBezierTo(w * 0.15, h * 0.015, w * 0.50, h * 0.005);
    path.close();

    return path;
  }

  Path _createDiamondPath(List<Offset> points, Size size, double scale) {
    final w = size.width;
    final h = size.height;
    double cx = 0, cy = 0;
    for (final p in points) {
      cx += p.dx * w;
      cy += p.dy * h;
    }
    cx /= points.length;
    cy /= points.length;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final px = cx + (points[i].dx * w - cx) * scale;
      final py = cy + (points[i].dy * h - cy) * scale;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  Path _createCarvedPillarPath(List<Offset> points, Size size, double progress) {
    final w = size.width;
    final h = size.height;

    double minY = points.first.dy * h;
    double maxY = points.first.dy * h;
    for (final p in points) {
      final y = p.dy * h;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final totalHeight = maxY - minY;
    final currentCutBottom = minY + (totalHeight * progress);

    final path = Path();
    path.moveTo(points[0].dx * w, points[0].dy * h);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * w, points[i].dy * h);
    }
    path.close();

    final clipPath = Path()..addRect(Rect.fromLTRB(0, minY - 2, w, currentCutBottom));
    return Path.combine(PathOperation.intersect, path, clipPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Garis Outline Perisai
    if (outlineProgress > 0.0 && shieldFillOpacity < 0.95) {
      final shieldPath = _createSmoothShieldPath(size);
      final metrics = shieldPath.computeMetrics().first;
      final currentLength = metrics.length * outlineProgress;
      final drawnPath = metrics.extractPath(0.0, currentLength);

      final strokePaint = Paint()
        ..color = logoColor.withValues(alpha: (1.0 - shieldFillOpacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(drawnPath, strokePaint);
    }

    // 2. Gambar Perisai Putih/Hijau Solid dengan Ukiran Elemen Dalam (evenOdd)
    if (shieldFillOpacity > 0.0) {
      final solidShield = _createSmoothShieldPath(size);
      solidShield.fillType = PathFillType.evenOdd;

      // Pahat 3 lubang titik intan
      if (dot1Carve > 0.01) {
        solidShield.addPath(_createDiamondPath(_dot1, size, dot1Carve), Offset.zero);
      }
      if (dot2Carve > 0.01) {
        solidShield.addPath(_createDiamondPath(_dot2, size, dot2Carve), Offset.zero);
      }
      if (dot3Carve > 0.01) {
        solidShield.addPath(_createDiamondPath(_dot3, size, dot3Carve), Offset.zero);
      }

      // Pahat 4 lubang pilar vertikal
      if (pillarsCarve > 0.01) {
        solidShield.addPath(_createCarvedPillarPath(_pillar1, size, pillarsCarve), Offset.zero);
        solidShield.addPath(_createCarvedPillarPath(_pillar2, size, pillarsCarve), Offset.zero);
        solidShield.addPath(_createCarvedPillarPath(_pillar3, size, pillarsCarve), Offset.zero);
        solidShield.addPath(_createCarvedPillarPath(_rightSpire, size, pillarsCarve), Offset.zero);
      }

      final fillPaint = Paint()
        ..color = logoColor.withValues(alpha: shieldFillOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawPath(solidShield, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoCarvingPainter oldDelegate) {
    return oldDelegate.outlineProgress != outlineProgress ||
        oldDelegate.shieldFillOpacity != shieldFillOpacity ||
        oldDelegate.dot1Carve != dot1Carve ||
        oldDelegate.dot2Carve != dot2Carve ||
        oldDelegate.dot3Carve != dot3Carve ||
        oldDelegate.pillarsCarve != pillarsCarve ||
        oldDelegate.logoColor != logoColor;
  }
}
