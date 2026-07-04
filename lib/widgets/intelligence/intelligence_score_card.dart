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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: scoreColor.withValues(alpha: 0.12),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PortfolioAnalyzer gerçek portföy verisine göre hesaplandı.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}