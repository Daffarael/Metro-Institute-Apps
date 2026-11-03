import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';

/// SplashScreen — Clean, Elegant Staged Logo Construction.
///
/// Proses Pembuatan Logo:
/// 1. [0.00 – 0.28] Garis kontur luar perisai digambar secara tenang dan mulus (tanpa titik pemandu, background bersih pekat).
/// 2. [0.28 – 0.42] Perisai terisi warna putih solid secara lembut.
/// 3. [0.42 – 0.65] 3 titik ketupat & 4 pilar kaligrafi "MI" terukir bersih (clean carved cutouts, tanpa garis toska).
/// 4. [0.65 – 0.76] Berkas kilatan cahaya putih bersih (pure white sheen sweep) menyapu diagonal perisai.
/// 5. [0.76 – 0.92] Logo meluncur mulus ke kiri, teks "Metro" disusul "Institute" dan tagline muncul anggun.
/// 6. [0.92 – 1.00] Hold sejenak sebelum dissolve halus menuju halaman utama.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;

  // ── Tahap 1: Outline Tracing (Garis perisai melingkar tanpa titik) ────────
  late Animation<double> _outlineProgress;

  // ── Tahap 2: Pengisian Perisai Putih Solid ────────────────────────────────
  late Animation<double> _shieldFillOpacity;

  // ── Tahap 3: Ukiran Elemen Dalam (Pure Clean Cutouts) ─────────────────────
  late Animation<double> _dot1Carve;
  late Animation<double> _dot2Carve;
  late Animation<double> _dot3Carve;
  late Animation<double> _pillarsCarve;

  // ── Tahap 4: Kilatan Cahaya Putih Bersih ──────────────────────────────────
  late Animation<double> _shimmerProgress;

  // ── Tahap 5: Geser Logo & Tipografi Bertahap ──────────────────────────────
  late Animation<double> _logoShift;
  late Animation<double> _metroOpacity;
  late Animation<double> _metroSlide;
  late Animation<double> _instituteOpacity;
  late Animation<double> _instituteSlide;
  late Animation<double> _taglineOpacity;

  // ── Tahap 6: Exit Dissolve ────────────────────────────────────────────────
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runAnimationSequence();
  }

  void _initAnimations() {
    // 4800ms: Durasi tenang dan anggun agar prosesnya dinikmati tanpa terburu-buru
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    // 1. Tracing Outline: Garis perisai digambar melingkar bersih (0ms – 1350ms)
    _outlineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.02, 0.28, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Perisai putih terisi secara lembut (1350ms – 2000ms)
    _shieldFillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.26, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tiga titik intan terukir bertahap (2000ms – 2500ms): Dot 1 -> Dot 2 -> Dot 3
    _dot1Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.47, curve: Curves.easeOutBack),
      ),
    );
    _dot2Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.52, curve: Curves.easeOutBack),
      ),
    );
    _dot3Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.57, curve: Curves.easeOutBack),
      ),
    );

    // Empat pilar kaligrafi terukir memotong perisai putih turun ke bawah (2400ms – 3100ms)
    _pillarsCarve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.65, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Kilatan Cahaya Putih Bersih menyapu perisai (3100ms – 3650ms)
    _shimmerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.76, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Logo meluncur ke kiri secara sangat mulus (3650ms – 4400ms)
    _logoShift = Tween<double>(begin: 76.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.74, 0.90, curve: Curves.easeInOutCubic),
      ),
    );

    // Kata "Metro" meluncur masuk lembut dari kiri
    _metroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.76, 0.86, curve: Curves.easeOut),
      ),
    );
    _metroSlide = Tween<double>(begin: -14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.76, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // Kata "Institute" menyusul di bawahnya
    _instituteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.81, 0.91, curve: Curves.easeOut),
      ),
    );
    _instituteSlide = Tween<double>(begin: -14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.81, 0.93, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline "Grow Your Digital Future"
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 0.98, curve: Curves.easeOut),
      ),
    );

    // 6. Exit Controller (500ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    // Haptic feedback saat logo selesai ditempa
    _controller.addListener(() {
      if (_controller.value >= 0.65 && !_hasTriggeredHaptic) {
        _hasTriggeredHaptic = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  Future<void> _runAnimationSequence() async {
    try {
      await _controller.forward();
      // Jeda sejenak untuk mengagumi tampilan logo utuh
      await Future.delayed(const Duration(milliseconds: 400));
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
      backgroundColor: const Color(0xFF0F1216), // Solid, bersih pekat, tanpa grid/lingkaran
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _exitController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _exitScale.value,
              child: Opacity(
                opacity: _exitOpacity.value,
                child: Transform.translate(
                  offset: Offset(_logoShift.value, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Logo Canvas (Perisai yang Dibentuk Bertahap) ──
                      SizedBox(
                        width: 82,
                        height: 104,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Ambient Glow Putih Bersih
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.12 * _shieldFillOpacity.value + 0.05 * _outlineProgress.value,
                                      ),
                                      blurRadius: 36,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Staged Carving Custom Painter (Garis outline & ukiran lubang murni tanpa toska)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _LogoCarvingPainter(
                                  outlineProgress: _outlineProgress.value,
                                  shieldFillOpacity: _shieldFillOpacity.value,
                                  dot1Carve: _dot1Carve.value,
                                  dot2Carve: _dot2Carve.value,
                                  dot3Carve: _dot3Carve.value,
                                  pillarsCarve: _pillarsCarve.value,
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
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/images/logo_clean.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => Image.asset('assets/images/logo.png'),
                                    ),
                                  ),
                                ),
                              ),

                            // Pure White Specular Sheen (Kilatan putih bersih saat logo selesai)
                            if (_shimmerProgress.value > 0.01 && _shimmerProgress.value < 0.99)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PureWhiteSheenPainter(progress: _shimmerProgress.value),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Brand Typography (Selalu di tree, tidak ada layout jump!) ──
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Kata "Metro"
                            Transform.translate(
                              offset: Offset(_metroSlide.value, 0),
                              child: Opacity(
                                opacity: _metroOpacity.value,
                                child: Text(
                                  'Metro',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.8,
                                    color: Colors.white,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                            ),

                            // Kata "Institute"
                            Transform.translate(
                              offset: Offset(_instituteSlide.value, 0),
                              child: Opacity(
                                opacity: _instituteOpacity.value,
                                child: Text(
                                  'Institute',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.8,
                                    color: Colors.white,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                            ),

                            // Tagline dengan aksen hijau Metro solid
                            Opacity(
                              opacity: _taglineOpacity.value,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF018556),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Grow Your Digital Future',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom Painter yang menggambar garis perisai (tanpa titik) dan memahat lubang secara bersih
class _LogoCarvingPainter extends CustomPainter {
  final double outlineProgress;
  final double shieldFillOpacity;
  final double dot1Carve;
  final double dot2Carve;
  final double dot3Carve;
  final double pillarsCarve;

  _LogoCarvingPainter({
    required this.outlineProgress,
    required this.shieldFillOpacity,
    required this.dot1Carve,
    required this.dot2Carve,
    required this.dot3Carve,
    required this.pillarsCarve,
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
    // Ukiran turun dari atas ke bawah
    final currentCutBottom = minY + (totalHeight * progress);

    final path = Path();
    path.moveTo(points[0].dx * w, points[0].dy * h);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * w, points[i].dy * h);
    }
    path.close();

    // Clip vertically sesuai kedalaman ukiran
    final clipPath = Path()..addRect(Rect.fromLTRB(0, minY - 2, w, currentCutBottom));
    return Path.combine(PathOperation.intersect, path, clipPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Garis Outline Perisai (Murni Garis Mulus Tanpa Titik)
    if (outlineProgress > 0.0 && shieldFillOpacity < 0.95) {
      final shieldPath = _createSmoothShieldPath(size);
      final metrics = shieldPath.computeMetrics().first;
      final currentLength = metrics.length * outlineProgress;
      final drawnPath = metrics.extractPath(0.0, currentLength);

      // Garis stroke putih bersih
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.90 * (1.0 - shieldFillOpacity)).clamp(0.0, 0.90))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Glow putih lembut di sekitar garis
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.22 * (1.0 - shieldFillOpacity)).clamp(0.0, 0.22))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawPath(drawnPath, glowPaint);
      canvas.drawPath(drawnPath, strokePaint);
      // Titik di ujung garis telah DIHAPUS sesuai permintaan user
    }

    // 2. Gambar Perisai Putih Solid dengan Ukiran Elemen Dalam (PathFillType.evenOdd)
    // Bersih murni hitam/putih, TANPA WARNA TOSKA
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
        ..color = Colors.white.withValues(alpha: shieldFillOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawPath(solidShield, fillPaint);
      // Garis toska laser telah DIHAPUS 100% sehingga ukiran murni bersih
    }
  }

  @override
  bool shouldRepaint(covariant _LogoCarvingPainter oldDelegate) {
    return oldDelegate.outlineProgress != outlineProgress ||
        oldDelegate.shieldFillOpacity != shieldFillOpacity ||
        oldDelegate.dot1Carve != dot1Carve ||
        oldDelegate.dot2Carve != dot2Carve ||
        oldDelegate.dot3Carve != dot3Carve ||
        oldDelegate.pillarsCarve != pillarsCarve;
  }
}

/// Painter untuk menyapukan kilauan cahaya specular putih murni (tanpa toska)
class _PureWhiteSheenPainter extends CustomPainter {
  final double progress;

  _PureWhiteSheenPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-2.5 + progress * 5.0, -1.0),
        end: Alignment(-1.5 + progress * 5.0, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.srcATop;

    canvas.drawRect(rect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _PureWhiteSheenPainter oldDelegate) => oldDelegate.progress != progress;
}
