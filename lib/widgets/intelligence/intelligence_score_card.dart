import 'package:flutter/material.dart';

class IntelligenceScoreCard extends StatelessWidget {
  final int score;
  final String status;

  const IntelligenceScoreCard({
    super.key,
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: scoreColor),
              const SizedBox(width: 8),
              const Text(
                'AI Intelligence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score.clamp(0, 100) / 100,
              minHeight: 10,
              backgroundColor: scoreColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _HeroMetric(
                icon: Icons.shield_outlined,
                title: 'Risk',
                value: 'Low',
              ),
              _HeroMetric(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Diversify',
                value: 'Good',
              ),
              _HeroMetric(
                icon: Icons.trending_up_rounded,
                title: 'Trend',
                value: 'Stable',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}