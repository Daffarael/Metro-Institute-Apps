import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';

/// SplashScreen — Photorealistic Tactile Pull-Cord Pendant Lamp & Staged Logo Construction.
///
/// Urutan Animasi:
/// 1. [0.00 – 0.08] Ruangan gelap pekat (#020906), lampu gantung putih satin/aluminium
///    dan tali saklar tergantung diam (persis seperti referensi foto kondisi OFF).
/// 2. [0.08 – 0.20] Tali saklar ditarik ke bawah secara mulus oleh tangan tak terlihat,
///    lalu lepas dan memantul cepat (elastic snap-back).
/// 3. [0.16 – 0.30] Saklar "KLIK!" (Haptic feedback). Filamen tungsten memijar hangat
///    berdasarkan kurva radiasi Blackbody (merah bara -> oranye menyala -> putih pijar).
///    Interior kap lampu menyala emas tembaga cerah, menyemburkan sorotan berkas downlight
///    scallop ke dinding/latar belakang, mengubah ruangan menjadi Hijau Zamrud Metro (#063D2A).
/// 4. [0.28 – 0.48] Di bawah cahaya lampu, garis kontur luar perisai digambar bersih melingkar.
/// 5. [0.48 – 0.62] Perisai terisi warna putih solid secara lembut.
/// 6. [0.62 – 0.81] 3 titik intan & 4 pilar kaligrafi terukir menembus perisai putih ke hijau zamrud.
/// 7. [0.81 – 0.93] Logo meluncur mulus ke kiri, teks "Metro" dan "Institute" putih muncul anggun.
/// 8. [0.93 – 1.00] Hold sejenak sebelum dissolve halus menuju halaman berikutnya.
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
    // 5300ms: Durasi sinematik yang tenang, berbobot, dan memukau
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5300),
    );

    // 1. Tali saklar ditarik ke bawah lalu membal elastis (snap-back)
    _cordPull = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 58,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.22),
      ),
    );

    // 2. Lampu menyala! Filamen memijar hangat dan menyinari ruangan (800ms – 1550ms)
    _lampGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tracing Outline: Garis luar perisai digambar tajam & bersih (1450ms – 2500ms)
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

    // Empat pilar kaligrafi terukir memotong perisai putih turun ke bawah (3500ms – 4250ms)
    _pillarsCarve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.81, curve: Curves.easeInOutCubic),
      ),
    );

    // 6. Logo meluncur ke kiri secara sangat mulus (4250ms – 4900ms)
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
          // Latar belakang bertransisi dinamis dari malam pekat (#020906) ke Hijau Zamrud Metro (#063D2A)
          final backgroundColor = Color.lerp(
            const Color(0xFF020906),
            const Color(0xFF063D2A),
            _lampGlow.value,
          )!;

          return Container(
            color: backgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── LAYER 1: Sorotan Cahaya Downlight Scallop di Dinding ───
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WallLightScallopPainter(
                      glow: _lampGlow.value,
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
                        offset: Offset(_logoShift.value, 46), // Posisi proporsional di bawah lampu
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

                // ── LAYER 3: Lampu Gantung Sinematik & Tali Saklar (Pull-Cord Bulb) ──
                // Diposisikan tepat di atas layar, persis seperti foto referensi
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 440,
                  child: CustomPaint(
                    painter: _PendantLampPainter(
                      cordPull: _cordPull.value,
                      glow: _lampGlow.value,
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

/// Custom Painter untuk Sorotan Berkas Cahaya di Dinding (Wall Downlight Scallop)
class _WallLightScallopPainter extends CustomPainter {
  final double glow;

  _WallLightScallopPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    if (glow <= 0.005) return;

    final cx = size.width / 2;
    const rimY = 162.0;

    // 1. Scallop downlight cone melebar ke bawah
    final conePath = Path()
      ..moveTo(cx - 100, rimY + 6)
      ..lineTo(cx + 100, rimY + 6)
      ..lineTo(size.width * 1.15, size.height)
      ..lineTo(-size.width * 0.15, size.height)
      ..close();

    final conePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFAE653).withValues(alpha: (0.35 * glow).clamp(0.0, 1.0)),
          const Color(0xFF018556).withValues(alpha: (0.28 * glow).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(-size.width * 0.15, rimY, size.width * 1.3, size.height - rimY));

    canvas.drawPath(conePath, conePaint);

    // 2. Ambient radial golden wash di area logo
    final washCenter = Offset(cx, size.height * 0.52);
    final washPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFAE653).withValues(alpha: (0.16 * glow).clamp(0.0, 1.0)),
          const Color(0xFF018556).withValues(alpha: (0.08 * glow).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: washCenter, radius: size.width * 0.75));

    canvas.drawCircle(washCenter, size.width * 0.75, washPaint);
  }

  @override
  bool shouldRepaint(covariant _WallLightScallopPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}

/// Custom Painter untuk Lampu Gantung Sinematik (Pull-Cord Bulb)
/// Mengikuti 100% anatomi foto referensi:
/// - Mangkuk plafon aluminium satin (Canopy Cup)
/// - Kabel gantung lurus
/// - Leher/Kerah fitting (Collar)
/// - Kap Kubah Putih Matte/Aluminium (Dome Shade 216px) dengan pencahayaan 3D realistis
/// - Underside Enamel Cavity: hitam pekat saat MATI, kuning keemasan membara saat HIDUP
/// - Bohlam kaca jernih dengan filamen tungsten Blackbody (dingin saat OFF, memijar putih-hangat saat ON)
/// - Soket saklar logam di sisi kanan
/// - Tali saklar putih satin & bandul buah ek (Acorn) terbalik
class _PendantLampPainter extends CustomPainter {
  final double cordPull;
  final double glow;

  _PendantLampPainter({
    required this.cordPull,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // ── Geometri Lampu Berdasarkan Anatomi Fisik Referensi ──
    const canopyTopY = 0.0;
    const canopyHeight = 16.0;
    const canopyWidth = 52.0;

    const cableTopY = canopyHeight;
    const cableLength = 38.0;
    const cableBottomY = cableTopY + cableLength; // 54.0

    const collarHeight = 18.0;
    const collarWidth = 18.0;
    const domeTopY = cableBottomY + collarHeight; // 72.0

    const domeRadius = 108.0; // Lebar total kubah: 216.0 px (Sangat anggun & proporsional)
    const domeHeight = 90.0;
    const rimY = domeTopY + domeHeight; // 162.0
    const elevation = 0.17; // Sudut pandang perspektif dari bawah
    const rimMinorRadius = domeRadius * elevation; // 18.36

    final bulbCenter = Offset(cx, rimY + 16.0); // 178.0
    const bulbRadius = 25.0; // Diameter 50.0 px

    final cordAnchorX = cx + 56.0; // Soket tali di sisi kanan bawah kap
    const cordAnchorY = rimY - 2.0;
    const baseCordLength = 145.0;
    final currentPullOffset = cordPull * 32.0; // Tali ditarik 32px ke bawah
    final acornY = cordAnchorY + 14.0 + baseCordLength + currentPullOffset;

    // ── 0. Volumetric Light Bloom (Pendaran Cahaya Bohlam) ────────────────
    if (glow > 0.01) {
      // Core Bloom (Putih keemasan intens di sekitar filamen)
      final coreBloom = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: (0.92 * glow).clamp(0.0, 1.0)),
            const Color(0xFFFFF7D6).withValues(alpha: (0.75 * glow).clamp(0.0, 1.0)),
            const Color(0xFFFFB84D).withValues(alpha: (0.35 * glow).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: bulbCenter, radius: 46.0 * glow));
      canvas.drawCircle(bulbCenter, 46.0 * glow, coreBloom);

      // Wide Ambient Halo (Menyebar lembut ke bawah kap)
      final wideHalo = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFB03A).withValues(alpha: (0.45 * glow).clamp(0.0, 1.0)),
            const Color(0xFFFF8C00).withValues(alpha: (0.18 * glow).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: bulbCenter, radius: 140.0 * glow));
      canvas.drawCircle(bulbCenter, 140.0 * glow, wideHalo);
    }

    // ── 1. Mangkuk Plafon (Ceiling Canopy Cup) ─────────────────────────────
    final canopyRect = Rect.fromCenter(
      center: Offset(cx, canopyTopY + (canopyHeight / 2)),
      width: canopyWidth,
      height: canopyHeight,
    );
    final canopyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE2E6E9),
          Color(0xFFB5BAC0),
          Color(0xFF8B9298),
        ],
        stops: [0.05, 0.35, 0.75, 1.0],
      ).createShader(canopyRect);

    final canopyPath = Path()
      ..moveTo(cx - (canopyWidth / 2), canopyTopY)
      ..lineTo(cx + (canopyWidth / 2), canopyTopY)
      ..lineTo(cx + (canopyWidth / 2) - 3, canopyTopY + canopyHeight)
      ..lineTo(cx - (canopyWidth / 2) + 3, canopyTopY + canopyHeight)
      ..close();
    canvas.drawPath(canopyPath, canopyPaint);

    // Garis rim bawah canopy
    final canopyRimPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - (canopyWidth / 2) + 3, canopyTopY + canopyHeight),
      Offset(cx + (canopyWidth / 2) - 3, canopyTopY + canopyHeight),
      canopyRimPaint,
    );

    // ── 2. Kabel Gantung (Pendant Cable / Stem) ───────────────────────────
    final cableRect = Rect.fromLTWH(cx - 1.8, cableTopY, 3.6, cableLength);
    final cablePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFD6DBDE),
          Color(0xFF8B9399),
        ],
      ).createShader(cableRect);
    canvas.drawRect(cableRect, cablePaint);

    // ── 3. Leher Kerah Fitting (Collar Top of Dome) ───────────────────────
    final collarRect = Rect.fromCenter(
      center: Offset(cx, cableBottomY + (collarHeight / 2)),
      width: collarWidth,
      height: collarHeight,
    );
    final collarPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFDDE1E4),
          Color(0xFF9AA1A7),
          Color(0xFF70777D),
        ],
        stops: [0.08, 0.38, 0.78, 1.0],
      ).createShader(collarRect);
    canvas.drawRRect(RRect.fromRectAndRadius(collarRect, const Radius.circular(2.5)), collarPaint);

    // Cincin dasar collar
    final collarBaseRect = Rect.fromCenter(
      center: Offset(cx, domeTopY),
      width: collarWidth + 6,
      height: 4.0,
    );
    canvas.drawOval(collarBaseRect, collarPaint);

    // ── 4. Rongga Dalam Kap Lampu (Inner Enamel Cavity) ───────────────────
    // Dilihat dari bawah sebagai elips dengan kedalaman perspektif
    final innerCavityRect = Rect.fromCenter(
      center: Offset(cx, rimY),
      width: domeRadius * 2,
      height: rimMinorRadius * 2,
    );

    final innerCavityPaint = Paint();
    if (glow > 0.01) {
      // KONDISI HIDUP: Menyala emas membara cerah (Luminous Amber Enamel)!
      innerCavityPaint.shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.9,
        colors: [
          Color.lerp(const Color(0xFF222527), const Color(0xFFFFF2A8), glow)!,
          Color.lerp(const Color(0xFF161819), const Color(0xFFFFAC38), glow)!,
          Color.lerp(const Color(0xFF0F1011), const Color(0xFFE65100), glow)!,
          Color.lerp(const Color(0xFF0A0B0C), const Color(0xFF8C2700), glow)!,
        ],
        stops: const [0.0, 0.40, 0.80, 1.0],
      ).createShader(innerCavityRect);
    } else {
      // KONDISI MATI: Rongga gelap gulita persis foto referensi
      innerCavityPaint.shader = const RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 0.9,
        colors: [
          Color(0xFF242729),
          Color(0xFF181A1B),
          Color(0xFF0D0E0F),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(innerCavityRect);
    }
    canvas.drawOval(innerCavityRect, innerCavityPaint);

    // ── 5. Permukaan Luar Kap Kubah (White / Aluminium Dome Shade) ─────────
    // Kubah setengah bola mulus dengan bayangan 3D matte spun aluminium
    final domePath = Path()
      ..moveTo(cx - domeRadius, rimY)
      // Busur kubah atas dari kiri ke kanan
      ..arcToPoint(
        Offset(cx + domeRadius, rimY),
        radius: const Radius.elliptical(domeRadius, domeHeight),
        clockwise: true,
      )
      // Busur bibir depan bawah kap menutup kubah
      ..arcToPoint(
        Offset(cx - domeRadius, rimY),
        radius: const Radius.elliptical(domeRadius, rimMinorRadius),
        clockwise: false,
      )
      ..close();

    final domeShader = const LinearGradient(
      begin: Alignment(-0.85, -0.95),
      end: Alignment(0.85, 0.85),
      colors: [
        Color(0xFFFFFFFF), // Highlight pantulan cahaya ruang atas kiri
        Color(0xFFF3F5F7),
        Color(0xFFE0E4E7), // Warna dasar putih satin / spun aluminium
        Color(0xFFC4CBD0),
        Color(0xFF9AA1A7), // Bayangan lengkungan bawah kanan
      ],
      stops: [0.0, 0.22, 0.58, 0.82, 1.0],
    ).createShader(Rect.fromLTWH(cx - domeRadius, domeTopY, domeRadius * 2, domeHeight + rimMinorRadius));

    final domePaint = Paint()
      ..shader = domeShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(domePath, domePaint);

    // Bibir Roll Bawah Kap (Rolled Rim Lip Catch-Light & Shadow)
    final frontLipPath = Path()
      ..moveTo(cx - domeRadius, rimY)
      ..arcToPoint(
        Offset(cx + domeRadius, rimY),
        radius: const Radius.elliptical(domeRadius, rimMinorRadius),
        clockwise: false,
      );

    // Kilauan garis putih pada bibir depan
    final frontLipPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(frontLipPath, frontLipPaint);

    // Bayangan halus di bawah bibir
    final lipShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawOval(innerCavityRect, lipShadowPaint);

    // ── 6. Bohlam Kaca Jernih & Filamen Tungsten (Clear Bulb & Filament) ────
    final bulbRect = Rect.fromCircle(center: bulbCenter, radius: bulbRadius);

    // Kaca Bohlam (Transparan dengan pantulan specular)
    final glassFillPaint = Paint();
    if (glow > 0.01) {
      glassFillPaint.shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Color.lerp(const Color(0x22FFFFFF), const Color(0xD8FFF5D6), glow)!,
          Color.lerp(const Color(0x18FFFFFF), const Color(0x99FFA726), glow)!,
          Color.lerp(const Color(0x08FFFFFF), const Color(0x44E65100), glow)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bulbRect);
    } else {
      glassFillPaint.color = const Color(0x1AFFFFFF); // Kaca transparan jernih
    }
    canvas.drawCircle(bulbCenter, bulbRadius, glassFillPaint);

    // Kontur kaca bohlam
    final glassOutlinePaint = Paint()
      ..color = glow > 0.01
          ? Color.lerp(const Color(0x55FFFFFF), const Color(0xEEFFF3D1), glow)!
          : const Color(0x44FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(bulbCenter, bulbRadius, glassOutlinePaint);

    // Specular Highlight pada kaca (pantulan lengkung di kiri atas bola kaca)
    final specularPath = Path()
      ..addArc(
        Rect.fromCircle(center: bulbCenter, radius: bulbRadius - 3.5),
        math.pi * 1.10,
        math.pi * 0.45,
      );
    final specularPaint = Paint()
      ..color = Colors.white.withValues(alpha: glow > 0.01 ? 0.80 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(specularPath, specularPaint);

    // Dudukan Kaca di Dalam Bohlam (Glass Stem Press)
    final stemPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(cx, rimY + 2.0),
      Offset(cx, bulbCenter.dy - 6.0),
      stemPaint,
    );

    // Kawat Penyangga Filamen (Lead-in Mount Wires)
    final leadWirePaint = Paint()
      ..color = glow > 0.01
          ? Color.lerp(const Color(0xFF6B7280), const Color(0xFFFFD54F), glow)!
          : const Color(0xFF5A5F63)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final leadWireLeft = Path()
      ..moveTo(cx - 4.0, bulbCenter.dy - 6.0)
      ..lineTo(cx - 6.5, bulbCenter.dy + 3.0);
    final leadWireRight = Path()
      ..moveTo(cx + 4.0, bulbCenter.dy - 6.0)
      ..lineTo(cx + 6.5, bulbCenter.dy + 3.0);

    canvas.drawPath(leadWireLeft, leadWirePaint);
    canvas.drawPath(leadWireRight, leadWirePaint);

    // Kumparan Filamen Tungsten (Blackbody Incandescent Coil)
    final filamentPath = Path()
      ..moveTo(cx - 6.5, bulbCenter.dy + 3.0)
      ..quadraticBezierTo(cx, bulbCenter.dy - 2.5, cx + 6.5, bulbCenter.dy + 3.0);

    if (glow > 0.01) {
      // Glow pijar filamen (Radiasi termal $T^4$ dari merah bara ke putih panas)
      final filamentGlowColor = glow < 0.35
          ? Color.lerp(const Color(0xFFFF3700), const Color(0xFFFF8500), glow / 0.35)!
          : Color.lerp(const Color(0xFFFF8500), const Color(0xFFFFFFFF), (glow - 0.35) / 0.65)!;

      final filamentHotPaint = Paint()
        ..color = filamentGlowColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(filamentPath, filamentHotPaint);

      // Inti putih panas murni di tengah filamen
      final filamentCorePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(filamentPath, filamentCorePaint);
    } else {
      // Filamen dingin metalik saat lampu padam
      final filamentColdPaint = Paint()
        ..color = const Color(0xFF4A4E52)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(filamentPath, filamentColdPaint);
    }

    // ── 7. Soket Tali Saklar (Pull-Switch Metal Socket) ───────────────────
    final socketRect = Rect.fromLTWH(cordAnchorX - 3.5, cordAnchorY, 7.0, 14.0);
    final socketPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFD6DBDE),
          Color(0xFF8B9399),
        ],
      ).createShader(socketRect);
    canvas.drawRRect(RRect.fromRectAndRadius(socketRect, const Radius.circular(1.5)), socketPaint);

    // ── 8. Tali Saklar Putih Satin (Braided Textile Pull-Cord) ────────────
    final cordStartX = cordAnchorX;
    final cordStartY = cordAnchorY + 14.0;
    final cordEndY = acornY;

    final cordColor = glow > 0.01
        ? Color.lerp(const Color(0xFFE5E7EB), const Color(0xFFFFF7DB), glow)!
        : const Color(0xFFE2E6E8);

    final cordPaint = Paint()
      ..color = cordColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cordStartX, cordStartY), Offset(cordStartX, cordEndY), cordPaint);

    // ── 9. Bandul Saklar Buah Ek (Turned Aluminium Acorn) ──────────────────
    // Bentuk tetesan buah ek khas pada referensi foto (Teardrop Acorn Weight)
    final acornRect = Rect.fromLTWH(cordStartX - 6.5, acornY, 13.0, 26.0);
    final acornPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          glow > 0.01 ? const Color(0xFFFFFDF5) : const Color(0xFFFFFFFF),
          glow > 0.01 ? const Color(0xFFF7EED2) : const Color(0xFFE2E6E9),
          glow > 0.01 ? const Color(0xFFDAC79E) : const Color(0xFFB5BAC0),
          glow > 0.01 ? const Color(0xFFA6906A) : const Color(0xFF858C92),
        ],
        stops: const [0.05, 0.35, 0.75, 1.0],
      ).createShader(acornRect);

    final acornPath = Path()
      // Kerah atas tempat masuknya tali
      ..moveTo(cordStartX - 3.0, acornY)
      ..lineTo(cordStartX + 3.0, acornY)
      ..lineTo(cordStartX + 3.5, acornY + 3.5)
      // Badan membulat anggun menyerupai buah ek / tetesan air terbalik
      ..cubicTo(
        cordStartX + 6.8, acornY + 7.0,
        cordStartX + 6.8, acornY + 17.0,
        cordStartX, acornY + 25.0,
      )
      ..cubicTo(
        cordStartX - 6.8, acornY + 17.0,
        cordStartX - 6.8, acornY + 7.0,
        cordStartX - 3.5, acornY + 3.5,
      )
      ..close();

    canvas.drawPath(acornPath, acornPaint);

    // Garis rim cincin atas acorn
    final acornRimPaint = Paint()
      ..color = const Color(0xFF6B7280).withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cordStartX - 3.0, acornY + 3.5),
      Offset(cordStartX + 3.0, acornY + 3.5),
      acornRimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PendantLampPainter oldDelegate) {
    return oldDelegate.cordPull != cordPull || oldDelegate.glow != glow;
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
