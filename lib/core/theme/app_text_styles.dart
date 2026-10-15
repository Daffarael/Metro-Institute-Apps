import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTextStyles — named text styles for quick access in widgets.
/// Mirrors the typography scale in UIUXDesignConcept.md.
class AppTextStyles {
  AppTextStyles._();

  // Headings
  static const TextStyle headingXL = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.25);
  static const TextStyle headingL  = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.3);
  static const TextStyle headingM  = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);

  // Body
  static const TextStyle bodyRegular = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.625);
  static const TextStyle bodyMedium  = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5);
  static const TextStyle bodySmall   = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);

  // Labels
  static const TextStyle labelL = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const TextStyle labelM = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const TextStyle labelS = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.06);

  // Caption
  static const TextStyle caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static const TextStyle captionM = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary);

  // Chip / Badge
  static const TextStyle chip = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5);
}
