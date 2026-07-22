import 'package:flutter/material.dart';

import '../models/cash_movement.dart';
import '../repositories/cash_repository.dart';
import '../screens/cash/cash_management_page.dart';
import '../utils/myfin_formatters.dart';

class CashSummaryCard extends StatelessWidget {
  const CashSummaryCard({super.key, required this.investmentValue});

  final double investmentValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CashBalanceSnapshot>(
      stream: CashRepository.instance.watchBalance(),
      initialData: CashRepository.instance.latest,
      builder: (context, snapshot) {
        final cash = snapshot.data?.balance ?? 0;
        final total = investmentValue + cash;
        final ratio = total <= 0 ? 0.0 : cash / total * 100;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CashManagementPage(),
              ),
            ),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF0F9FF),
                    Color(0xFFE0F2FE),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBAE6FD)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: .10),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 15,
                        color: Color(0xFF0369A1),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Finansal Varlıklar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF075985),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Nakit yönetimi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF0284C7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .90),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: _SummaryMetric(
                            icon: Icons.show_chart_rounded,
                            label: 'Yatırımlar',
                            value: formatCurrency(investmentValue, 'TRY'),
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const _VerticalDivider(),
                        Expanded(
                          flex: 10,
                          child: _SummaryMetric(
                            icon: Icons.savings_outlined,
                            label: 'TL Nakit',
                            value: formatCurrency(cash, 'TRY'),
                            detail: '%${ratio.toStringAsFixed(1)}',
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                        const _VerticalDivider(),
                        Expanded(
                          flex: 11,
                          child: _SummaryMetric(
                            icon: Icons.account_balance_rounded,
                            label: 'Toplam Varlık',
                            value: formatCurrency(total, 'TRY'),
                            color: const Color(0xFF0F172A),
                            emphasize: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.detail,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? detail;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color.withValues(alpha: .82)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: .76),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: emphasize ? 15 : 14,
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                  color: color,
                  letterSpacing: -.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail ?? (emphasize ? 'Yatırım + nakit' : 'Güncel değer'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: .66),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFBAE6FD).withValues(alpha: .80),
    );
  }
}
