import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppSpacing — spacing and radius tokens
class AppSpacing {
  AppSpacing._();

  static const double xxs  = 4.0;
  static const double xs   = 8.0;
  static const double sm   = 12.0;
  static const double md   = 16.0;
  static const double lg   = 20.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;

  // Radius
  static const double radiusXS  = 4.0;
  static const double radiusSM  = 6.0;
  static const double radiusMD  = 8.0;
  static const double radiusLG  = 12.0;
  static const double radiusXL  = 16.0;
  static const double radiusFull = 999.0;

  // Common padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionGap  = EdgeInsets.only(bottom: xl);
}

/// AppDecorations — commonly reused BoxDecoration presets
class AppDecorations {
  AppDecorations._();

  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
    border: Border.all(color: AppColors.border),
  );

  static BoxDecoration get primaryCard => BoxDecoration(
    color: AppColors.primaryXLight,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
    border: Border.all(color: AppColors.primaryLight),
  );

  static BoxDecoration get accentCard => BoxDecoration(
    color: AppColors.accent,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
  );

  static BoxDecoration get pill => BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
  );
}
