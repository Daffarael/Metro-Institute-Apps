import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';

/// SplashScreen — Cinematic Staged Logo Construction Animation.
///
/// Tahapan Pembuatan Logo:
/// 1. Blueprint & Outline Tracing: Garis kontur perisai digambar secara bertahap oleh pena cahaya neon.
/// 2. Core Glyph Carving: 3 titik ketupat (diamonds) muncul pop satu per satu, disusul 3 pilar vertikal & sayap kanan terukir naik.
/// 3. Solidification & Specular Shimmer: Bentuk geometris menyatu menjadi perisai solid dengan kilatan cahaya (metallic sheen sweep).
/// 4. Shift & Sequential Wordmark: Logo bergeser ke kiri, kata "Metro" meluncur masuk disusul kata "Institute" dan tagline.
/// 5. Exit Transition: Dissolve mulus ke halaman utama/login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;

  // ── Tahap 1: Blueprint & Outline Tracing (0.0 - 0.28) ──────────────────────
  late Animation<double> _blueprintOpacity;
  late Animation<double> _outlineProgress;

  // ── Tahap 2: Ukiran Elemen Dalam (Diamonds & Pillars) (0.28 - 0.48) ────────
  late Animation<double> _dot1Scale;
  late Animation<double> _dot2Scale;
  late Animation<double> _dot3Scale;
  late Animation<double> _pillarsProgress;

  // ── Tahap 3: Solidifikasi & Kilau Cahaya (0.48 - 0.62) ─────────────────────
  late Animation<double> _solidFill;
  late Animation<double> _shimmerProgress;

  // ── Tahap 4: Geser Logo & Tipografi Bertahap (0.62 - 0.85) ──────────────────
  late Animation<double> _logoShift;
  late Animation<double> _metroOpacity;
  late Animation<double> _metroSlide;
  late Animation<double> _instituteOpacity;
  late Animation<double> _instituteSlide;
  late Animation<double> _taglineOpacity;

  // ── Tahap 5: Exit Dissolve ──────────────────────────────────────────────────
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 1. Blueprint Grid & Guidance Lines (Fade in & slowly fade out)
    _blueprintOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65),
    ));

    // Outline path tracing: Menggambar keliling perisai (0ms - 900ms)
    _outlineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.02, 0.28, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Tiga Titik Intan (Diamonds) muncul estafet: Dot 1 -> Dot 2 -> Dot 3
    _dot1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.36, curve: Curves.easeOutBack),
      ),
    );
    _dot2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.41, curve: Curves.easeOutBack),
      ),
    );
    _dot3Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.46, curve: Curves.easeOutBack),
      ),
    );

    // Pilar & Spire mengukir naik dari bawah ke atas
    _pillarsProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Solidifikasi menyatu penuh & Kilau Cahaya (Shimmer) meluncur
    _solidFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.58, curve: Curves.easeOut),
      ),
    );
    _shimmerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.64, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Logo bergeser ke kiri (76px -> 0px)
    _logoShift = Tween<double>(begin: 84.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.64, 0.82, curve: Curves.easeInOutCubic),
      ),
    );

    // Teks "Metro" meluncur dari kiri dan memudar jelas
    _metroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.78, curve: Curves.easeOut),
      ),
    );
    _metroSlide = Tween<double>(begin: -16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Teks "Institute" menyusul di bawahnya
    _instituteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.84, curve: Curves.easeOut),
      ),
    );
    _instituteSlide = Tween<double>(begin: -16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.86, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline kecil "Grow Your Digital Future"
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 0.94, curve: Curves.easeOut),
      ),
    );

    // 5. Exit Controller
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    // Listener untuk haptic feedback saat logo berhasil terkunci
    _controller.addListener(() {
      if (_controller.value >= 0.52 && !_hasTriggeredHaptic) {
        _hasTriggeredHaptic = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  Future<void> _runAnimationSequence() async {
    try {
      await _controller.forward();
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
      backgroundColor: const Color(0xFF0A0D12), // Deep luxurious dark background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Blueprint Grid (Muncul saat proses pembuatan logo)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_blueprintOpacity.value <= 0.01) return const SizedBox.shrink();
              return Opacity(
                opacity: _blueprintOpacity.value,
                child: CustomPaint(
                  painter: _BlueprintGridPainter(),
                  size: Size.infinite,
                ),
              );
            },
          ),

          // Main Center Stage
          Center(
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
                          // ── Logo Canvas: Visual Proses Pembuatan Logo ──
                          SizedBox(
                            width: 82,
                            height: 104,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Aura / Ambient Glow
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.12 * _solidFill.value + 0.06 * _outlineProgress.value,
                                          ),
                                          blurRadius: 36,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 1. Staged Vector Construction Painter
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _LogoConstructionPainter(
                                      outlineProgress: _outlineProgress.value,
                                      dot1Progress: _dot1Scale.value,
                                      dot2Progress: _dot2Scale.value,
                                      dot3Progress: _dot3Scale.value,
                                      pillarsProgress: _pillarsProgress.value,
                                      solidFillProgress: _solidFill.value,
                                    ),
                                  ),
                                ),

                                // 2. Solid High-Res Shield (Memudar masuk saat proses perakitan selesai)
                                if (_solidFill.value > 0.01)
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: _solidFill.value,
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

                                // 3. Metallic Shimmer Light Sweep (Kilatan cahaya saat logo terkunci)
                                if (_shimmerProgress.value > 0.01 && _shimmerProgress.value < 0.99)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _LightSweepPainter(progress: _shimmerProgress.value),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ── Brand Typography: Bertahap Muncul Setelah Logo Jadi ──
                          if (_controller.value >= 0.62)
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

                                  // Sub-tagline elegan
                                  if (_taglineOpacity.value > 0.01) ...[
                                    const SizedBox(height: 5),
                                    Opacity(
                                      opacity: _taglineOpacity.value,
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
                                  ],
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
        ],
      ),
    );
  }
}

/// Painter untuk menggambar garis outline, titik 3 intan, dan pilar secara bertahap
class _LogoConstructionPainter extends CustomPainter {
  final double outlineProgress;
  final double dot1Progress;
  final double dot2Progress;
  final double dot3Progress;
  final double pillarsProgress;
  final double solidFillProgress;

  _LogoConstructionPainter({
    required this.outlineProgress,
    required this.dot1Progress,
    required this.dot2Progress,
    required this.dot3Progress,
    required this.pillarsProgress,
    required this.solidFillProgress,
  });

  // Normalized shield polygon boundary (13 exact points)
  static const List<Offset> _shieldBoundary = [
    Offset(0.0569, 0.0436),
    Offset(0.0018, 0.0788),
    Offset(0.0036, 0.6793),
    Offset(0.0819, 0.7778),
    Offset(0.2082, 0.8720),
    Offset(0.4431, 0.9831),
    Offset(0.5285, 0.9930),
    Offset(0.8238, 0.8509),
    Offset(0.9911, 0.6878),
    Offset(0.9964, 0.0759),
    Offset(0.8683, 0.0267),
    Offset(0.6210, 0.0028),
    Offset(0.2829, 0.0084),
  ];

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

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Gambar Garis Outline Perisai (Tracing Stroke)
    if (outlineProgress > 0.0) {
      final shieldPath = Path();
      shieldPath.moveTo(_shieldBoundary[0].dx * w, _shieldBoundary[0].dy * h);
      for (int i = 1; i < _shieldBoundary.length; i++) {
        shieldPath.lineTo(_shieldBoundary[i].dx * w, _shieldBoundary[i].dy * h);
      }
      shieldPath.close();

      final metrics = shieldPath.computeMetrics().first;
      final currentLength = metrics.length * outlineProgress;
      final drawnPath = metrics.extractPath(0.0, currentLength);

      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 + 0.15 * solidFillProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Glow outline
      final glowPaint = Paint()
        ..color = const Color(0xFF018556).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawPath(drawnPath, glowPaint);
      canvas.drawPath(drawnPath, strokePaint);

      // Glowing Tracer Spark at the leading edge of drawing
      if (outlineProgress > 0.01 && outlineProgress < 0.99) {
        final tangent = metrics.getTangentForOffset(currentLength);
        if (tangent != null) {
          final sparkGlow = Paint()
            ..color = const Color(0xFF00F0FF).withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
          final sparkCore = Paint()..color = Colors.white;

          canvas.drawCircle(tangent.position, 5.0, sparkGlow);
          canvas.drawCircle(tangent.position, 2.4, sparkCore);
        }
      }
    }

    // 2. Gambar 3 Titik Intan (Diamonds)
    _drawDiamond(canvas, size, _dot1, dot1Progress);
    _drawDiamond(canvas, size, _dot2, dot2Progress);
    _drawDiamond(canvas, size, _dot3, dot3Progress);

    // 3. Gambar 4 Pilar / Spire Dalam Perisai (Carving from bottom to top)
    if (pillarsProgress > 0.0) {
      _drawCarvedPillar(canvas, size, _pillar1, pillarsProgress);
      _drawCarvedPillar(canvas, size, _pillar2, pillarsProgress);
      _drawCarvedPillar(canvas, size, _pillar3, pillarsProgress);
      _drawCarvedPillar(canvas, size, _rightSpire, pillarsProgress);
    }
  }

  void _drawDiamond(Canvas canvas, Size size, List<Offset> points, double scale) {
    if (scale <= 0.001) return;
    final w = size.width;
    final h = size.height;

    // Hitung pusat titik intan
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

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.9 * scale).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.4 * scale).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, fillPaint);
  }

  void _drawCarvedPillar(Canvas canvas, Size size, List<Offset> points, double progress) {
    final w = size.width;
    final h = size.height;

    // Hitung minY dan maxY dari polygon
    double minY = points.first.dy * h;
    double maxY = points.first.dy * h;
    for (final p in points) {
      final y = p.dy * h;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final totalHeight = maxY - minY;
    // Reveal naik dari bawah ke atas
    final currentCutY = maxY - (totalHeight * progress);

    canvas.save();
    // Clip rect yang membesar dari bawah ke atas
    canvas.clipRect(Rect.fromLTRB(0, currentCutY, w, maxY + 2));

    final path = Path();
    path.moveTo(points[0].dx * w, points[0].dy * h);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * w, points[i].dy * h);
    }
    path.close();

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.85 * progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: (0.7 * (1.0 - progress)).clamp(0.0, 0.7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, fillPaint);
    if (progress < 0.95) {
      canvas.drawPath(path, strokePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoConstructionPainter oldDelegate) {
    return oldDelegate.outlineProgress != outlineProgress ||
        oldDelegate.dot1Progress != dot1Progress ||
        oldDelegate.dot2Progress != dot2Progress ||
        oldDelegate.dot3Progress != dot3Progress ||
        oldDelegate.pillarsProgress != pillarsProgress ||
        oldDelegate.solidFillProgress != solidFillProgress;
  }
}

/// Painter untuk menyapukan kilauan cahaya specular diagonal saat logo selesai
class _LightSweepPainter extends CustomPainter {
  final double progress;

  _LightSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-2.5 + progress * 5.0, -1.0),
        end: Alignment(-1.5 + progress * 5.0, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.srcATop;

    canvas.drawRect(rect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _LightSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Painter untuk latar belakang grid blueprint arsitektural halus
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF018556).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Circular radar guide in center
    final center = Offset(size.width / 2, size.height / 2);
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 90, circlePaint);
    canvas.drawCircle(center, 150, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _BlueprintGridPainter oldDelegate) => false;
}
