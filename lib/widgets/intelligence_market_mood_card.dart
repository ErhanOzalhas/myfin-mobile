import 'package:flutter/material.dart';

class IntelligenceMarketMoodCard extends StatelessWidget {
  final String mood;

  const IntelligenceMarketMoodCard({
    super.key,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (mood) {
      'Bullish' => Colors.green,
      'Bearish' => Colors.red,
      _ => Colors.orange,
    };

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Mood',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mood,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}