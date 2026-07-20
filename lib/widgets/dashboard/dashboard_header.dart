import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.totalValueText,
    required this.profitText,
    required this.profitPercentText,
    required this.isProfit,
    required this.onRefresh,
  });

  final String totalValueText;
  final String profitText;
  final String profitPercentText;
  final bool isProfit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final accent = isProfit ? const Color(0xFF0F8A4B) : const Color(0xFFB42318);
    final capsuleBackground = isProfit ? const Color(0xFFEAF8EF) : const Color(0xFFFEECEC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008DB9),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F008DB9),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: Colors.white,
                tooltip: 'Yenile',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Toplam Portföy',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalValueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w400,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: capsuleBackground,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfit
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: accent,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  '$profitText ($profitPercentText)',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
