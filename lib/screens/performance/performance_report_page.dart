import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../models/dashboard_summary.dart';
import '../../models/portfolio_item.dart';
import '../../models/portfolio_performance.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_performance_service.dart';
import '../../services/report_export_service.dart';
import '../../widgets/common/report_row.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/dashboard/weekly_performance_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../../utils/myfin_formatters.dart';

class PerformanceReportPage extends StatefulWidget {
  const PerformanceReportPage({super.key});

  @override
  State<PerformanceReportPage> createState() => _PerformanceReportPageState();
}

class _PerformanceReportPageState extends State<PerformanceReportPage> {
  String _range = '7 Gün';
  DateTimeRange? _customRange;
  PortfolioPerformance? _lastPerformance;

  static const List<String> _ranges = [
    'Bugün',
    '3 Gün',
    '7 Gün',
    '1 Ay',
    'Özel',
  ];

  Future<DashboardSummary> _loadDashboardSummary(List<PortfolioItem> items) {
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

  DateTimeRange _selectedDateRange() {
    final end = DateTime.now();
    if (_range == 'Özel' && _customRange != null) return _customRange!;
    final days = switch (_range) {
      'Bugün' => 1,
      '3 Gün' => 3,
      '1 Ay' => 30,
      _ => 7,
    };
    return DateTimeRange(
      start: DateTime(
        end.year,
        end.month,
        end.day,
      ).subtract(Duration(days: days - 1)),
      end: end,
    );
  }

  Future<void> _selectRange(String range) async {
    if (range != 'Özel') {
      setState(() => _range = range);
      return;
    }
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          ),
      helpText: 'Performans tarih aralığı',
      saveText: 'Uygula',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customRange = selected;
      _range = range;
    });
  }

  Future<void> _exportReport(ReportFileType type) async {
    final performance = _lastPerformance;
    if (performance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapor için performans verisi bekleniyor.'),
        ),
      );
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await ReportExportService.instance.sharePerformance(
        performance: performance,
        rangeLabel: _range,
        type: type,
        shareOrigin: origin,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rapor oluşturulamadı: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Performans Raporu'),
        centerTitle: false,
        actions: [
          PopupMenuButton<ReportFileType>(
            tooltip: 'Rapor oluştur',
            icon: const Icon(Icons.ios_share_rounded),
            onSelected: _exportReport,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ReportFileType.pdf,
                child: Text('PDF Raporu'),
              ),
              PopupMenuItem(
                value: ReportFileType.excel,
                child: Text('Excel Raporu'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: PortfolioRepository.instance.watchPortfolio(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? <PortfolioItem>[];

            return FutureBuilder<DashboardSummary>(
              future: _loadDashboardSummary(items),
              builder: (context, summarySnapshot) {
                final summary = summarySnapshot.data ?? _fallbackSummary(items);
                final selectedRange = _selectedDateRange();
                return FutureBuilder<PortfolioPerformance>(
                  future: PortfolioPerformanceService.instance.load(
                    items: items,
                    start: selectedRange.start,
                    end: selectedRange.end,
                  ),
                  builder: (context, performanceSnapshot) {
                    final performance = performanceSnapshot.data;
                    if (performance != null) _lastPerformance = performance;
                    final hasHistory = performance?.hasHistory ?? false;
                    final isPositive = performance?.isPositive ?? true;
                    final color = isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _ranges.map((range) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(range),
                                  selected: range == _range,
                                  showCheckmark: false,
                                  selectedColor: const Color(0xFF0F73C5),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: range == _range
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) => _selectRange(range),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        WeeklyPerformanceCard(
                          title: '$_range performansı',
                          subtitle: hasHistory
                              ? 'Gerçek günlük portföy kapanışları.'
                              : 'Performans geçmişi oluşturuluyor.',
                          changeText: formatPercent(
                            performance?.totalReturnPercent ?? 0,
                          ),
                          values: performance?.chartValues ?? const [],
                          isPositive: isPositive,
                          color: color,
                          momentumLabel:
                              performance?.momentumLabel ?? 'Bekleniyor',
                          riskLabel: performance?.riskLabel ?? 'Bekleniyor',
                          riskColor: _riskColor(performance),
                          dailyLabel: formatPercent(
                            performance?.averageDailyReturnPercent ?? 0,
                          ),
                          hasHistory: hasHistory,
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
                                value: formatPercent(
                                  performance?.totalReturnPercent ?? 0,
                                ),
                              ),
                              ReportRow(
                                label: 'Net Sermaye Hareketi',
                                value: formatCurrency(
                                  performance?.netContribution ?? 0,
                                ),
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
            );
          },
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 0,
        allowSelectedDestinationNavigation: true,
      ),
    );
  }
}

Color _riskColor(PortfolioPerformance? performance) {
  if (performance == null || !performance.hasHistory) {
    return const Color(0xFF64748B);
  }
  if (performance.volatilityPercent >= 3) return const Color(0xFFDC2626);
  if (performance.volatilityPercent >= 1.25) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFF16A34A);
}
