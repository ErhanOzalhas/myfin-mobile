import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color navy = Color(0xFF0F172A);
  static const Color navySoft = Color(0xFF1E293B);
  static const Color petrol = Color(0xFF075985);
  static const Color turquoise = Color(0xFF0891B2);
  static const Color primary = Color(0xFF087EA4);

  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE1E7EF);
  static const Color divider = Color(0xFFE8EDF3);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[navy, petrol, turquoise],
  );

  static const LinearGradient intelligenceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF5B21B6),
      Color(0xFF2563EB),
      Color(0xFF0891B2),
    ],
  );
}
