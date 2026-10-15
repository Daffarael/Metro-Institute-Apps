import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_constants.dart';

/// SplashScreen â€” Full-screen green branded splash.
/// Checks auth token â†’ routes to login or basecamp/skill-test.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    // TODO: Check token via AuthRepository â†’ route accordingly
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'MI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -1,
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // App name
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 6),

            Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 60),

            // Loading indicator
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                borderRadius: BorderRadius.circular(99),
                minHeight: 3,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}


