import 'package:flutter/material.dart';

class MarketTicker extends StatelessWidget {
  const MarketTicker({
    super.key,
    required this.rows,
  });

  final List<MarketTickerRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, __) => Container(
          width: 1,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: const Color(0xFFE5E7EB),
        ),
        itemBuilder: (context, index) {
          final row = rows[index];
          final color = row.positive
              ? const Color(0xFF15803D)
              : const Color(0xFFB42318);

          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.flag,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 6),
                Text(
                  row.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  row.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  row.change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MarketTickerRowData {
  final String flag;
  final String name;
  final String value;
  final String change;
  final bool positive;

  const MarketTickerRowData({
    required this.flag,
    required this.name,
    required this.value,
    required this.change,
    required this.positive,
  });
}