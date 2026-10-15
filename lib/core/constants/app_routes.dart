/// AppRoutes — all named route paths used with go_router.
class AppRoutes {
  AppRoutes._();

  // ── Root ──────────────────────────────────────────────────────────────────
  static const String splash = '/';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login    = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static const String skillTest       = '/skill-test';
  static const String skillTestResult = '/skill-test/result';

  // ── Main Shell (Bottom Nav) ────────────────────────────────────────────────
  static const String basecamp     = '/basecamp';       // Tab 1
  static const String learn        = '/learn';          // Tab 2
  static const String challenge    = '/challenge';      // Tab 3
  static const String certificate  = '/certificate';    // Tab 4
  static const String profile      = '/profile';        // Tab 5

  // ── Sub-routes: Belajar ────────────────────────────────────────────────────
  static const String courseDetail  = '/learn/course/:id';
  static const String checkout      = '/learn/checkout/:id';
  static const String learningPlayer= '/learn/player/:sessionId';
  static const String wishlist      = '/learn/wishlist';
  static const String myCourses    = '/learn/my-courses';

  // ── Sub-routes: Challenge ─────────────────────────────────────────────────
  static const String challengeArena    = '/challenge/arena/:id';
  static const String leaderboard       = '/challenge/leaderboard';

  // ── Sub-routes: Certificate ────────────────────────────────────────────────
  static const String certificateDetail = '/certificate/:id';

  // ── Sub-routes: Profile ────────────────────────────────────────────────────
  static const String editProfile       = '/profile/edit';
  static const String changePassword    = '/profile/change-password';
  static const String xpActivity        = '/profile/xp-activity';
  static const String transactions      = '/profile/transactions';
  static const String notifPreference   = '/profile/notification-settings';

  // ── Notification ──────────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Rating ────────────────────────────────────────────────────────────────
  static const String ratingReview = '/rating/:courseId';
}
