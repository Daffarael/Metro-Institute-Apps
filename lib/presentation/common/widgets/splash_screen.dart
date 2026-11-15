import 'dart:math' as math;
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

  bool _hasTriggeredOutlineStartHaptic = false;
  bool _hasTriggeredDot1Haptic = false;
  bool _hasTriggeredDot2Haptic = false;
  bool _hasTriggeredDot3Haptic = false;
  bool _hasTriggeredCarveHaptic = false;
  int _lastMetroChars = 0;
  int _lastInstituteChars = 0;
  Future<bool>? _isLoggedInFuture;

  // Warna Brand Utama Metro Institute
  static const Color _brandColor = Color(0xFF063D2A); // Hijau Zamrud Mewah & Kontras Tinggi

  double _measuredMetroWordWidth = 52.5; // Lebar presisi 'Metro ' pada 16.5px w700
  double _headerTextHeight = 21.0; // Tinggi teks header onboarding
  double _metroBigHeight = 35.7; // Tinggi 'Metro' 34px bold
  double _instituteBigHeight = 35.7; // Tinggi 'Institute' 34px bold

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureTextDimensions();
  }

  void _measureTextDimensions() {
    try {
      // Ukur teks header penuh 'Metro Institute' (16.5px w700, height 1.15, matching LoginScreen)
      final tpHeaderFull = TextPainter(
        text: TextSpan(
          text: 'Metro Institute',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.15,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tpHeaderFull.height > 10) {
        _headerTextHeight = tpHeaderFull.height;
      }

      // Offset caret persis di huruf ke-6 ('I' pada 'Metro Institute')
      final caretOffset = tpHeaderFull.getOffsetForCaret(
        const TextPosition(offset: 6),
        Rect.zero,
      );
      if (caretOffset.dx > 20) {
        _measuredMetroWordWidth = caretOffset.dx;
      } else {
        final tpInstOnly = TextPainter(
          text: TextSpan(
            text: 'Institute',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final diff = tpHeaderFull.width - tpInstOnly.width;
        if (diff > 20) {
          _measuredMetroWordWidth = diff;
        } else {
          _measuredMetroWordWidth = 52.5;
        }
      }

      // 3. Tinggi 'Metro' & 'Institute' saat 34px di tengah layar
      final tpMetroBig = TextPainter(
        text: TextSpan(
          text: 'Metro',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w800,
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
            fontWeight: FontWeight.w800,
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
    // 0. Pre-fetch status auth di background agar tidak ada jeda disk I/O sebelum penerbangan logo
    try {
      _isLoggedInFuture = sl<AuthRepository>().isLoggedIn();
    } catch (_) {}

    // 1. Tunggu frame pertama benar-benar selesai di-rasterisasi oleh GPU ke layar HP
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    if (!mounted) return;

    // 2. Jeda settle 1100ms: Memastikan native splash window OS (Android 12+ SplashScreen / WindowManager)
    // sudah 100% lenyap dan user sudah memandang layar putih bersih sebelum garis outline pertama mulai digambar.
    // Menjamin pada 'flutter run' (cold boot) maupun hot restart, outline SELALU mulai digambar dari 0%.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    // 3. TUNDA pre-cache gambar onboarding sampai ukiran logo SELESAI (3800ms)
    // Hal ini KUNCI agar UI thread 100% bebas dari lag decode gambar saat garis outline digambar dari 0%!
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/images/onboarding_illu_1.png'), context);
      precacheImage(const AssetImage('assets/images/onboarding_illu_2.png'), context);
    });

    // 4. Mulai perakitan logo — garis bingkai dijamin 100% terlihat digambar dari 0%
    _runAnimationSequence();
  }

  void _initAnimations() {
    // 8200ms: Durasi sinematik logo assembly & typing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8200),
    );

    // 1. Tracing Outline: Garis perisai digambar melingkar sangat halus dari titik 0% (0.00 – 0.24)
    // Memberikan durasi tracing penuh ~1960ms tanpa hambatan apapun!
    _outlineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.24, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Perisai hijau terisi secara lembut (0.24 – 0.35)
    _shieldFillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tiga buah intan muncul TERLEBIH DAHULU di puncak (0.35 – 0.47)
    _dot1Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.41, curve: Curves.easeOutCubic),
      ),
    );
    _dot2Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.44, curve: Curves.easeOutCubic),
      ),
    );
    _dot3Carve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.41, 0.47, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Garis-garis "M" terukir perlahan (0.47 – 0.62)
    _pillarsCarve = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.47, 0.62, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Perisai utuh meluncur mulus dari titik tengah absolut ke posisi kiri (0.62 – 0.69)
    _logoShiftProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.69, curve: Curves.easeInOutCubic),
      ),
    );

    // 6. Animasi "Metro" via Framer Motion TextEffect Blur Preset (0.69 – 0.84)
    _metroTypeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.69, 0.84, curve: Curves.linear),
      ),
    );

    // Animasi "Institute" via Framer Motion TextEffect Blur Preset di bawahnya (0.83 – 0.98)
    _instituteTypeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.83, 0.98, curve: Curves.linear),
      ),
    );

    // 6. Flight Controller: Gerakan logo & teks ke kiri atas (2200ms dengan kurva easeInOut yang halus, konsisten & terlihat nyata di tiap frame)
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _flightAnimation = CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOut,
    );

    // Haptic feedback saat ukiran selesai & saat setiap huruf diketik
    _controller.addListener(() {
      if (_outlineProgress.value > 0.01 && !_hasTriggeredOutlineStartHaptic) {
        _hasTriggeredOutlineStartHaptic = true;
        HapticFeedback.selectionClick();
      }
      if (_dot1Carve.value > 0.5 && !_hasTriggeredDot1Haptic) {
        _hasTriggeredDot1Haptic = true;
        HapticFeedback.selectionClick();
      }
      if (_dot2Carve.value > 0.5 && !_hasTriggeredDot2Haptic) {
        _hasTriggeredDot2Haptic = true;
        HapticFeedback.selectionClick();
      }
      if (_dot3Carve.value > 0.5 && !_hasTriggeredDot3Haptic) {
        _hasTriggeredDot3Haptic = true;
        HapticFeedback.selectionClick();
      }
      if (_pillarsCarve.value >= 0.99 && !_hasTriggeredCarveHaptic) {
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

      // Jeda sejenak untuk mengagumi logo utuh di tengah layar
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final authRepo = sl<AuthRepository>();
      final loggedIn = await (_isLoggedInFuture ?? authRepo.isLoggedIn());
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
        // Jalankan animasi pergerakan logo & teks ke kiri atas secara fluid dan lembut
        await _flightController.forward();
        if (!mounted) return;

        // Jeda hening 60ms agar frame landing benar-benar dinikmati mata sebelum pergantian rute
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;

        // 3. Mendarat instan ke halaman login karena frame akhir SplashScreen sudah 100% identik
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
    final bottomInset = mediaQuery.padding.bottom;
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final bottomBarHeight = 84.0 + (bottomInset > 0 ? bottomInset : 14.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _flightController]),
        builder: (context, _) {
          final flightT = _flightAnimation.value;

          // ── 1. Geometri Perisai (82x104 di tengah -> 32x38 di kiri atas) ──
          const shieldWStart = 82.0;
          const shieldHStart = 104.0;
          const shieldHEnd = 38.0;
          const shieldWEnd = 32.0;
          const gapStart = 18.0;

          // Lebar teks 2-baris di tengah layar
          const textWidthInst = 144.5;
          const shiftDistance = (gapStart + textWidthInst) / 2; // 81.25
          final initialShift = -shiftDistance * _logoShiftProgress.value;

          // Posisi Awal (Tengah Layar)
          final startShieldLeft = (screenWidth / 2) - (shieldWStart / 2) + initialShift;
          final startShieldTop = (screenHeight - shieldHStart) / 2;

          // Posisi Akhir (Kiri Atas Onboarding - PERSIS LoginScreen horizontal: 24, vertical: 20)
          const endShieldBoxLeft = 24.0;
          final endShieldTop = topPadding + 20.0;

          // Interpolasi posisi box perisai
          final currentShieldBoxLeft = ui.lerpDouble(startShieldLeft, endShieldBoxLeft, flightT)!;
          final currentShieldTop = ui.lerpDouble(startShieldTop, endShieldTop, flightT)!;
          final shieldScaleX = ui.lerpDouble(1.0, shieldWEnd / shieldWStart, flightT)!;
          final shieldScaleY = ui.lerpDouble(1.0, shieldHEnd / shieldHStart, flightT)!;

          // Warna: mengalir lembut dari hijau zamrud (#063D2A) ke hijau (#143E26) untuk teks
          final currentTextColor = Color.lerp(
            _brandColor,
            const Color(0xFF143E26),
            flightT,
          )!;

          // Skala teks via GPU hardware scaling (34.0 -> 16.5)
          final textScale = ui.lerpDouble(1.0, 16.5 / 34.0, flightT)!;

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

          // Interpolasi Posisi 'Metro'
          final currentMetroLeft = ui.lerpDouble(startTextLeft, endTextLeft, flightT)!;
          final currentMetroTop = ui.lerpDouble(startMetroTop, endTextTop, flightT)!;

          // Interpolasi Posisi 'Institute'
          final currentInstituteLeft = ui.lerpDouble(startTextLeft, endInstituteLeft, flightT)!;
          final currentInstituteTop = ui.lerpDouble(startInstituteTop, endTextTop, flightT)!;

          // ── Transisi Elemen Onboarding (Muncul Bertahap & Elegan Saat Logo Bergerak) ──
          final bgOpacity = Curves.easeInOut.transform(flightT);

          // Step Indicator di kanan atas: Muncul perlahan saat logo mendekati atas (0.45 - 1.00)
          final stepIndicatorT = ((flightT - 0.45) / 0.55).clamp(0.0, 1.0);
          final stepIndicatorOpacity = Curves.easeInOut.transform(stepIndicatorT);

          // Ilustrasi Onboarding: Mulai mekar lembut hanya setelah logo sudah naik meninggalkan tengah layar (0.48 - 1.00)
          final illuT = ((flightT - 0.48) / 0.52).clamp(0.0, 1.0);
          final illuCurve = Curves.easeOutCubic.transform(illuT);
          final illuOpacity = illuCurve;
          final illuOffsetY = (1.0 - illuCurve) * 20.0;

          // Headline Besar: Muncul perlahan mengikuti ilustrasi (0.52 - 1.00)
          final headlineT = ((flightT - 0.52) / 0.48).clamp(0.0, 1.0);
          final headlineCurve = Curves.easeOutCubic.transform(headlineT);
          final headlineOpacity = headlineCurve;
          final headlineOffsetY = (1.0 - headlineCurve) * 20.0;

          // Subtitle: Mengalir perlahan setelah headline (0.58 - 1.00)
          final subtitleT = ((flightT - 0.58) / 0.42).clamp(0.0, 1.0);
          final subtitleCurve = Curves.easeOutCubic.transform(subtitleT);
          final subtitleOpacity = subtitleCurve;
          final subtitleOffsetY = (1.0 - subtitleCurve) * 16.0;

          // Tombol "Let's Go" Full Bottom: Naik perlahan dari bawah layar (0.65 - 1.00)
          final buttonT = ((flightT - 0.65) / 0.35).clamp(0.0, 1.0);
          final buttonCurve = Curves.easeOutCubic.transform(buttonT);
          final buttonOpacity = buttonCurve;
          final buttonOffsetY = (1.0 - buttonCurve) * 30.0;

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

                // ── Latar Belakang Onboarding Hangat (Fade-in mulus saat terbang) ──
                Positioned.fill(
                  child: Opacity(
                    opacity: bgOpacity,
                    child: Container(
                      color: const Color(0xFFFAF7F2),
                    ),
                  ),
                ),

                // ── Lingkaran Gradien Dekoratif (Kuning & Mint) ──
                Positioned(
                  top: -50,
                  right: -50,
                  child: Opacity(
                    opacity: bgOpacity,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFEF9C3).withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: -60,
                  child: Opacity(
                    opacity: bgOpacity,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F5E9).withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),

                // ── Konten Onboarding (Step Indicator, Ilustrasi, Headline, Subtitle) ──
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row (Placeholder transparan untuk mengunci Spacer & Step Indicator layout)
                          Row(
                            children: [
                              const SizedBox(width: 32, height: 38),
                              const SizedBox(width: 10),
                              const Spacer(),
                              // Step Indicator di Kanan Atas
                              Opacity(
                                opacity: stepIndicatorOpacity,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF143E26),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 7,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFACC15),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Spacer(flex: 2),

                          // Ilustrasi Onboarding HD (Tanpa bingkai kotak, menyatu ke latar)
                          Opacity(
                            opacity: illuOpacity,
                            child: Transform.translate(
                              offset: Offset(0, illuOffsetY),
                              child: Center(
                                child: SizedBox(
                                  height: screenHeight * 0.31,
                                  child: RepaintBoundary(
                                    child: Image.asset(
                                      'assets/images/onboarding_illu_1.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Headline Besar Onboarding
                          Opacity(
                            opacity: headlineOpacity,
                            child: Transform.translate(
                              offset: Offset(0, headlineOffsetY),
                              child: Text(
                                'Langkah Awal Menuju\nPotensi Tanpa Batas.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF143E26),
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle Onboarding
                          Opacity(
                            opacity: subtitleOpacity,
                            child: Transform.translate(
                              offset: Offset(0, subtitleOffsetY),
                              child: Text(
                                'Pelajari keterampilan teknologi masa kini, eksplorasi kurikulum berbasis industri, dan persiapkan karir digital impian Anda.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF5C5850),
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: bottomBarHeight + 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Tombol "Let's Go" Full Bottom (Naik lembut dari bawah layar) ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: buttonOpacity,
                    child: Transform.translate(
                      offset: Offset(0, buttonOffsetY),
                      child: FullBottomLetsGoButton(
                        onTap: () {
                          if (mounted) context.go(AppRoutes.login);
                        },
                      ),
                    ),
                  ),
                ),

                // ── Kata 'Metro' (GPU-accelerated Transform.scale, zero layout recomputation) ──
                if (_logoShiftProgress.value > 0.01)
                  Positioned(
                    left: currentMetroLeft,
                    top: currentMetroTop,
                    child: flightT > 0.0
                        ? Transform.scale(
                            scale: textScale,
                            alignment: Alignment.topLeft,
                            child: RepaintBoundary(
                              child: Text(
                                'Metro',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: currentTextColor,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          )
                        : (_metroTypeProgress.value < 1.0)
                            ? TextEffect(
                                text: 'Metro',
                                preset: TextEffectPreset.blur,
                                blurColor: Colors.white,
                                per: TextEffectPer.char,
                                overlap: 0.65,
                                progress: _metroTypeProgress.value,
                                curve: Curves.easeOutCubic,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: currentTextColor,
                                  height: 1.05,
                                ),
                              )
                            : Text(
                                'Metro',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: currentTextColor,
                                  height: 1.05,
                                ),
                              ),
                  ),

                // ── Kata 'Institute' (GPU-accelerated Transform.scale, zero layout recomputation) ──
                if (_logoShiftProgress.value > 0.01)
                  Positioned(
                    left: currentInstituteLeft,
                    top: currentInstituteTop,
                    child: flightT > 0.0
                        ? Transform.scale(
                            scale: textScale,
                            alignment: Alignment.topLeft,
                            child: RepaintBoundary(
                              child: Text(
                                'Institute',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: currentTextColor,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          )
                        : (_instituteTypeProgress.value < 1.0)
                            ? TextEffect(
                                text: 'Institute',
                                preset: TextEffectPreset.blur,
                                blurColor: Colors.white,
                                per: TextEffectPer.char,
                                overlap: 0.65,
                                progress: _instituteTypeProgress.value,
                                curve: Curves.easeOutCubic,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: currentTextColor,
                                  height: 1.05,
                                ),
                              )
                            : Text(
                                'Institute',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 34.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: currentTextColor,
                                  height: 1.05,
                                ),
                              ),
                  ),

                // ── Perisai Vektor Orisinal (GPU-accelerated Transform.scale, fixed bounds) ─
                Positioned(
                  left: currentShieldBoxLeft,
                  top: currentShieldTop,
                  child: Transform.scale(
                    scaleX: shieldScaleX,
                    scaleY: shieldScaleY,
                    alignment: Alignment.topLeft,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: shieldWStart,
                        height: shieldHStart,
                        child: CustomPaint(
                          isComplex: true,
                          willChange: flightT == 0.0,
                          painter: LogoCarvingPainter(
                            outlineProgress: _outlineProgress.value,
                            shieldFillOpacity: _shieldFillOpacity.value,
                            dot1Carve: _dot1Carve.value,
                            dot2Carve: _dot2Carve.value,
                            dot3Carve: _dot3Carve.value,
                            pillarsCarve: _pillarsCarve.value,
                            logoColor: const Color(0xFF063D2A),
                          ),
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

  // Vektor 3 Intan (Diamonds) Presisi 100% dari Logo Asli Metro Institute
  static const List<Offset> _dot1 = [
    Offset(0.3203, 0.1435),
    Offset(0.2687, 0.1842),
    Offset(0.3203, 0.2250),
    Offset(0.3701, 0.1857),
  ];
  static const List<Offset> _dot2 = [
    Offset(0.4288, 0.1449),
    Offset(0.3754, 0.1842),
    Offset(0.4270, 0.2250),
    Offset(0.4786, 0.1842),
  ];
  static const List<Offset> _dot3 = [
    Offset(0.5356, 0.1435),
    Offset(0.4840, 0.1842),
    Offset(0.5356, 0.2250),
    Offset(0.5872, 0.1842),
  ];

  // Vektor 4 Garis Pilar Kaligrafi "M" Presisi 100% dari Logo Asli Metro Institute
  // Pillar 1: Garis pilar kiri pertama (mengikuti lekukan perisai luar kiri)
  static const List<Offset> _pillar1 = [
    Offset(0.3132, 0.2588),
    Offset(0.2100, 0.2588),
    Offset(0.2028, 0.2911),
    Offset(0.1993, 0.3221),
    Offset(0.1655, 0.5035),
    Offset(0.1655, 0.5471),
    Offset(0.1708, 0.5752),
    Offset(0.1868, 0.6160),
    Offset(0.2100, 0.6512),
    Offset(0.2367, 0.6779),
    Offset(0.2580, 0.5710),
    Offset(0.2580, 0.5584),
  ];

  // Pillar 2: Garis pilar kedua (sejajar miring, melengkung di dasar perisai)
  static const List<Offset> _pillar2 = [
    Offset(0.4786, 0.2588),
    Offset(0.3754, 0.2588),
    Offset(0.2954, 0.7145),
    Offset(0.3381, 0.7300),
    Offset(0.3808, 0.7384),
    Offset(0.3932, 0.7384),
    Offset(0.3986, 0.7159),
    Offset(0.4004, 0.6934),
    Offset(0.4217, 0.5865),
    Offset(0.4235, 0.5640),
    Offset(0.4306, 0.5359),
    Offset(0.4306, 0.5246),
  ];

  // Pillar 3: Garis pilar ketiga (menembus paling dalam ke ujung runcing perisai)
  static const List<Offset> _pillar3 = [
    Offset(0.6459, 0.2588),
    Offset(0.5427, 0.2588),
    Offset(0.5302, 0.3347),
    Offset(0.5249, 0.3516),
    Offset(0.5231, 0.3741),
    Offset(0.5160, 0.4023),
    Offset(0.4982, 0.5148),
    Offset(0.4929, 0.5316),
    Offset(0.4929, 0.5429),
    Offset(0.4502, 0.7750),
    Offset(0.4502, 0.7989),
    Offset(0.4626, 0.8256),
    Offset(0.4840, 0.8439),
    Offset(0.5036, 0.8523),
    Offset(0.5214, 0.8565),
    Offset(0.5391, 0.8565),
    Offset(0.5409, 0.8383),
    Offset(0.5480, 0.8115),
    Offset(0.5498, 0.7890),
    Offset(0.5641, 0.7201),
    Offset(0.5658, 0.6990),
    Offset(0.5712, 0.6821),
    Offset(0.5730, 0.6596),
    Offset(0.5801, 0.6315),
    Offset(0.5890, 0.5696),
    Offset(0.5943, 0.5527),
    Offset(0.5961, 0.5302),
    Offset(0.6032, 0.5021),
    Offset(0.6032, 0.4909),
  ];

  // Pillar 4: Garis pilar kanan keempat (memanjang anggun dari puncak atas ke kanan)
  static const List<Offset> _rightSpire = [
    Offset(0.8327, 0.1406),
    Offset(0.7295, 0.1421),
    Offset(0.7189, 0.2124),
    Offset(0.6975, 0.3193),
    Offset(0.6957, 0.3418),
    Offset(0.6886, 0.3685),
    Offset(0.6868, 0.3910),
    Offset(0.6726, 0.4599),
    Offset(0.6726, 0.4712),
    Offset(0.6566, 0.5485),
    Offset(0.6477, 0.6104),
    Offset(0.6335, 0.6779),
    Offset(0.6477, 0.6695),
    Offset(0.6779, 0.6456),
    Offset(0.7100, 0.6132),
    Offset(0.7438, 0.5654),
    Offset(0.7598, 0.5316),
    Offset(0.7687, 0.5049),
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

    // Bypass operasi boolean Path.combine yang berat jika ukiran pilar sudah selesai 100%
    if (progress >= 1.0) {
      return path;
    }

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

/// Exact vector shield icon matching the loading page (100% vector carved)
class MetroShieldIcon extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const MetroShieldIcon({
    super.key,
    this.width = 32,
    this.height = 38,
    this.color = const Color(0xFF063D2A),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: LogoCarvingPainter(
          outlineProgress: 1.0,
          shieldFillOpacity: 1.0,
          dot1Carve: 1.0,
          dot2Carve: 1.0,
          dot3Carve: 1.0,
          pillarsCarve: 1.0,
          logoColor: color,
        ),
      ),
    );
  }
}

/// Full-width bottom "Let's Go" button anchored flush to the bottom of the screen,
/// matching the user's reference design 100% in signature Metro Institute Green.
class FullBottomLetsGoButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final Color backgroundColor;
  final bool pointingUp;

  const FullBottomLetsGoButton({
    super.key,
    required this.onTap,
    this.text = "Let's Go",
    this.backgroundColor = const Color(0xFF143E26),
    this.pointingUp = false,
  });

  @override
  State<FullBottomLetsGoButton> createState() => _FullBottomLetsGoButtonState();
}

class _FullBottomLetsGoButtonState extends State<FullBottomLetsGoButton> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    // Continuous sequential wave animation for blinking chevrons
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  /// Computes a smooth travelling pulse opacity [0.25 .. 1.0] for chevron index
  double _getChevronOpacity(double t, int index) {
    final start = index * 0.16;
    final end = start + 0.38;
    if (t >= start && t <= end) {
      final p = (t - start) / (end - start);
      final sine = math.sin(p * math.pi);
      return 0.25 + 0.75 * sine;
    }
    return 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = 84.0 + (bottomInset > 0 ? bottomInset : 14.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) => _animController.reverse(),
      onTapCancel: () => _animController.reverse(),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
        child: SizedBox(
          width: double.infinity,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Metro Green contoured base sheet with top arch and center notch
              Positioned.fill(
                child: CustomPaint(
                  painter: _FullBottomLetsGoPainter(color: widget.backgroundColor),
                ),
              ),

              // Foreground Row: "Let's Go" and Blinking Chevrons >>>
              Positioned(
                left: 0,
                right: 0,
                top: 22,
                bottom: bottomInset > 0 ? bottomInset : 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Text with Comic Neue font (matching reference style & slightly larger)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.text,
                            maxLines: 1,
                            style: GoogleFonts.comicNeue(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ).copyWith(
                              fontFamilyFallback: const ['Comic Sans MS', 'Chalkboard SE', 'sans-serif'],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right: Animated Chevrons (Horizontal >>> or Upward ^^^)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final t = _pulseController.value;
                          if (widget.pointingUp) {
                            return SizedBox(
                              width: 20,
                              height: 30,
                              child: CustomPaint(
                                painter: _UpwardChevronsPainter(
                                  t: t,
                                  getOpacity: _getChevronOpacity,
                                ),
                              ),
                            );
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: Colors.white.withValues(
                                  alpha: _getChevronOpacity(t, 0),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: Colors.white.withValues(
                                  alpha: _getChevronOpacity(t, 1),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: Colors.white.withValues(
                                  alpha: _getChevronOpacity(t, 2),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for sleek vertical chevrons pointing upwards,
/// with sequential light wave gliding from bottom to top.
class _UpwardChevronsPainter extends CustomPainter {
  final double t;
  final double Function(double t, int index) getOpacity;

  const _UpwardChevronsPainter({required this.t, required this.getOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // 3 chevrons vertically spaced
    // index 0: bottom, index 1: mid, index 2: top
    // Sequential pulse flows from bottom to top
    final yOffsets = [
      size.height * 0.80, // bottom (index 0)
      size.height * 0.50, // mid (index 1)
      size.height * 0.20, // top (index 2)
    ];

    const strokeWidth = 2.4;
    const chevronHalfWidth = 7.0;
    const chevronHeight = 5.0;

    for (int i = 0; i < 3; i++) {
      final alpha = getOpacity(t, i);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final yc = yOffsets[i];
      final path = Path()
        ..moveTo(cx - chevronHalfWidth, yc + chevronHeight / 2)
        ..lineTo(cx, yc - chevronHeight / 2)
        ..lineTo(cx + chevronHalfWidth, yc + chevronHeight / 2);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UpwardChevronsPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _FullBottomLetsGoPainter extends CustomPainter {
  final Color color;

  const _FullBottomLetsGoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final centerX = w / 2;
    const notchHalfW = 26.0;
    const notchDepth = 12.0;

    final path = Path();

    // 1. Bottom-left to bottom-right (flush against bottom screen edge)
    path.moveTo(0, h);
    path.lineTo(w, h);

    // 2. Right edge going up to where top corner starts
    path.lineTo(w, 42);

    // 3. Top-right corner rounded transition
    path.quadraticBezierTo(
      w, 24,
      w - 20, 20,
    );

    // 4. Right top arch: slopes gently up to notch right crest
    path.quadraticBezierTo(
      w * 0.74, 1.5,
      centerX + notchHalfW, 0,
    );

    // 5. Center notch: smooth concave circular dip
    path.cubicTo(
      centerX + notchHalfW * 0.55, 0,
      centerX + notchHalfW * 0.40, notchDepth,
      centerX, notchDepth,
    );
    path.cubicTo(
      centerX - notchHalfW * 0.40, notchDepth,
      centerX - notchHalfW * 0.55, 0,
      centerX - notchHalfW, 0,
    );

    // 6. Left top arch: slopes gently down from notch left crest to left corner
    path.quadraticBezierTo(
      w * 0.26, 1.5,
      20, 20,
    );

    // 7. Top-left corner rounded transition
    path.quadraticBezierTo(
      0, 24,
      0, 42,
    );

    // 8. Left edge down to (0, h)
    path.lineTo(0, h);
    path.close();

    // Soft upward drop shadow in Metro Green tone
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(path.shift(const Offset(0, -3)), shadowPaint);

    // Solid Metro Green fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _FullBottomLetsGoPainter oldDelegate) => oldDelegate.color != color;
}
