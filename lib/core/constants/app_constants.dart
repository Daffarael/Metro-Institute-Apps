/// AppConstants — all app-wide constants for Metro Institute Mobile App.
class AppConstants {
  AppConstants._();

  // ── API ─────────────────────────────────────────────────────────────────────
  static const String baseUrl     = 'http://10.0.2.2:5000/api/v1'; // Android emulator localhost
  static const String prodBaseUrl = 'https://api.metroinstitute.site/api/v1';
  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms

  // ── App Info ─────────────────────────────────────────────────────────────────
  static const String appName    = 'Metro Institute';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Grow Your Digital Future';

  // ── Storage Keys ─────────────────────────────────────────────────────────────
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
  static const String keyHasSkillTest = 'has_completed_skill_test';

  // ── Spacing ──────────────────────────────────────────────────────────────────
  static const double paddingHorizontal = 16.0;
  static const double paddingVertical   = 16.0;
  static const double gapItem           = 12.0;
  static const double gapSection        = 24.0;

  // ── Radius ───────────────────────────────────────────────────────────────────
  static const double radiusSmall  = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge  = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusFull   = 999.0; // Pill shape

  // ── Bottom Nav ────────────────────────────────────────────────────────────────
  static const double bottomNavHeight = 64.0;
  static const double appBarHeight    = 56.0;

  // ── Skill Test ────────────────────────────────────────────────────────────────
  static const int skillTestTotalQuestions = 12;
  static const int skillTestTimerSeconds   = 30;

  // ── Badge XP Thresholds ───────────────────────────────────────────────────────
  static const Map<String, int> badgeXpThresholds = {
    'METRO_ROOKIE':    500,
    'METRO_EXPLORER':  2000,
    'METRO_ACHIEVER':  5000,
    'METRO_EXPERT':    10000,
    'METRO_MASTER':    10000,
  };

  // ── Badge Labels ─────────────────────────────────────────────────────────────
  static const Map<String, String> badgeLabels = {
    'METRO_ROOKIE':    'Metro Rookie',
    'METRO_EXPLORER':  'Metro Explorer',
    'METRO_ACHIEVER':  'Metro Achiever',
    'METRO_EXPERT':    'Metro Expert',
    'METRO_MASTER':    'Metro Master',
  };
}
