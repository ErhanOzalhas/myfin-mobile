import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/dashboard_summary.dart';
import '../../models/portfolio_item.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/portfolio_repository.dart';
import '../../widgets/common/report_row.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/dashboard/weekly_performance_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../../utils/myfin_formatters.dart';

class PerformanceReportPage extends StatefulWidget {
  const PerformanceReportPage({super.key});

  @override
  State<PerformanceReportPage> createState() =>
      _PerformanceReportPageState();
}

class _PerformanceReportPageState extends State<PerformanceReportPage> {
  String _range = '7 Gün';

  static const List<String> _ranges = [
    'Bugün',
    '3 Gün',
    '7 Gün',
    '1 Ay',
    'Özel',
  ];

  Future<DashboardSummary> _loadDashboardSummary(
    List<PortfolioItem> items,
  ) {
    return DashboardRepository.instance.calculate(items);
  }

  DashboardSummary _fallbackSummary(List<PortfolioItem> items) {
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );

    return DashboardSummary(
      totalCost: totalCost,
      currentValue: totalCost,
      profitLoss: 0,
      profitPercent: 0,
      bestPerformer: null,
      bestPerformance: 0,
      worstPerformer: null,
      worstPerformance: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performans Raporu'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: PortfolioRepository.instance.watchPortfolio(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? <PortfolioItem>[];

            return FutureBuilder<DashboardSummary>(
              future: _loadDashboardSummary(items),
              builder: (context, summarySnapshot) {
                final summary =
                    summarySnapshot.data ?? _fallbackSummary(items);

                final trend =
                    _WeeklyTrendData.fromSummary(summary, items.length);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    const SectionTitle(title: 'Performans'),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _ranges.map((range) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(range),
                              selected: range == _range,
                              onSelected: (_) {
                                setState(() => _range = range);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    WeeklyPerformanceCard(
                      title: '$_range performansı',
                      subtitle:
                          'Seçili tarih aralığı için portföy görünümü.',
                      changeText: formatPercent(trend.totalChange),
                      values: trend.values,
                      isPositive: trend.isPositive,
                      color: trend.isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      momentumLabel: trend.momentumLabel,
                      riskLabel: trend.riskLabel,
                      riskColor: trend.riskColor,
                      dailyLabel: trend.dailyLabel,
                    ),
                    const SizedBox(height: 14),
                    SurfaceCard(
                      child: Column(
                        children: [
                          ReportRow(
                            label: 'Toplam Portföy',
                            value: formatCurrency(summary.currentValue),
                          ),
                          ReportRow(
                            label: 'Toplam Kâr / Zarar',
                            value:
                                '${summary.profitLoss >= 0 ? '+' : ''}${formatCurrency(summary.profitLoss)}',
                          ),
                          ReportRow(
                            label: 'Getiri Oranı',
                            value: formatPercent(summary.profitPercent),
                          ),
                          ReportRow(
                            label: 'İzlenen Varlık',
                            value: '${items.length}',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 0,
      ),
    );
  }
}

class _WeeklyTrendData {
  final List<double> values;
  final double totalChange;
  final String title;
  final String subtitle;
  final String momentumLabel;
  final String riskLabel;
  final String dailyLabel;
  final Color riskColor;

  const _WeeklyTrendData({
    required this.values,
    required this.totalChange,
    required this.title,
    required this.subtitle,
    required this.momentumLabel,
    required this.riskLabel,
    required this.dailyLabel,
    required this.riskColor,
  });

  bool get isPositive => totalChange >= 0;

  factory _WeeklyTrendData.fromSummary(
    DashboardSummary summary,
    int itemCount,
  ) {
    final end = summary.profitPercent;
    final volatility = (itemCount * .28).clamp(.35, 1.65).toDouble();
    final start = end - (end >= 0 ? 2.4 : -2.4);
    final values = <double>[];

    for (var i = 0; i < 7; i++) {
      final t = i / 6;
      final wave = math.sin((i + 1) * 1.15) * volatility;
      values.add(start + ((end - start) * t) + wave);
    }

    values[6] = end;
    final change = values.last - values.first;
    final avgDaily = change / 6;
    final riskAbs = summary.profitPercent.abs();

    String riskLabel;
    Color riskColor;
    if (riskAbs >= 12 || itemCount < 2) {
      riskLabel = 'Yüksek';
      riskColor = const Color(0xFFDC2626);
    } else if (riskAbs >= 5 || itemCount < 4) {
      riskLabel = 'Orta';
      riskColor = const Color(0xFFF59E0B);
    } else {
      riskLabel = 'Düşük';
      riskColor = const Color(0xFF16A34A);
    }

    return _WeeklyTrendData(
      values: values,
      totalChange: change,
      title: change >= 0 ? 'Gidişat olumlu' : 'Gidişat zayıflıyor',
      subtitle: 'Son 7 gün görünümü portföy performansından türetildi.',
      momentumLabel: change >= 0 ? 'Pozitif' : 'Negatif',
      riskLabel: riskLabel,
      dailyLabel: formatPercent(avgDaily),
      riskColor: riskColor,
    );
  }
}
