import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/repositories/auth_repository.dart';

/// SplashScreen — Elegant branded launch animation inspired by Opal (Mobbin).
/// Sequence:
/// 1. Only the authentic Metro Institute shield emblem appears in the dead-center, large and crisp.
/// 2. Then, the shield shifts smoothly to the left as "Metro \n Institute" expands horizontally.
/// 3. The full lockup stays centered, followed by seamless route navigation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;

  // Phase 1: Logo entrance (Scale & Fade)
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Phase 2: Logo shift & Text reveal (Depth Zoom: Belakang ke Depan + Blur to Clear)
  late Animation<double> _logoShift;
  late Animation<double> _textOpacity;
  late Animation<double> _textBlur;
  late Animation<double> _textScale;

  // Phase 3: Exit animation (Smooth dissolve & gentle scale before navigating to next screen)
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runAnimationSequence();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 0.0 – 0.38 (0 – 900ms): Logo appears dead-center alone, large & prominent
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.easeIn),
      ),
    );

    // 0.40 – 0.80 (960 – 1920ms): Logo shifts gracefully left
    // Shift distance is ~76px so Logo starts dead center and ends left-aligned with text
    _logoShift = Tween<double>(begin: 76.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeInOutCubic),
      ),
    );

    // Text fades in smoothly (0.0 -> 1.0)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.76, curve: Curves.easeOut),
      ),
    );

    // Soft Gaussian blur resolves from 20px down to 0px (asalnya blur, lama-lama jelas)
    _textBlur = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Depth zoom: Muncul dari belakang ke depan (0.68 -> 1.0) tanpa geser dari kanan
    _textScale = Tween<double>(begin: 0.68, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 3 Exit Controller (Dissolves gracefully into next screen)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeInCubic),
      ),
    );
  }

  Future<void> _runAnimationSequence() async {
    try {
      // 1. Play entrance and depth reveal
      await _controller.forward();

      // 2. Brief appreciative hold on the full lockup
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      // 3. Smooth Exit Animation: dissolves out gracefully rather than abruptly cutting
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
      backgroundColor: const Color(0xFF0F1216), // Premium deep dark background
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
                  // Shield Logo Emblem (Large & Crisp)
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        height: 96,
                        width: 78,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.16),
                              blurRadius: 36,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/metro_shield.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/logo_clean.png',
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Brand Text ("Metro \n Institute") — Depth Zoom (dari belakang ke depan, blur ke jelas)
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.scale(
                      scale: _textScale.value,
                      alignment: Alignment.centerLeft,
                      child: _textBlur.value > 0.05
                          ? ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: _textBlur.value,
                                sigmaY: _textBlur.value,
                              ),
                              child: _buildBrandText(),
                            )
                          : _buildBrandText(),
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

  Widget _buildBrandText() {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Metro',
            style: GoogleFonts.plusJakartaSans(
              textStyle: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: Colors.white,
                height: 1.06,
              ),
            ),
          ),
          Text(
            'Institute',
            style: GoogleFonts.plusJakartaSans(
              textStyle: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: Colors.white,
                height: 1.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
