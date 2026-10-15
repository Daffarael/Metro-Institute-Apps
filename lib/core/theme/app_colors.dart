import 'package:flutter/material.dart';

/// AppColors — single source of truth for all colors in Metro Institute Mobile.
/// Synchronized 1:1 with website's variables.css design tokens.
class AppColors {
  AppColors._();

  // ── Brand / Primary ────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF018556); // --color-primary
  static const Color primaryDark   = Color(0xFF016b44); // --color-primary-dark
  static const Color primaryLight  = Color(0xFFe6f4ef); // --color-primary-light
  static const Color primaryXLight = Color(0xFFf0faf6); // --color-primary-xlight

  // ── Accent / Yellow ────────────────────────────────────────────────────────
  static const Color accent      = Color(0xFFFAE653); // --color-accent
  static const Color accentDark  = Color(0xFFe6d13a); // --color-accent-dark
  static const Color accentLight = Color(0xFFfef9d5); // --color-accent-light

  // ── Neutral / Background ───────────────────────────────────────────────────
  static const Color background      = Color(0xFFF8F9FA); // --color-bg
  static const Color backgroundSubtle = Color(0xFFF1F3F5); // --color-border-subtle
  static const Color surface         = Color(0xFFFFFFFF); // --color-surface
  static const Color border          = Color(0xFFE9ECEF); // --color-border

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D1117); // --color-text-primary
  static const Color textSecondary = Color(0xFF6C757D); // --color-text-secondary
  static const Color textTertiary  = Color(0xFFADB5BD); // --color-text-tertiary
  static const Color textDisabled  = Color(0xFFCED4DA); // --color-text-disabled
  static const Color textInverse   = Color(0xFFFFFFFF); // --color-text-inverse

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success   = Color(0xFF018556); // --color-success
  static const Color successBg = Color(0xFFe6f4ef); // --color-success-bg
  static const Color warning   = Color(0xFFD97706); // --color-warning
  static const Color warningBg = Color(0xFFFEF3C7); // --color-warning-bg
  static const Color error     = Color(0xFFDC2626); // --color-error
  static const Color errorBg   = Color(0xFFFEF2F2); // --color-error-bg
  static const Color info      = Color(0xFF2563EB); // --color-info
  static const Color infoBg    = Color(0xFFEFF6FF); // --color-info-bg

  // ── Gamification / XP ──────────────────────────────────────────────────────
  static const Color xp       = Color(0xFFF59E0B); // --color-xp (gold stars, XP)
  static const Color xpBg     = Color(0xFFFEF3C7); // --color-xp-bg
  static const Color streak   = Color(0xFFEF4444); // --color-streak (fire 🔥)
  static const Color streakBg = Color(0xFFFEF2F2); // --color-streak-bg

  // ── Badge Levels ───────────────────────────────────────────────────────────
  static const Color badgeRookie   = Color(0xFF9CA3AF); // Abu
  static const Color badgeExplorer = Color(0xFF3B82F6); // Biru
  static const Color badgeAchiever = Color(0xFF8B5CF6); // Ungu
  static const Color badgeExpert   = Color(0xFFF59E0B); // Emas
  static const Color badgeMaster   = Color(0xFF018556); // Hijau Primary

  // ── Overlay ────────────────────────────────────────────────────────────────
  static const Color overlay = Color(0x80000000); // 50% black

  // ── Helper ─────────────────────────────────────────────────────────────────
  static Color badgeColor(String badgeLevel) {
    switch (badgeLevel.toUpperCase()) {
      case 'METRO_ROOKIE':    return badgeRookie;
      case 'METRO_EXPLORER':  return badgeExplorer;
      case 'METRO_ACHIEVER':  return badgeAchiever;
      case 'METRO_EXPERT':    return badgeExpert;
      case 'METRO_MASTER':    return badgeMaster;
      default:                return badgeRookie;
    }
  }
}
