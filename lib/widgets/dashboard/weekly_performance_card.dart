import 'dart:math' as math;

import 'package:flutter/material.dart';

class WeeklyPerformanceCard extends StatelessWidget {
  const WeeklyPerformanceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.changeText,
    required this.values,
    required this.isPositive,
    required this.color,
    required this.momentumLabel,
    required this.riskLabel,
    required this.riskColor,
    required this.dailyLabel,
    this.hasHistory = true,
  });

  final String title;
  final String subtitle;
  final String changeText;
  final List<double> values;
  final bool isPositive;
  final Color color;
  final String momentumLabel;
  final String riskLabel;
  final Color riskColor;
  final String dailyLabel;
  final bool hasHistory;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _TrendBadge(text: changeText, color: color),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 112,
            child: hasHistory
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) {
                      return CustomPaint(
                        painter: _WeeklyTrendPainter(
                          values: values,
                          color: color,
                          progress: progress,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Gerçek performans geçmişi oluşturuluyor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PulseStat(
                  label: 'Momentum',
                  value: momentumLabel,
                  color: color,
                ),
              ),
              Expanded(
                child: _PulseStat(
                  label: 'Risk',
                  value: riskLabel,
                  color: riskColor,
                ),
              ),
              Expanded(
                child: _PulseStat(
                  label: 'Günlük Trend',
                  value: dailyLabel,
                  color: const Color(0xFF008DB9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeeklyTrendPainter extends CustomPainter {
  const _WeeklyTrendPainter({
    required this.values,
    required this.color,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < .01 ? 1 : maxValue - minValue;

    Offset pointAt(int index) {
      final x = size.width * (index / (values.length - 1));
      final normalized = (values[index] - minValue) / range;
      final y =
          size.height - (normalized * size.height * .78) - (size.height * .11);
      return Offset(x, y);
    }

    final points = List<Offset>.generate(values.length, pointAt);
    final visibleSegments = ((points.length - 1) * progress).clamp(
      0,
      points.length - 1,
    );
    final fullSegments = visibleSegments.floor();
    final partial = visibleSegments - fullSegments;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i <= fullSegments; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (fullSegments < points.length - 1) {
      final a = points[fullSegments];
      final b = points[fullSegments + 1];
      path.lineTo(
        a.dx + (b.dx - a.dx) * partial,
        a.dy + (b.dy - a.dy) * partial,
      );
    }

    final areaPath = Path.from(path)
      ..lineTo(size.width * progress, size.height)
      ..lineTo(0, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: .18), color.withValues(alpha: .02)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < points.length; i++) {
      if (i / (points.length - 1) <= progress) {
        canvas.drawCircle(points[i], 4, dotPaint);
        canvas.drawCircle(
          points[i],
          7,
          Paint()..color = color.withValues(alpha: .12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress;
  }
}
