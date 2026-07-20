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
    final normalizedScore = score.clamp(0, 100);

    final Color scoreColor = normalizedScore >= 71
        ? const Color(0xFF16A34A)
        : normalizedScore >= 41
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);

    final Color cardBaseColor = normalizedScore >= 71
        ? const Color(0xFFF6FCF8)
        : normalizedScore >= 41
        ? const Color(0xFFFFFBF3)
        : const Color(0xFFFFF7F7);

    final String aiMessage = normalizedScore >= 71
        ? 'AI bugün portföyünü güçlü buluyor.'
        : normalizedScore >= 41
        ? 'AI portföyünde iyileştirilebilecek alanlar görüyor.'
        : 'AI portföyünde dikkat edilmesi gereken riskler görüyor.';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBaseColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scoreColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scoreColor.withValues(alpha: 0.16),
                    scoreColor.withValues(alpha: 0.00),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withValues(alpha: 0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: scoreColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Portföy AI Skoru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF172033),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '$normalizedScore',
                    style: TextStyle(
                      fontSize: 50,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      color: scoreColor,
                      letterSpacing: -1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ScoreScale(score: normalizedScore, scoreColor: scoreColor),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Expanded(
                      child: _HeroMetric(
                        icon: Icons.shield_outlined,
                        title: 'Risk',
                        value: 'Düşük',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _HeroMetric(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'Çeşitlilik',
                        value: 'İyi',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _HeroMetric(
                        icon: Icons.trending_up_rounded,
                        title: 'Trend',
                        value: 'Stabil',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_alt_outlined,
                      size: 17,
                      color: scoreColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4B5565),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreScale extends StatelessWidget {
  final int score;
  final Color scoreColor;

  const _ScoreScale({required this.score, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    final progress = score / 100;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: scoreColor.withValues(alpha: 0.82),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0, 25, 50, 75, 100]
                    .map(
                      (value) => Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: value >= 75
                              ? scoreColor.withValues(alpha: 0.80)
                              : const Color(0xFF9AA3B2),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            SizedBox(
              width: 18,
              child: Center(
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const markerSize = 12.0;
                  final markerLeft =
                      (constraints.maxWidth - markerSize) *
                      progress.clamp(0.0, 1.0);

                  return SizedBox(
                    height: markerSize,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: scoreColor,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Positioned(
                          left: markerLeft,
                          child: Container(
                            width: markerSize,
                            height: markerSize,
                            decoration: BoxDecoration(
                              color: scoreColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: scoreColor.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF485466)),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7B8493),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
