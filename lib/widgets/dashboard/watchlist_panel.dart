import 'package:flutter/material.dart';

class WatchlistPanel extends StatelessWidget {
  const WatchlistPanel({
    super.key,
    required this.items,
  });

  final List<WatchlistItem> items;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Watchlist Pro',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Takip listesi bekleniyor.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              _WatchlistRow(item: items[i]),
              if (i != items.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class WatchlistItem {
  const WatchlistItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
  });

  final String symbol;
  final String name;
  final String price;
  final double changePercent;

  bool get isPositive => changePercent >= 0;
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.item});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.symbol.characters.take(2).toString().toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.price,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${item.isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
