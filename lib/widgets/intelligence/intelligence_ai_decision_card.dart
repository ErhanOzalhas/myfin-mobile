import 'package:flutter/material.dart';

class IntelligenceAIDecisionCard extends StatelessWidget {
  final List<String> strengths;
  final List<String> warnings;
  final String riskLevel;
  final String investmentStyle;

  const IntelligenceAIDecisionCard({
    super.key,
    required this.strengths,
    required this.warnings,
    required this.riskLevel,
    required this.investmentStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'AI Decision',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (strengths.isNotEmpty) ...[
              const Text(
                '🟢 Güçlü Yönler',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ...strengths
                  .take(2)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "• $e",
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    ),
                  ),

              const SizedBox(height: 18),
            ],

            if (warnings.isNotEmpty) ...[
              const Text(
                '🟡 Dikkat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ...warnings
                  .take(2)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "• $e",
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    ),
                  ),

              const SizedBox(height: 18),
            ],

            const Divider(),

            const SizedBox(height: 12),

            Text(
              "Risk Seviyesi : $riskLevel",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            Text(
              "Yatırım Stili : $investmentStyle",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
