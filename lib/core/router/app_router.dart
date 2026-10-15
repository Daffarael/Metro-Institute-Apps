import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../presentation/features/auth/screens/login_screen.dart';
import '../../presentation/features/auth/screens/register_screen.dart';
import '../../presentation/features/skill_test/screens/skill_test_screen.dart';
import '../../presentation/features/basecamp/screens/basecamp_screen.dart';
import '../../presentation/features/learn/screens/learn_screen.dart';
import '../../presentation/features/challenge/screens/challenge_screen.dart';
import '../../presentation/features/certificate/screens/certificate_screen.dart';
import '../../presentation/features/profile/screens/profile_screen.dart';
import '../../presentation/features/notification/screens/notification_screen.dart';
import '../../presentation/common/widgets/main_shell.dart';
import '../../presentation/common/widgets/splash_screen.dart';

/// AppRouter â€” centralized routing using go_router with shell route for
/// persistent Bottom Navigation Bar across Tab 1-5.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // â”€â”€ Splash â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // â”€â”€ Onboarding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: AppRoutes.skillTest,
        builder: (context, state) => const SkillTestScreen(),
      ),

      // â”€â”€ Main Shell: Bottom Navigation (Tab 1â€“5) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.basecamp,
            builder: (context, state) => const BasecampScreen(),
          ),
          GoRoute(
            path: AppRoutes.learn,
            builder: (context, state) => const LearnScreen(),
          ),
          GoRoute(
            path: AppRoutes.challenge,
            builder: (context, state) => const ChallengeScreen(),
          ),
          GoRoute(
            path: AppRoutes.certificate,
            builder: (context, state) => const CertificateScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // â”€â”€ Notification (full screen, outside shell) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}

