import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const TextStyle appTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle heroValue = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.08,
    letterSpacing: -0.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textMuted,
  );

  static const TextStyle small = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.textMuted,
  );
}
