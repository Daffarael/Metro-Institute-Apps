import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';
import 'text_effect.dart';

/// SplashScreen — Staged Shield Construction, Framer Motion TextEffect,
/// and Seamless Flight Transition to Top-Left Onboarding Header.
///
/// Urutan Animasi Sinematik:
/// 1. [0.00 – 0.05] Ruang tenang, perisai MULAI PERSIS DI TITIK TENGAH LAYAR (Dead Center).
/// 2. [0.05 – 0.25] Garis kontur perisai digambar sangat halus, lembut, dan melingkar.
/// 3. [0.25 – 0.36] Perisai terisi warna hijau zamrud solid (#063D2A) secara lembut mengalir.
/// 4. [0.36 – 0.52] 3 titik intan & 4 pilar kaligrafi "MI" terukir presisi menembus perisai ke warna putih.
/// 5. [0.52 – 0.60] Perisai meluncur mulus (easeInOutCubic) dari titik tengah ke posisi kiri lockup.
/// 6. [0.60 – 0.77] Teks "Metro" mekar dengan TextEffect (Luminous White Blur Preset).
/// 7. [0.75 – 0.95] Teks "Institute" mekar menyusul tepat di bawahnya.
/// 8. [0.95 – 1.00] Logo utuh di tengah layar dinikmati sejenak.
/// 9. [Flight Transition: ~950ms]:
///    - Background onboarding malam hari melarut lembut menggantikan latar putih.
///    - Perisai & teks "Metro Institute" terbang anggun dari titik tengah ke kiri atas.
///    - Ukuran perisai mengecil dari 82x104 ke 32x38.
///    - Warna perisai & teks berganti dari hijau zamrud (#063D2A) ke putih murni (Colors.white).
///    - Teks "Metro" & "Institute" menyatu dari 2 baris menjadi 1 baris horizontal.
///    - Elemen onboarding (headline & tombol) muncul menyambut pengguna saat logo mendarat di kiri atas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _flightController;
  late Animation<double> _flightAnimation;

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

  bool _hasTriggeredCarveHaptic = false;
  int _lastMetroChars = 0;
  int _lastInstituteChars = 0;

  // Warna Brand Utama Metro Institute
  static const Color _brandColor = Color(0xFF063D2A); // Hijau Zamrud Mewah & Kontras Tinggi

  double _measuredMetroWordWidth = 48.0; // Lebar perkiraan 'Metro ' pada 16.5px bold
  double _headerTextHeight = 21.0; // Tinggi teks header onboarding
  double _metroBigHeight = 35.7; // Tinggi 'Metro' 34px bold
  double _instituteBigHeight = 35.7; // Tinggi 'Institute' 34px bold

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _measureTextDimensions() {
    try {
      // 1. Lebar kata 'Metro ' di kiri atas onboarding (16.5px bold)
      final tpMetroSmall = TextPainter(
        text: TextSpan(
          text: 'Metro ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tpMetroSmall.width > 20) {
        _measuredMetroWordWidth = tpMetroSmall.width;
      }

      // 2. Tinggi teks header onboarding 'Metro Institute' (16.5px bold)
      final tpHeaderFull = TextPainter(
        text: TextSpan(
          text: 'Metro Institute',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tpHeaderFull.height > 10) {
        _headerTextHeight = tpHeaderFull.height;
      }

      // 3. Tinggi 'Metro' & 'Institute' saat 34px di tengah layar
      final tpMetroBig = TextPainter(
        text: TextSpan(
          text: 'Metro',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tpMetroBig.height > 20) {
        _metroBigHeight = tpMetroBig.height;
      }

      final tpInstBig = TextPainter(
        text: TextSpan(
          text: 'Institute',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tpInstBig.height > 20) {
        _instituteBigHeight = tpInstBig.height;
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startOrchestratedAnimation();
  }

  Future<void> _startOrchestratedAnimation() async {
    // 1. Tunggu frame pertama benar-benar selesai di-rasterisasi oleh GPU ke layar HP
    final rasterizedFuture = WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    if (rasterizedFuture != null) {
      await rasterizedFuture;
    }
    if (!mounted) return;



    // 3. Pre-cache gambar ditunda di background agar Frame 1 sama sekali tidak lag
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/images/onboarding_intro.jpg'), context);
      precacheImage(const AssetImage('assets/images/metro_shield.png'), context);
      _measureTextDimensions();
    });

    // 4. Mulai perakitan logo — garis bingkai dijamin 100% terlihat digambar dari 0%
    _runAnimationSequence();
  }

  void _initAnimations() {
    // 7600ms: Durasi sinematik logo assembly & typing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7600),
    );

    // 1. Tracing Outline: Garis perisai digambar melingkar sangat halus (300ms – 1900ms)
    _outlineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Perisai hijau terisi secara lembut (1900ms – 2740ms)
    _shieldFillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.36, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tiga titik intan terukir bertahap dengan mulus (2740ms – 3880ms)
    _dot1Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.43, curve: Curves.easeOutCubic),
      ),
    );
    _dot2Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.47, curve: Curves.easeOutCubic),
      ),
    );
    _dot3Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.44, 0.51, curve: Curves.easeOutCubic),
      ),
    );

    // Empat pilar kaligrafi terukir memotong perisai turun ke bawah (3190ms – 3950ms)
    _pillarsCarve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.52, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Perisai meluncur mulus dari titik tengah absolut ke posisi kiri (3950ms – 4560ms)
    _logoShiftProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.60, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Animasi "Metro" via Framer Motion TextEffect Blur Preset (4560ms – 5850ms)
    _metroTypeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.77, curve: Curves.linear),
      ),
    );

    // Animasi "Institute" via Framer Motion TextEffect Blur Preset di bawahnya (5700ms – 7220ms)
    _instituteTypeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 0.95, curve: Curves.linear),
      ),
    );

    // 6. Flight Controller: Gerakan logo & teks ke kiri atas & kemunculan mekar serempak saat mendarat (2200ms)
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _flightAnimation = CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic, // Gerakan fluida sinematik dengan akselerasi & deselerasi lembut
    );

    // Haptic feedback saat ukiran selesai & saat setiap huruf diketik
    _controller.addListener(() {
      if (_controller.value >= 0.52 && !_hasTriggeredCarveHaptic) {
        _hasTriggeredCarveHaptic = true;
        HapticFeedback.lightImpact();
      }

      // Haptic tactile click saat mengetik tiap karakter
      final currentMetroLen = (_metroTypeProgress.value * 5).floor().clamp(0, 5);
      if (currentMetroLen > _lastMetroChars) {
        _lastMetroChars = currentMetroLen;
        HapticFeedback.selectionClick();
      }

      final currentInstLen = (_instituteTypeProgress.value * 9).floor().clamp(0, 9);
      if (currentInstLen > _lastInstituteChars) {
        _lastInstituteChars = currentInstLen;
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _runAnimationSequence() async {
    try {
      // 1. Jalankan perakitan logo & teks mekar di tengah layar
      await _controller.forward();

      // Jeda sejenak untuk mengagumi logo utuh di tengah
      await Future.delayed(const Duration(milliseconds: 450));
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
        // 2. Jika belum login (Onboarding Flow):
        // Jalankan animasi pergerakan logo & teks ke kiri atas dan perubahan warna
        await _flightController.forward();
        if (!mounted) return;

        // 3. Mendarat sempurna ke halaman login / onboarding
        context.go(AppRoutes.login);
      }
    } catch (_) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _flightController]),
        builder: (context, _) {
          final flightT = _flightAnimation.value;

          // ── 1. Geometri Perisai (Proporsi 100% Terkunci 82:104, Anti-Penyek) ──
          const shieldWStart = 82.0;
          const shieldHStart = 104.0;
          const shieldAspect = shieldWStart / shieldHStart; // 0.78846

          const shieldHEnd = 38.0;
          const shieldWEnd = shieldHEnd * shieldAspect; // 29.96px (~30px, tepat di dalam container 32px)

          const gapStart = 18.0;
          const gapEnd = 10.0;

          // Lebar teks 2-baris di tengah layar
          const textWidthInst = 144.5;
          const shiftDistance = (gapStart + textWidthInst) / 2; // 81.25
          final initialShift = -shiftDistance * _logoShiftProgress.value;

          // Posisi Awal (Tengah Layar) & Posisi Akhir (Kiri Atas Onboarding)
          final startShieldLeft = (screenWidth / 2) - (shieldWStart / 2) + initialShift;
          final startShieldTop = (screenHeight - shieldHStart) / 2;

          const endShieldLeft = 25.0; // 24.0 padding + 1.0 margin
          final endShieldTop = topPadding + 20.0;

          // Interpolasi posisi & ukuran perisai (selalu proporsional, tanpa peregangan)
          final currentShieldLeft = ui.lerpDouble(startShieldLeft, endShieldLeft, flightT)!;
          final currentShieldTop = ui.lerpDouble(startShieldTop, endShieldTop, flightT)!;
          final currentShieldHeight = ui.lerpDouble(shieldHStart, shieldHEnd, flightT)!;
          final currentShieldWidth = currentShieldHeight * shieldAspect;

          // Warna: mengalir lembut dari hijau zamrud (#063D2A) ke putih murni (Colors.white)
          final currentBrandColor = Color.lerp(
            _brandColor,
            Colors.white,
            Curves.easeInOutCubic.transform(flightT),
          )!;

          // ── Posisi & Dimensi Teks (Bergerak Mulus Bersama Perisai) ─────────
          final currentFontSize = ui.lerpDouble(34.0, 16.5, flightT)!;
          final currentLetterSpacing = ui.lerpDouble(-0.8, -0.2, flightT)!;
          final currentLineHeight = ui.lerpDouble(1.05, 1.25, flightT);

          // Total tinggi teks 2-baris di tengah layar
          final totalBigTextHeight = _metroBigHeight + 2.0 + _instituteBigHeight;
          final textBlockOffset = (shieldHStart - totalBigTextHeight) / 2;

          // Posisi Awal Teks (Di tengah layar persis di samping perisai)
          final startTextLeft = startShieldLeft + shieldWStart + gapStart;
          final startMetroTop = startShieldTop + textBlockOffset;
          final startInstituteTop = startMetroTop + _metroBigHeight + 2.0;

          // Posisi Akhir Teks (Di kiri atas onboarding sejajar horizontal)
          const endTextLeft = 66.0; // 24.0 padding + 32.0 box + 10.0 gap
          final endTextTop = endShieldTop + (shieldHEnd - _headerTextHeight) / 2;
          final endInstituteLeft = endTextLeft + _measuredMetroWordWidth;

          // Interpolasi Posisi 'Metro' (Melayang naik ke kiri atas bersama perisai)
          final currentMetroLeft = ui.lerpDouble(startTextLeft, endTextLeft, flightT)!;
          final currentMetroTop = ui.lerpDouble(startMetroTop, endTextTop, flightT)!;

          // Interpolasi Posisi 'Institute' (Melayang dari bawah naik sejajar ke samping 'Metro')
          final currentInstituteLeft = ui.lerpDouble(startTextLeft, endInstituteLeft, flightT)!;
          final currentInstituteTop = ui.lerpDouble(startInstituteTop, endTextTop, flightT)!;

          // ── Transisi Munculnya Elemen Onboarding (Baru Muncul Penuh Tepat Saat Logo & Teks Menetap di Kiri Atas) ──
          // Background malam hari menggelap mengalir lembut seiring penerbangan (flightT 0.00 -> 1.00)
          final bgNightOpacity = Curves.easeInOutCubic.transform(flightT);

          // 1. Step Indicator di kanan atas: Mekar saat logo mendekati kiri atas (mencapai 100% di 1.0)
          final stepIndicatorT = ((flightT - 0.45) / 0.55).clamp(0.0, 1.0);
          final stepIndicatorOpacity = Curves.easeInQuad.transform(stepIndicatorT);

          // 2. Headline "Langkah Awal...": Tetap samar selama logo terbang, baru mekar penuh 100% saat logo menetap di kiri atas
          final headlineT = ((flightT - 0.45) / 0.55).clamp(0.0, 1.0);
          final headlineCurve = Curves.easeInQuad.transform(headlineT);
          final headlineOpacity = headlineCurve;
          final headlineOffsetY = (1.0 - headlineT) * 22.0;

          // 3. Subtitle "Pelajari keterampilan...": Mengikuti di bawah headline dan mekar penuh 100% saat logo menetap di kiri atas
          final subtitleT = ((flightT - 0.55) / 0.45).clamp(0.0, 1.0);
          final subtitleCurve = Curves.easeInQuad.transform(subtitleT);
          final subtitleOpacity = subtitleCurve;
          final subtitleOffsetY = (1.0 - subtitleT) * 18.0;

          // 4. Tombol Continue: Naik dari bawah dan mencapai 100% penuh tepat bersamaan dengan menetapnya logo di kiri atas
          final buttonT = ((flightT - 0.65) / 0.35).clamp(0.0, 1.0);
          final buttonCurve = Curves.easeInQuad.transform(buttonT);
          final buttonOpacity = buttonCurve;
          final buttonOffsetY = (1.0 - buttonT) * 22.0;
          final buttonScale = 0.95 + (0.05 * buttonCurve);

          return SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Latar Belakang Putih Awal ──
                Positioned.fill(
                  child: Container(color: Colors.white),
                ),

                // ── Latar Belakang Onboarding Malam Hari (Fade-in saat terbang) ──
                if (flightT > 0.0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: bgNightOpacity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/onboarding_intro.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(color: const Color(0xFF0D1117)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.60),
                                  Colors.black.withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.30, 0.60, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Elemen Pendukung Onboarding (Muncul sangat halus, bertahap & tanpa kejutan) ──
                if (flightT > 0.0)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row dengan placeholder transparan 38x32 untuk mengunci posisi Spacer & layout 100% identik dengan LoginScreen
                            Row(
                              children: [
                                const SizedBox(height: 38, width: 32),
                                const SizedBox(width: 10),
                                const Spacer(),
                                // Step Indicator di Kanan Atas (Mekar lembut seiring naiknya perisai)
                                Opacity(
                                  opacity: stepIndicatorOpacity,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        width: 8,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Headline Besar Onboarding (Mengapung lembut ke atas dengan fade-in yang menenangkan)
                            Opacity(
                              opacity: headlineOpacity,
                              child: Transform.translate(
                                offset: Offset(0, headlineOffsetY),
                                child: Text(
                                  'Langkah Awal Menuju\nPotensi Tanpa Batas.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle Onboarding: Muncul perlahan secara bertahap setelah headline
                            Opacity(
                              opacity: subtitleOpacity,
                              child: Transform.translate(
                                offset: Offset(0, subtitleOffsetY),
                                child: const Text(
                                  'Pelajari keterampilan teknologi masa kini, eksplorasi kurikulum berbasis industri, dan persiapkan karir digital impian Anda.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFFCBD5E1),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 52),

                            // Tombol Continue Onboarding: Muncul perlahan dari bawah setelah subtitle (100% identik dengan LoginScreen)
                            Opacity(
                              opacity: buttonOpacity,
                              child: Transform.translate(
                                offset: Offset(0, buttonOffsetY),
                                child: Transform.scale(
                                  scale: buttonScale,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                              color: Color(0xFF0D1117),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 17,
                                            color: Color(0xFF0D1117),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Ruang bawah 24px persis sama dengan LoginScreen agar tidak ada loncatan
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Kata 'Metro' (Mengetik di tengah lalu terbang anggun ke kiri atas) ──
                if (_logoShiftProgress.value > 0.01)
                  Positioned(
                    left: currentMetroLeft,
                    top: currentMetroTop,
                    child: TextEffect(
                      text: 'Metro',
                      preset: TextEffectPreset.blur,
                      blurColor: Colors.white,
                      per: TextEffectPer.char,
                      overlap: 0.65,
                      progress: _metroTypeProgress.value,
                      curve: Curves.easeOutCubic,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: currentFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: currentLetterSpacing,
                        color: currentBrandColor,
                        height: currentLineHeight,
                      ),
                    ),
                  ),

                // ── Kata 'Institute' (Mengetik di bawah 'Metro' lalu terbang naik sejajar ke samping 'Metro') ──
                if (_logoShiftProgress.value > 0.01)
                  Positioned(
                    left: currentInstituteLeft,
                    top: currentInstituteTop,
                    child: TextEffect(
                      text: 'Institute',
                      preset: TextEffectPreset.blur,
                      blurColor: Colors.white,
                      per: TextEffectPer.char,
                      overlap: 0.65,
                      progress: _instituteTypeProgress.value,
                      curve: Curves.easeOutCubic,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: currentFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: currentLetterSpacing,
                        color: currentBrandColor,
                        height: currentLineHeight,
                      ),
                    ),
                  ),

                // ── Perisai Vektor Orisinal (Bergerak & Berubah Warna Murni) ─
                // Rasio 82:104 terkunci 100%, kurva orisinal utuh, tidak pernah gepeng
                Positioned(
                  left: currentShieldLeft,
                  top: currentShieldTop,
                  width: currentShieldWidth,
                  height: currentShieldHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        if (flightT > 0.2)
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.12 * flightT),
                            blurRadius: 14,
                          ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: LogoCarvingPainter(
                        outlineProgress: _outlineProgress.value,
                        shieldFillOpacity: _shieldFillOpacity.value,
                        dot1Carve: _dot1Carve.value,
                        dot2Carve: _dot2Carve.value,
                        dot3Carve: _dot3Carve.value,
                        pillarsCarve: _pillarsCarve.value,
                        logoColor: currentBrandColor,
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

/// Custom Painter yang menggambar garis perisai dan ukiran cutouts
class LogoCarvingPainter extends CustomPainter {
  final double outlineProgress;
  final double shieldFillOpacity;
  final double dot1Carve;
  final double dot2Carve;
  final double dot3Carve;
  final double pillarsCarve;
  final Color logoColor;

  LogoCarvingPainter({
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
        ..strokeWidth = 2.8
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
  bool shouldRepaint(covariant LogoCarvingPainter oldDelegate) {
    return oldDelegate.outlineProgress != outlineProgress ||
        oldDelegate.shieldFillOpacity != shieldFillOpacity ||
        oldDelegate.dot1Carve != dot1Carve ||
        oldDelegate.dot2Carve != dot2Carve ||
        oldDelegate.dot3Carve != dot3Carve ||
        oldDelegate.pillarsCarve != pillarsCarve ||
        oldDelegate.logoColor != logoColor;
  }
}
