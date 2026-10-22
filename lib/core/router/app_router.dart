import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../presentation/features/auth/screens/login_screen.dart';
import '../../presentation/features/auth/screens/register_screen.dart';
import '../../presentation/features/skill_test/screens/skill_test_screen.dart';
import '../../presentation/features/basecamp/screens/basecamp_screen.dart';
import '../../presentation/features/learn/screens/learn_screen.dart';
import '../../presentation/features/learn/screens/course_detail_screen.dart';
import '../../presentation/features/learn/screens/video_player_screen.dart';
import '../../presentation/features/challenge/screens/challenge_screen.dart';
import '../../presentation/features/challenge/screens/challenge_arena_screen.dart';
import '../../presentation/features/certificate/screens/certificate_screen.dart';
import '../../presentation/features/profile/screens/profile_screen.dart';
import '../../presentation/features/profile/screens/edit_profile_screen.dart';
import '../../presentation/features/profile/screens/transactions_screen.dart';
import '../../presentation/features/profile/screens/xp_activity_screen.dart';
import '../../presentation/features/profile/screens/change_password_screen.dart';
import '../../presentation/features/notification/screens/notification_screen.dart';
import '../../presentation/features/leaderboard/screens/leaderboard_screen.dart';
import '../../presentation/features/webinar/screens/webinar_screen.dart';
import '../../presentation/features/wishlist/screens/wishlist_screen.dart';
import '../../presentation/features/my_courses/screens/my_courses_screen.dart';
import '../../presentation/common/widgets/main_shell.dart';
import '../../presentation/common/widgets/splash_screen.dart';

/// AppRouter — centralized routing using go_router with shell route for
/// persistent Bottom Navigation Bar across Tab 1-5.
class AppRouter {
  AppRouter._();

  static Page<dynamic> _buildTabPage({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
        ),
      ),

      // ── Onboarding / Skill Test ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.skillTest,
        builder: (context, state) => const SkillTestScreen(),
      ),

      // ── Main Shell: Bottom Navigation (Tab 1–5) ───────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.basecamp,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const BasecampScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.learn,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const LearnScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const NotificationScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.challenge,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const ChallengeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.certificate,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const CertificateScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _buildTabPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Full-screen Sub-routes ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.xpActivity,
        builder: (context, state) => const XpActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.challengeArena,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return ChallengeArenaScreen(
            challengeId: id,
            title: extra?['title'] ?? 'Arena Tantangan',
            timeLimitMinutes: extra?['timeLimitMinutes'] ?? 15,
            xpReward: extra?['xpReward'] ?? 100,
          );
        },
      ),

      // ── Leaderboard ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // ── Webinar ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.webinar,
        builder: (context, state) => const WebinarScreen(),
      ),

      // ── Wishlist ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),

      // ── My Courses ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.myCourses,
        builder: (context, state) => const MyCoursesScreen(),
      ),

      // ── Course & Bootcamp Detail ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.courseDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {'id': id};
          final isBootcamp = extra['isBootcamp'] == true;
          return CourseDetailScreen(
            item: extra,
            isBootcamp: isBootcamp,
          );
        },
      ),

      // ── Video Learning Player ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.learningPlayer,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VideoPlayerScreen(
            sessionId: sessionId,
            title: extra['title'] ?? 'Sesi Belajar',
            courseTitle: extra['courseTitle'] ?? 'Kelas Metro',
            videoUrl: extra['videoUrl'],
            courseId: extra['courseId'],
            isBootcamp: extra['isBootcamp'] == true,
            isAlreadyCompleted: extra['isCompleted'] == true,
          );
        },
      ),
    ],
  );
}
