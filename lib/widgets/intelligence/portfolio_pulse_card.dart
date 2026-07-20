import 'package:flutter/material.dart';

import '../../models/ai/portfolio_intelligence.dart';

class PortfolioPulseCard extends StatelessWidget {
  const PortfolioPulseCard({
    super.key,
    required this.portfolio,
  });

  final PortfolioIntelligence portfolio;

  @override
  Widget build(BuildContext context) {
    final profitColor =
        portfolio.isProfit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

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
              Icon(Icons.favorite_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Text(
                'Portföy Nabzı',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PulseMetric(
            label: 'Toplam Değer',
            value: _formatCurrency(portfolio.totalValue),
            helper: '${portfolio.assetCount} varlık • ${portfolio.typeCount} tür',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 12),
          _PulseMetric(
            label: 'Kâr / Zarar',
            value: _formatCurrency(portfolio.profitLoss),
            helper:
                '${portfolio.profitLossPercent >= 0 ? '+' : ''}${portfolio.profitLossPercent.toStringAsFixed(1)}%',
            color: profitColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactPulseBox(
                  label: 'Baskın Varlık',
                  value: portfolio.dominantAssetSymbol.isEmpty
                      ? '-'
                      : portfolio.dominantAssetSymbol,
                  helper: '${(portfolio.dominantAssetWeight * 100).round()}%',
                  color: portfolio.hasDominantAsset
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactPulseBox(
                  label: 'Baskın Tür',
                  value: portfolio.dominantType.isEmpty
                      ? '-'
                      : _typeLabel(portfolio.dominantType),
                  helper: '${(portfolio.dominantTypeWeight * 100).round()}%',
                  color: portfolio.hasDominantType
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(double value) {
    final sign = value < 0 ? '-' : '';
    final absValue = value.abs();

    if (absValue >= 1000000) {
      return '$sign₺${(absValue / 1000000).toStringAsFixed(1)}M';
    }

    if (absValue >= 1000) {
      return '$sign₺${(absValue / 1000).toStringAsFixed(1)}K';
    }

    return '$sign₺${absValue.toStringAsFixed(0)}';
  }

  static String _typeLabel(String type) {
    final normalized = type.toLowerCase().trim();

    if (normalized.contains('hisse') || normalized.contains('stock')) {
      return 'Hisse';
    }
    if (normalized.contains('fon') || normalized.contains('etf')) {
      return 'Fon';
    }
    if (normalized.contains('altın') ||
        normalized.contains('altin') ||
        normalized.contains('gold')) {
      return 'Altın';
    }
    if (normalized.contains('kripto') || normalized.contains('crypto')) {
      return 'Kripto';
    }
    if (normalized.contains('nakit') ||
        normalized.contains('cash') ||
        normalized.contains('döviz') ||
        normalized.contains('doviz')) {
      return 'Nakit';
    }

    return type.isEmpty ? '-' : type;
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.show_chart_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPulseBox extends StatelessWidget {
  const _CompactPulseBox({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
