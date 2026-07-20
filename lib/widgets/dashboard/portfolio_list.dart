

import 'package:flutter/material.dart';

class PortfolioList extends StatelessWidget {
  const PortfolioList({
    super.key,
    required this.items,
  });

  final List<PortfolioRowData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Portföy boş.')),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _PortfolioRow(item: items[index]),
            ),
    );
  }
}

class PortfolioRowData {
  const PortfolioRowData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.pnl,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String value;
  final String pnl;
  final bool positive;
}

class _PortfolioRow extends StatelessWidget {
  const _PortfolioRow({required this.item});

  final PortfolioRowData item;

  @override
  Widget build(BuildContext context) {
    final color = item.positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return ListTile(
      leading: CircleAvatar(
        child: Text(item.title.characters.first.toUpperCase()),
      ),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w400)),
      subtitle: Text(item.subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(item.value, style: const TextStyle(fontWeight: FontWeight.w400)),
          Text(item.pnl, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
