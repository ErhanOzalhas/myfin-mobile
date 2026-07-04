

import 'package:flutter/material.dart';

class DistributionCard extends StatelessWidget {
  const DistributionCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<DistributionItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty || total <= 0)
            const Text(
              'Dağılım verisi bekleniyor.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              _DistributionRow(
                item: items[i],
                total: total,
              ),
              if (i != items.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class DistributionItem {
  const DistributionItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.item,
    required this.total,
  });

  final DistributionItem item;
  final double total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (item.value / total).clamp(0.0, 1.0);
    final percent = ratio * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}