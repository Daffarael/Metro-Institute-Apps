import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';

/// SplashScreen — Cinematic Pendant Lamp & Staged Logo Construction.
///
/// Urutan Animasi:
/// 1. [0.00 – 0.10] Ruangan gelap pekat, lampu gantung & tali saklar tergantung diam.
/// 2. [0.10 – 0.18] Tali saklar ditarik ke bawah (pull down) lalu memantul kembali (snap back).
/// 3. [0.16 – 0.28] Lampu "KLIK" MENYALA! Filamen memijar hangat, menyorotkan cahaya ke bawah dan menerangi ruangan jadi Hijau Zamrud (#063D2A).
/// 4. [0.28 – 0.48] Garis kontur luar perisai digambar bersih di bawah sorotan cahaya lampu.
/// 5. [0.48 – 0.62] Perisai terisi warna putih solid secara lembut.
/// 6. [0.62 – 0.80] 3 titik ketupat & 4 pilar kaligrafi "MI" terukir bersih (cutouts menembus ke hijau zamrud).
/// 7. [0.80 – 0.94] Logo meluncur mulus ke kiri, teks "Metro" dan "Institute" putih muncul anggun.
/// 8. [0.94 – 1.00] Hold sejenak sebelum dissolve halus menuju halaman berikutnya.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;

  // ── Tahap 1: Animasi Lampu Gantung & Tali Saklar ───────────────────────────
  late Animation<double> _cordPull;
  late Animation<double> _lampGlow;

  // ── Tahap 2: Outline Tracing (Garis perisai) ──────────────────────────────
  late Animation<double> _outlineProgress;

  // ── Tahap 3: Pengisian Perisai Putih Solid ────────────────────────────────
  late Animation<double> _shieldFillOpacity;

  // ── Tahap 4: Ukiran Elemen Dalam (Pure Clean Cutouts) ─────────────────────
  late Animation<double> _dot1Carve;
  late Animation<double> _dot2Carve;
  late Animation<double> _dot3Carve;
  late Animation<double> _pillarsCarve;

  // ── Tahap 5: Geser Logo & Tipografi Bertahap ──────────────────────────────
  late Animation<double> _logoShift;
  late Animation<double> _metroOpacity;
  late Animation<double> _metroSlide;
  late Animation<double> _instituteOpacity;
  late Animation<double> _instituteSlide;

  // ── Tahap 6: Exit Dissolve ────────────────────────────────────────────────
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  bool _hasTriggeredClickHaptic = false;
  bool _hasTriggeredCarveHaptic = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runAnimationSequence();
  }

  void _initAnimations() {
    // 5200ms: Durasi sinematik yang tenang dan elegan
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    // 1. Tali saklar ditarik ke bawah lalu memantul kembali (400ms – 900ms)
    _cordPull = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.20),
      ),
    );

    // 2. Lampu "KLIK" MENYALA! Filamen memijar hangat dan ruangan terang (800ms – 1450ms)
    _lampGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.28, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tracing Outline: Garis perisai digambar melingkar tajam & bersih (1450ms – 2500ms)
    _outlineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.48, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Perisai putih terisi secara lembut (2500ms – 3200ms)
    _shieldFillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    // 5. Tiga titik intan terukir bertahap (3200ms – 3700ms)
    _dot1Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.69, curve: Curves.easeOutBack),
      ),
    );
    _dot2Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.73, curve: Curves.easeOutBack),
      ),
    );
    _dot3Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.77, curve: Curves.easeOutBack),
      ),
    );

    // Empat pilar kaligrafi terukir memotong perisai putih turun ke bawah (3500ms – 4200ms)
    _pillarsCarve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.81, curve: Curves.easeInOutCubic),
      ),
    );

    // 6. Logo meluncur ke kiri secara sangat mulus (4200ms – 4900ms)
    _logoShift = Tween<double>(begin: 76.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.81, 0.93, curve: Curves.easeInOutCubic),
      ),
    );

    // Kata "Metro" meluncur masuk lembut dari kiri
    _metroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.83, 0.92, curve: Curves.easeOut),
      ),
    );
    _metroSlide = Tween<double>(begin: -14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.83, 0.93, curve: Curves.easeOutCubic),
      ),
    );

    // Kata "Institute" menyusul di bawahnya
    _instituteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.86, 0.95, curve: Curves.easeOut),
      ),
    );
    _instituteSlide = Tween<double>(begin: -14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.86, 0.96, curve: Curves.easeOutCubic),
      ),
    );

    // 7. Exit Controller (500ms)
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

    // Haptic feedback saat saklar klik & ukiran selesai
    _controller.addListener(() {
      if (_controller.value >= 0.16 && !_hasTriggeredClickHaptic) {
        _hasTriggeredClickHaptic = true;
        HapticFeedback.mediumImpact(); // Sensasi klik mekanis saklar
      }
      if (_controller.value >= 0.81 && !_hasTriggeredCarveHaptic) {
        _hasTriggeredCarveHaptic = true;
        HapticFeedback.lightImpact(); // Sensasi ukiran selesai
      }
    });
  }

  Future<void> _runAnimationSequence() async {
    try {
      await _controller.forward();
      // Jeda sejenak untuk mengagumi tampilan logo utuh di bawah sorotan lampu
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
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _exitController]),
        builder: (context, child) {
          // Latar belakang bertransisi dinamis dari gelap pekat (#020E08) ke Hijau Zamrud Metro (#063D2A)
          final backgroundColor = Color.lerp(
            const Color(0xFF020E08),
            const Color(0xFF063D2A),
            _lampGlow.value,
          )!;

          return Container(
            color: backgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── LAYER 1: Lampu Gantung Sinematik & Sorotan Cahaya ───────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 380,
                  child: CustomPaint(
                    painter: _PendantLampPainter(
                      cordPull: _cordPull.value,
                      glow: _lampGlow.value,
                      lampDrop: 70.0,
                    ),
                  ),
                ),

                // ── LAYER 2: Logo Perisai & Tipografi Metro Institute ──────
                Center(
                  child: Transform.scale(
                    scale: _exitScale.value,
                    child: Opacity(
                      opacity: _exitOpacity.value,
                      child: Transform.translate(
                        offset: Offset(_logoShift.value, 20), // Posisi pas di bawah sorotan lampu
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Logo Canvas (Perisai yang Dibentuk Bertahap Murni) ──
                            SizedBox(
                              width: 82,
                              height: 104,
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

                                  // Kata "Institute" putih bersih
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom Painter untuk Lampu Gantung Sinematik & Tali Saklar (Pull Cord)
class _PendantLampPainter extends CustomPainter {
  final double cordPull;
  final double glow;
  final double lampDrop;

  _PendantLampPainter({
    required this.cordPull,
    required this.glow,
    this.lampDrop = 70.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // 1. Sorotan Berkas Cahaya Lampu (Soft Volumetric Downlight Cone)
    if (glow > 0.01) {
      final shadeBottomY = lampDrop + 32.0;

      // Cone penyinaran yang melebar ke bawah
      final conePath = Path()
        ..moveTo(cx - 32, shadeBottomY + 4)
        ..lineTo(cx + 32, shadeBottomY + 4)
        ..lineTo(size.width * 0.95, size.height)
        ..lineTo(size.width * 0.05, size.height)
        ..close();

      final conePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFAE653).withValues(alpha: (0.28 * glow).clamp(0.0, 1.0)),
            const Color(0xFFFAE653).withValues(alpha: (0.08 * glow).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromLTWH(0, shadeBottomY, size.width, size.height - shadeBottomY));

      canvas.drawPath(conePath, conePaint);

      // Pendaran Radial Halo di sekitar bohlam
      final bloomCenter = Offset(cx, shadeBottomY + 3);
      final bloomRadius = 52.0 * glow;
      final bloomPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF6D6).withValues(alpha: (0.70 * glow).clamp(0.0, 1.0)),
            const Color(0xFFFAE653).withValues(alpha: (0.32 * glow).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: bloomCenter, radius: bloomRadius));
      canvas.drawCircle(bloomCenter, bloomRadius, bloomPaint);
    }

    // 2. Mangkuk Plafon (Ceiling Canopy Cup)
    final cupPaint = Paint()..color = const Color(0xFF161F1A);
    final cupRect = Rect.fromCenter(center: Offset(cx, 0), width: 34, height: 16);
    canvas.drawArc(cupRect, 0, math.pi, true, cupPaint);

    // 3. Kabel Gantung (Pendant Cable)
    final cablePaint = Paint()
      ..color = const Color(0xFF1E2822)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, 0), Offset(cx, lampDrop), cablePaint);

    // 4. Kap Lampu Minimalis (Dome Shade)
    final shadeTopY = lampDrop;
    const shadeHeight = 32.0;
    final shadeBottomY = shadeTopY + shadeHeight;

    final shadePath = Path()
      ..moveTo(cx - 7, shadeTopY)
      ..lineTo(cx + 7, shadeTopY)
      ..quadraticBezierTo(cx + 12, shadeTopY + 10, cx + 36, shadeBottomY)
      ..lineTo(cx - 36, shadeBottomY)
      ..quadraticBezierTo(cx - 12, shadeTopY + 10, cx - 7, shadeTopY)
      ..close();

    final shadeGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF3D4D44),
        Color(0xFF1F2B24),
        Color(0xFF121A15),
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(cx - 38, shadeTopY, 76, shadeHeight));

    final shadePaint = Paint()
      ..shader = shadeGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadePath, shadePaint);

    // Garis bibir kap lampu (Rim Lip)
    final rimPaint = Paint()
      ..color = const Color(0xFF5A6E62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx - 36, shadeBottomY), Offset(cx + 36, shadeBottomY), rimPaint);

    // 5. Bohlam Kaca & Filamen Pijar (Glass Bulb & Hot Filament)
    final bulbCenter = Offset(cx, shadeBottomY + 6);
    const bulbRadius = 11.5;

    // Kaca Bohlam
    final glassFill = Paint()
      ..color = glow > 0.01
          ? Color.lerp(const Color(0x33FFFFFF), const Color(0x99FFEAA8), glow)!
          : const Color(0x22FFFFFF);
    canvas.drawCircle(bulbCenter, bulbRadius, glassFill);

    final glassStroke = Paint()
      ..color = glow > 0.01
          ? Color.lerp(const Color(0x66FFFFFF), const Color(0xEEFFF8DB), glow)!
          : const Color(0x44FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(bulbCenter, bulbRadius, glassStroke);

    // Filamen di dalam bohlam (memijar merah -> kuning putih saat glow naik)
    final filamentPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    if (glow > 0.01) {
      filamentPaint.color = Color.lerp(const Color(0xFFFF5722), const Color(0xFFFFFFFF), glow)!;
    } else {
      filamentPaint.color = const Color(0xFF4A5550);
    }

    final filamentPath = Path()
      ..moveTo(cx - 3.5, shadeBottomY + 1)
      ..lineTo(cx - 2.5, bulbCenter.dy + 1)
      ..lineTo(cx, bulbCenter.dy - 3)
      ..lineTo(cx + 2.5, bulbCenter.dy + 1)
      ..lineTo(cx + 3.5, shadeBottomY + 1);
    canvas.drawPath(filamentPath, filamentPaint..style = PaintingStyle.stroke);

    // 6. Tali Saklar (Pull Cord) & Bandul Emas (Acorn)
    final cordAnchorX = cx + 20.0;
    final cordAnchorY = shadeBottomY;
    const baseCordLength = 46.0;
    final currentPullOffset = cordPull * 22.0; // Tali ditarik ke bawah 22px
    final acornY = cordAnchorY + baseCordLength + currentPullOffset;

    // Tali saklar
    final cordPaint = Paint()
      ..color = const Color(0xFFD4AF37) // Warna anyaman emas
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cordAnchorX, cordAnchorY), Offset(cordAnchorX, acornY), cordPaint);

    // Bandul (Acorn) Emas
    final acornPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFAE653), // Metro Yellow Gold
          Color(0xFFB88E18),
        ],
      ).createShader(Rect.fromLTWH(cordAnchorX - 3.5, acornY, 7, 12));

    final acornPath = Path()
      ..moveTo(cordAnchorX - 2.5, acornY)
      ..lineTo(cordAnchorX + 2.5, acornY)
      ..lineTo(cordAnchorX + 3.5, acornY + 6)
      ..quadraticBezierTo(cordAnchorX, acornY + 11, cordAnchorX - 3.5, acornY + 6)
      ..close();
    canvas.drawPath(acornPath, acornPaint);
  }

  @override
  bool shouldRepaint(covariant _PendantLampPainter oldDelegate) {
    return oldDelegate.cordPull != cordPull ||
        oldDelegate.glow != glow ||
        oldDelegate.lampDrop != lampDrop;
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
        ..color = Colors.white.withValues(alpha: (1.0 - shieldFillOpacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(drawnPath, strokePaint);
    }

    // 2. Gambar Perisai Putih Solid dengan Ukiran Elemen Dalam (evenOdd)
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
