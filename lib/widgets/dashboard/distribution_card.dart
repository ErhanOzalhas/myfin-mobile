import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DistributionCard extends StatelessWidget {
  const DistributionCard({super.key, required this.items, this.onItemTap});

  final List<DistributionItem> items;
  final ValueChanged<DistributionItem>? onItemTap;

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
          if (items.isEmpty || total <= 0)
            const Text(
              'Dağılım verisi bekleniyor.',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              _DistributionRow(
                item: items[i],
                total: total,
                onTap: onItemTap == null ? null : () => onItemTap!(items[i]),
              ),
              if (i != items.length - 1) const SizedBox(height: 16),
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
    this.changePercent,
  });

  final String label;
  final double value;
  final Color color;

  /// Kategori bazındaki kâr/zarar yüzdesi.
  ///
  /// Pozitif: yeşil
  /// Negatif: kırmızı
  /// Null: henüz hesaplanmadı
  final double? changePercent;
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.item, required this.total, this.onTap});

  final DistributionItem item;
  final double total;
  final VoidCallback? onTap;

  static final NumberFormat _currencyFormatter =
      NumberFormat.decimalPatternDigits(locale: 'tr_TR', decimalDigits: 2);

  static final NumberFormat _percentFormatter = NumberFormat('0.0', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (item.value / total).clamp(0.0, 1.0);

    final allocationPercent = ratio * 100;
    final changePercent = item.changePercent;

    final bool hasChange = changePercent != null;
    final bool isPositive = (changePercent ?? 0) > 0;
    final bool isNegative = (changePercent ?? 0) < 0;

    final Color changeColor = isPositive
        ? const Color(0xFF16A34A)
        : isNegative
        ? const Color(0xFFDC2626)
        : const Color(0xFF64748B);

    final IconData? changeIcon = isPositive
        ? Icons.arrow_drop_up_rounded
        : isNegative
        ? Icons.arrow_drop_down_rounded
        : null;

    final String changeText;

    if (!hasChange) {
      changeText = '—';
    } else {
      final prefix = isPositive ? '+' : '';
      changeText = '$prefix${_percentFormatter.format(changePercent)}%';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_currencyFormatter.format(item.value)} TL',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (changeIcon != null)
                        Icon(changeIcon, size: 14, color: changeColor),
                      Flexible(
                        child: Text(
                          changeText,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: isPositive || isNegative
                                ? FontWeight.w400
                                : FontWeight.w400,
                            color: changeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: ratio,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${_percentFormatter.format(allocationPercent)}%',
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
