import 'package:flutter/material.dart';

import '../models/market_mood.dart';

class IntelligenceMarketMoodCard extends StatelessWidget {
  const IntelligenceMarketMoodCard({
    super.key,
    required this.result,
    this.isLoading = false,
  });

  final MarketMoodResult? result;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final data = result;
    final color = _colorFor(data?.regime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .14)),
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.public_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Mood',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Küresel ve yerel piyasa risk iştahı',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (data == null)
            const Text(
              'Piyasa göstergeleri yükleniyor...',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.score}',
                  style: TextStyle(
                    fontSize: 38,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3, left: 3),
                  child: Text(
                    '/100',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.score / 100,
                minHeight: 7,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Piyasa genişliği',
                    value: '%${(data.breadth * 100).round()}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Veri güveni',
                    value: '%${data.confidence}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Kapsam',
                    value: '${data.observationCount} gösterge',
                  ),
                ),
              ],
            ),
            if (data.drivers.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Öne çıkan göstergeler',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...data.drivers.map(
                (driver) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        driver.changePercent >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: driver.changePercent >= 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          driver.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${driver.changePercent >= 0 ? '+' : ''}${driver.changePercent.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 7),
                      _ImpactBadge(isPositive: driver.impact >= 0),
                    ],
                  ),
                ),
              ),
            ],
            if (data.rejectedCount > 0) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${data.rejectedIndicators.join(', ')} için anormal günlük veri algılandı; skora dahil edilmedi.',
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              data.confidence < 50
                  ? 'Veri kapsamı sınırlı; sonuç ön değerlendirme niteliğindedir.'
                  : 'BIST, küresel endeksler, kripto, altın ve kur sinyallerinden hesaplanır.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(MarketMoodRegime? regime) => switch (regime) {
    MarketMoodRegime.strongRiskOn => const Color(0xFF15803D),
    MarketMoodRegime.riskOn => const Color(0xFF16A34A),
    MarketMoodRegime.neutral => const Color(0xFFF59E0B),
    MarketMoodRegime.cautious => const Color(0xFFEA580C),
    MarketMoodRegime.riskOff => const Color(0xFFDC2626),
    MarketMoodRegime.insufficient || null => const Color(0xFF64748B),
  };
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.isPositive});

  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive
        ? const Color(0xFF15803D)
        : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPositive ? 'Mood +' : 'Mood −',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
