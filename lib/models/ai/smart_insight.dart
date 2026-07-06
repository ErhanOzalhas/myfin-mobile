import 'package:flutter/material.dart';

enum SmartInsightType {
  strength,
  warning,
  opportunity,
  trend,
}

enum SmartInsightPriority {
  low,
  medium,
  high,
}

class SmartInsight {
  const SmartInsight({
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
  });

  final SmartInsightType type;
  final SmartInsightPriority priority;

  final String title;
  final String message;

  IconData get icon {
    switch (type) {
      case SmartInsightType.strength:
        return Icons.verified_rounded;

      case SmartInsightType.warning:
        return Icons.warning_amber_rounded;

      case SmartInsightType.opportunity:
        return Icons.auto_awesome_rounded;

      case SmartInsightType.trend:
        return Icons.trending_up_rounded;
    }
  }

  Color get color {
    switch (type) {
      case SmartInsightType.strength:
        return const Color(0xFF16A34A);

      case SmartInsightType.warning:
        return const Color(0xFFF59E0B);

      case SmartInsightType.opportunity:
        return const Color(0xFF2563EB);

      case SmartInsightType.trend:
        return const Color(0xFF7C3AED);
    }
  }

  bool get isHighPriority =>
      priority == SmartInsightPriority.high;
}