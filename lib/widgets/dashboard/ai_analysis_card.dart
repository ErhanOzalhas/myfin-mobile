import 'package:flutter/material.dart';

class AIAnalysisCard extends StatelessWidget {
  const AIAnalysisCard({
    super.key,
    required this.strengths,
    required this.warnings,
    required this.recommendations,
    required this.confidence,
    required this.resultSummary,
  });

  final List<String> strengths;
  final List<String> warnings;
  final List<String> recommendations;
  final int confidence;
  final String resultSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt_rounded,
                  color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text(
                'AI Analizi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resultSummary,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Güçlü Yönler',
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle,
            items: strengths,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Dikkat Edilecekler',
            color: const Color(0xFFF59E0B),
            icon: Icons.warning_amber_rounded,
            items: warnings,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'AI Önerileri',
            color: const Color(0xFF2563EB),
            icon: Icons.lightbulb_rounded,
            items: recommendations,
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI Güven Skoru',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Text(
                '$confidence%',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}