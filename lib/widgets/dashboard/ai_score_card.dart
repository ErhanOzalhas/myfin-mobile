import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/ai_portfolio_score.dart';

class AIScoreCard extends StatelessWidget {
  const AIScoreCard({
    super.key,
    required this.score,
  });

  final AIPortfolioScore score;

  @override
  Widget build(BuildContext context) {
    final color = switch (score.risk) {
      RiskLevel.low => const Color(0xFF16A34A),
      RiskLevel.medium => const Color(0xFFF59E0B),
      RiskLevel.high => const Color(0xFFDC2626),
    };

    final progress = (score.overallScore / 100).clamp(0.0, 1.0);

    final strengths = <String>[];
    final warnings = <String>[];
    final recommendations = <String>[];

    if (score.diversification >= 70) {
      strengths.add('Çeşitlendirme güçlü.');
    } else {
      warnings.add('Çeşitlendirme artırılabilir.');
      recommendations.add('Farklı varlık türleri eklemek riski azaltabilir.');
    }

    if (score.momentum >= 75) {
      strengths.add('Büyüme potansiyeli güçlü.');
    }

    if (score.stability >= 70) {
      strengths.add('Stabilite iyi seviyede.');
    } else {
      warnings.add('Portföy oynaklığı yüksek olabilir.');
    }

    if (score.overallScore < 60) {
      recommendations.add('Daha dengeli dağılım için pozisyon ağırlıklarını gözden geçir.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'AI Portföy Skoru',
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                      letterSpacing: .1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  score.riskLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CompactInsightSummary(
            warnings: warnings,
            recommendations: recommendations,
          ),
          const SizedBox(height: 14),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  width: 186,
                  height: 186,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(
                      progress: value,
                      color: color,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(value * 100).round()}',
                            style: const TextStyle(
                              fontSize: 44,
                              height: .95,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI SCORE',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < (score.overallScore / 20).round()
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: const Color(0xFFFACC15),
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _MetricBar(
            title: 'Diversification',
            value: score.diversification,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 14),
          _MetricBar(
            title: 'Momentum',
            value: score.momentum,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 14),
          _MetricBar(
            title: 'Stability',
            value: score.stability,
            color: const Color(0xFF0F766E),
          ),
          const SizedBox(height: 16),
          Text(
            score.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInsightSummary extends StatelessWidget {
  const _CompactInsightSummary({
    required this.warnings,
    required this.recommendations,
  });

  final List<String> warnings;
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    final text = warnings.isNotEmpty
        ? warnings.first
        : recommendations.isNotEmpty
            ? recommendations.first
            : 'AI portföyünüzü dengeli buluyor.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology_rounded,
            color: Color(0xFF2563EB),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              '$value%',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: progress,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: .38),
          color,
          color.withValues(alpha: .72),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, glowPaint);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
