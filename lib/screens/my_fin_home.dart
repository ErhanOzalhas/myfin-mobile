import 'dart:async';
import 'dart:math' as math;
import '../widgets/dashboard/weekly_performance_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myfin_mobile/screens/intelligence/intelligence_page.dart';
import 'package:myfin_mobile/services/recommendation_engine.dart';
import 'package:myfin_mobile/services/portfolio_summary_service.dart';
import 'package:flutter/material.dart';
import '../services/ai_analysis_service.dart';
import '../services/ai_advisor_service.dart';
import '../models/dashboard_summary.dart';
import 'package:myfin_mobile/models/ai_portfolio_score.dart';
import '../models/portfolio_item.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/market_repository.dart';
import '../repositories/portfolio_repository.dart';
import '../widgets/dashboard/ai_analysis_card.dart';
import '../widgets/dashboard/ai_advisor_card.dart';
import '../widgets/dashboard/ai_score_card.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/distribution_card.dart';
import '../widgets/dashboard/market_ticker.dart';
import '../widgets/dashboard/watchlist_panel.dart';
import '../widgets/dashboard/portfolio_pulse_panel.dart';
import '../widgets/dashboard/portfolio_list.dart';
import '../widgets/dashboard/smart_insights_panel.dart';
import 'add_portfolio_item_page.dart';

class MyFinHome extends StatefulWidget {
  const MyFinHome({super.key});

  @override
  State<MyFinHome> createState() => _MyFinHomeState();
}

class _MyFinHomeState extends State<MyFinHome> {
  Timer? _refreshTimer;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _refreshTick++);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshMarketData() async {
    setState(() => _refreshTick++);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshMarketData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            children: [
              const _Header(),
              const SizedBox(height: 24),
              _HeroPortfolioCard(refreshTick: _refreshTick),
              const SizedBox(height: 14),
              _DashboardFadeIn(
                delay: 60,
                child: const _AIScoreSection(),
              ),
              const SizedBox(height: 14),
              _KpiGrid(refreshTick: _refreshTick),
              const SizedBox(height: 14),
              _DashboardFadeIn(
                delay: 80,
                child: _PerformanceHighlights(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Son 7 Gün Performansı', action: 'Trend'),
              _WeeklyPerformanceCard(refreshTick: _refreshTick),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Canlı Piyasa', action: 'Tümü'),
              _DashboardFadeIn(
                delay: 140,
                child: _MarketTicker(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Portföy Dağılımı', action: 'Detay'),
              _DashboardFadeIn(
                delay: 200,
                child: _DistributionCard(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 14),
              _DashboardInsightPanel(refreshTick: _refreshTick),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Portföy Nabzı', action: 'Yeni'),
              _DashboardFadeIn(
                delay: 260,
                child: _PortfolioPulsePanel(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Akıllı İçgörüler', action: 'AI'),
              _DashboardFadeIn(
                delay: 320,
                child: _SmartInsightsPanel(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Takip Listesi', action: 'İzle'),
              _DashboardFadeIn(
                delay: 360,
                child: _WatchlistSection(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 20),
              _PortfolioList(refreshTick: _refreshTick),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Hızlı İşlemler'),
              const _QuickActions(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Son İşlemler', action: 'Tümü'),
              const _RecentTransactions(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
onDestinationSelected: (index) {
  if (index == 0) return;

  if (index == 1) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PortfolioPage(),
      ),
    );
    return;
  }

  if (index == 2) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddPortfolioItemPage(),
      ),
    );
    return;
  }

  if (index == 3) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const IntelligencePage(),
      ),
    );
    return;
  }

  final label = switch (index) {
    4 => 'Ayarlar ekranı yakında aktif olacak.',
    _ => 'Bu bölüm yakında aktif olacak.',
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(label)),
  );
},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.pie_chart_rounded), label: 'Portföy'),
          NavigationDestination(icon: Icon(Icons.add_circle_rounded), label: 'Ekle'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Analiz'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

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

String _formatCurrency(double value, [String currency = 'TRY']) {
  final symbol = currency == 'TRY' ? '₺' : '$currency ';
  return '$symbol${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatPercent(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2).replaceAll('.', ',')}%';
}



class _PortfolioIntelligence {
  final int overallScore;
  final int riskScore;
  final int diversificationScore;
  final int sectorScore;
  final int currencyScore;
  final String topSector;
  final double topSectorWeight;
  final String topCurrency;
  final double topCurrencyWeight;
  final String topCountry;
  final double topCountryWeight;
  final String summary;
  final List<String> signals;

  const _PortfolioIntelligence({
    required this.overallScore,
    required this.riskScore,
    required this.diversificationScore,
    required this.sectorScore,
    required this.currencyScore,
    required this.topSector,
    required this.topSectorWeight,
    required this.topCurrency,
    required this.topCurrencyWeight,
    required this.topCountry,
    required this.topCountryWeight,
    required this.summary,
    required this.signals,
  });
}

_PortfolioIntelligence _buildPortfolioIntelligence(List<PortfolioItem> items) {
  if (items.isEmpty) {
    return const _PortfolioIntelligence(
      overallScore: 0,
      riskScore: 0,
      diversificationScore: 0,
      sectorScore: 0,
      currencyScore: 0,
      topSector: 'Veri yok',
      topSectorWeight: 0,
      topCurrency: 'Veri yok',
      topCurrencyWeight: 0,
      topCountry: 'Veri yok',
      topCountryWeight: 0,
      summary: 'Portföy verisi eklendiğinde AI Intelligence aktif olacak.',
      signals: [
        'İlk varlığı eklediğinde risk ve çeşitlilik hesabı otomatik oluşacak.',
      ],
    );
  }

  final total = items.fold<double>(0, (sum, item) => sum + item.totalCost);
  if (total <= 0) {
    return const _PortfolioIntelligence(
      overallScore: 0,
      riskScore: 0,
      diversificationScore: 0,
      sectorScore: 0,
      currencyScore: 0,
      topSector: 'Veri yok',
      topSectorWeight: 0,
      topCurrency: 'Veri yok',
      topCurrencyWeight: 0,
      topCountry: 'Veri yok',
      topCountryWeight: 0,
      summary: 'Portföy maliyet bilgisi oluşunca skorlar hesaplanacak.',
      signals: [
        'Maliyet bilgisi olmayan varlıklar analize dahil edilemez.',
      ],
    );
  }

  final symbolWeights = <String, double>{};
  final sectorWeights = <String, double>{};
  final currencyWeights = <String, double>{};
  final countryWeights = <String, double>{};

  for (final item in items) {
    final weight = item.totalCost / total;
    final symbol = item.symbol.trim().toUpperCase();
    final sector = _inferSector(item);
    final currency = item.currency.trim().isEmpty ? 'TRY' : item.currency.trim().toUpperCase();
    final country = _inferCountry(item);

    symbolWeights[symbol] = (symbolWeights[symbol] ?? 0) + weight;
    sectorWeights[sector] = (sectorWeights[sector] ?? 0) + weight;
    currencyWeights[currency] = (currencyWeights[currency] ?? 0) + weight;
    countryWeights[country] = (countryWeights[country] ?? 0) + weight;
  }

  final biggestPosition = _maxWeight(symbolWeights);
  final topSector = _maxWeight(sectorWeights);
  final topCurrency = _maxWeight(currencyWeights);
  final topCountry = _maxWeight(countryWeights);

  final concentrationPenalty = (biggestPosition.value * 58).round();
  final sectorPenalty = (topSector.value * 24).round();
  final currencyPenalty = (topCurrency.value * 18).round();
  final itemBonus = (items.length * 6).clamp(0, 24).round();

  final diversificationScore =
      (100 - concentrationPenalty - sectorPenalty + itemBonus).clamp(0, 100).round();

  final riskScore = (34 +
          (biggestPosition.value * 38) +
          (topSector.value * 18) +
          (topCurrency.value > .85 ? 10 : 0) -
          (items.length >= 5 ? 8 : 0))
      .clamp(0, 100)
      .round();

  final sectorScore = (100 - (topSector.value * 52)).clamp(0, 100).round();
  final currencyScore = (100 - (topCurrency.value * 42)).clamp(0, 100).round();

  final overallScore = ((diversificationScore * .38) +
          ((100 - riskScore) * .28) +
          (sectorScore * .2) +
          (currencyScore * .14))
      .round()
      .clamp(0, 100)
      .toInt();

  final signals = <String>[
    'En büyük pozisyon: ${biggestPosition.key} · ${_weightText(biggestPosition.value)}',
    'Sektör ağırlığı: ${topSector.key} · ${_weightText(topSector.value)}',
    'Para birimi ağırlığı: ${topCurrency.key} · ${_weightText(topCurrency.value)}',
  ];

  final summary = riskScore >= 72
      ? 'Portföy konsantrasyonu yüksek. Çeşitlendirme tarafında iyileştirme alanı var.'
      : diversificationScore >= 70
          ? 'Portföy dengesi sağlıklı görünüyor. Risk dağılımı kontrol altında.'
          : 'Portföy dengesi orta seviyede. Ana yoğunlukları takip etmek faydalı olur.';

  return _PortfolioIntelligence(
    overallScore: overallScore,
    riskScore: riskScore,
    diversificationScore: diversificationScore,
    sectorScore: sectorScore,
    currencyScore: currencyScore,
    topSector: topSector.key,
    topSectorWeight: topSector.value,
    topCurrency: topCurrency.key,
    topCurrencyWeight: topCurrency.value,
    topCountry: topCountry.key,
    topCountryWeight: topCountry.value,
    summary: summary,
    signals: signals,
  );
}

MapEntry<String, double> _maxWeight(Map<String, double> weights) {
  if (weights.isEmpty) return const MapEntry('Veri yok', 0);

  return weights.entries.reduce(
    (best, item) => item.value > best.value ? item : best,
  );
}

String _weightText(double value) {
  return '%${(value * 100).toStringAsFixed(0)}';
}

String _inferSector(PortfolioItem item) {
  final symbol = item.symbol.toUpperCase();
  final name = item.name.toUpperCase();
  final type = item.type.toUpperCase();

  if (type.contains('ALTIN') || name.contains('ALTIN') || symbol.contains('GOLD')) {
    return 'Emtia';
  }

  if (type.contains('KRİPTO') ||
      type.contains('CRYPTO') ||
      ['BTC', 'ETH', 'SOL', 'AVAX', 'XRP'].contains(symbol)) {
    return 'Kripto';
  }

  if ([
    'AAPL',
    'MSFT',
    'NVDA',
    'GOOGL',
    'GOOG',
    'META',
    'TSLA',
    'AMD',
    'INTC',
    'SPCX',
    'RKLM',
  ].contains(symbol)) {
    return 'Teknoloji';
  }

  if ([
    'ASELS',
    'KCHOL',
    'SAHOL',
    'SISE',
    'TUPRS',
    'THYAO',
    'FROTO',
    'EREGL',
  ].contains(symbol)) {
    return 'BIST / Sanayi';
  }

  if (['AKBNK', 'GARAN', 'ISCTR', 'YKBNK', 'HALKB', 'VAKBN'].contains(symbol)) {
    return 'Finans';
  }

  if (symbol.contains('USD') || symbol.contains('EUR') || type.contains('DÖVİZ')) {
    return 'Döviz';
  }

  return 'Diğer';
}

String _inferCountry(PortfolioItem item) {
  final symbol = item.symbol.toUpperCase();
  final currency = item.currency.toUpperCase();

  if (currency == 'USD' ||
      [
        'AAPL',
        'MSFT',
        'NVDA',
        'GOOGL',
        'GOOG',
        'META',
        'TSLA',
        'AMD',
        'INTC',
        'SPCX',
        'RKLM',
      ].contains(symbol)) {
    return 'ABD';
  }

  if (currency == 'EUR') return 'Avrupa';

  return 'Türkiye';
}

class _PortfolioIntelligenceCard extends StatelessWidget {
  final _PortfolioIntelligence intelligence;

  const _PortfolioIntelligenceCard({required this.intelligence});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Intelligence',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sprint 4.1 analiz motoru',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              _ScorePill(score: intelligence.overallScore),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            intelligence.summary,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniScoreTile(
                  title: 'Risk',
                  value: intelligence.riskScore,
                  helper: 'Düşük daha iyi',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniScoreTile(
                  title: 'Çeşitlilik',
                  value: intelligence.diversificationScore,
                  helper: 'Yüksek daha iyi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniScoreTile(
                  title: 'Sektör',
                  value: intelligence.sectorScore,
                  helper: intelligence.topSector,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniScoreTile(
                  title: 'Döviz',
                  value: intelligence.currencyScore,
                  helper: intelligence.topCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...intelligence.signals.map(
            (signal) => Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 17,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      signal,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;

  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score/100',
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MiniScoreTile extends StatelessWidget {
  final String title;
  final int value;
  final String helper;

  const _MiniScoreTile({
    required this.title,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            helper,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF008DB9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Benim Finans',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.7,
                      color: Color(0xFF0F172A))),
              SizedBox(height: 2),
              Text('Akıllı yatırım takibi',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Çıkış yap',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

class _HeroPortfolioCard extends StatelessWidget {
  final int refreshTick;

  const _HeroPortfolioCard({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }

  final items = snapshot.data ?? [];

        return FutureBuilder<DashboardSummary>(
          key: ValueKey('hero-summary-$refreshTick-${items.length}'),
          future: _loadDashboardSummary(items),
          builder: (context, summarySnapshot) {
            final summary = summarySnapshot.data ?? _fallbackSummary(items);
            final isPositive = summary.profitLoss >= 0;
            return InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PortfolioPage(),
                  ),
                );
              },
              child: DashboardHeader(
                totalValueText: _formatCurrency(summary.currentValue),
                profitText: '${isPositive ? '+' : ''}${_formatCurrency(summary.profitLoss)}',
                profitPercentText: _formatPercent(summary.profitPercent),
                isProfit: isPositive,
                onRefresh: () {},
              ),
            );
          },
        );
      },
    );
  }
}
class _AIScoreSection extends StatelessWidget {
  const _AIScoreSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final analysis = const AIAnalysisService().analyze(items);
        final intelligence = _buildPortfolioIntelligence(items);

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IntelligencePage(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6D5DF6),
                        Color(0xFF00A3FF),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MyFin Intelligence',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        analysis.resultSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Score ${intelligence.overallScore} • View insights',
                        style: const TextStyle(
                          color: Color(0xFF1D9BF0),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final int refreshTick;

  const _KpiGrid({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return FutureBuilder<DashboardSummary>(
          key: ValueKey('kpi-summary-$refreshTick-${items.length}'),
          future: _loadDashboardSummary(items),
          builder: (context, totalsSnapshot) {
            final summary = totalsSnapshot.data ?? _fallbackSummary(items);

            final isPositive = summary.profitLoss >= 0;

            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Maliyet',
                    value: _formatCurrency(summary.totalCost),
                    subtitle: '${items.length} varlık',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Kâr / Zarar',
                    value:
                        '${isPositive ? '+' : ''}${_formatCurrency(summary.profitLoss)}',
                    subtitle: _formatPercent(summary.profitPercent),
                    icon: isPositive
                        ? Icons.north_east_rounded
                        : Icons.south_east_rounded,
                    color: isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


class _PerformanceHighlights extends StatelessWidget {
  final int refreshTick;

  const _PerformanceHighlights({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return FutureBuilder<DashboardSummary>(
          key: ValueKey('performance-summary-$refreshTick-${items.length}'),
          future: _loadDashboardSummary(items),
          builder: (context, summarySnapshot) {
            final summary = summarySnapshot.data ?? _fallbackSummary(items);
            final hasItems = items.isNotEmpty;

            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'En İyi',
                    value: hasItems ? (summary.bestPerformer ?? '-') : '-',
                    subtitle: hasItems ? _formatPercent(summary.bestPerformance) : 'Veri yok',
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'En Zayıf',
                    value: hasItems ? (summary.worstPerformer ?? '-') : '-',
                    subtitle: hasItems ? _formatPercent(summary.worstPerformance) : 'Veri yok',
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPerformanceCard extends StatelessWidget {
  final int refreshTick;

  const _WeeklyPerformanceCard({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            child: SizedBox(
              height: 190,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const _SurfaceCard(
            child: _EmptyStateLine(
              icon: Icons.show_chart_rounded,
              title: 'Trend grafiği beklemede',
              subtitle: 'Portföye varlık eklediğinde 7 günlük performans simülasyonu oluşacak.',
            ),
          );
        }

        return FutureBuilder<DashboardSummary>(
          key: ValueKey('weekly-performance-$refreshTick-${items.length}'),
          future: _loadDashboardSummary(items),
          builder: (context, summarySnapshot) {
            final summary = summarySnapshot.data ?? _fallbackSummary(items);
            final trend = _WeeklyTrendData.fromSummary(summary, items.length);
            final color = trend.isPositive
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626);

            return _DashboardFadeIn(
              delay: 110,
              child: WeeklyPerformanceCard(
                title: trend.title,
                subtitle: trend.subtitle,
                changeText: _formatPercent(trend.totalChange),
                values: trend.values,
                isPositive: trend.isPositive,
                color: color,
                momentumLabel: trend.momentumLabel,
                riskLabel: trend.riskLabel,
                riskColor: trend.riskColor,
                dailyLabel: trend.dailyLabel,
              ),
            );
          },
        );
      },
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

  factory _WeeklyTrendData.fromSummary(DashboardSummary summary, int itemCount) {
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
      title: change >= 0 ? 'Momentum yukarı' : 'Momentum zayıflıyor',
      subtitle: 'Son 7 gün görünümü portföy performansından türetildi.',
      momentumLabel: change >= 0 ? 'Pozitif' : 'Negatif',
      riskLabel: riskLabel,
      dailyLabel: _formatPercent(avgDaily),
      riskColor: riskColor,
    );
  }
}

class _DashboardFadeIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const _DashboardFadeIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}



class _MarketTicker extends StatelessWidget {
  final int refreshTick;

  const _MarketTicker({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return const MarketTicker(
      rows: [
        MarketTickerRowData(
          flag: '🇺🇸',
          name: 'USD / TRY',
          value: '39,82',
          change: '+0,18%',
          positive: true,
        ),
        MarketTickerRowData(
          flag: '🇪🇺',
          name: 'EUR / TRY',
          value: '46,73',
          change: '+0,09%',
          positive: true,
        ),
        MarketTickerRowData(
          flag: '🥇',
          name: 'Gram Altın',
          value: '₺4.851',
          change: '-0,12%',
          positive: false,
        ),
        MarketTickerRowData(
          flag: '📈',
          name: 'BIST 100',
          value: '10.421',
          change: '+1,34%',
          positive: true,
        ),
      ],
    );
  }
}


class _DistributionCard extends StatelessWidget {
  final int refreshTick;

  const _DistributionCard({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            child: SizedBox(
              height: 145,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const _SurfaceCard(
            child: _EmptyStateLine(
              icon: Icons.donut_large_rounded,
              title: 'Dağılım için veri yok',
              subtitle: 'Varlık eklediğinde portföy dağılımı otomatik hesaplanacak.',
            ),
          );
        }

        return FutureBuilder<_DistributionSnapshot>(
          key: ValueKey('distribution-$refreshTick-${items.length}'),
          future: _loadDistributionSnapshot(items),
          builder: (context, distributionSnapshot) {
            final distribution = distributionSnapshot.data ??
                _DistributionSnapshot.fromCost(items);
            return DistributionCard(
              title: 'Portföy Dağılımı',
              items: distribution.segments
                  .map(
                    (segment) => DistributionItem(
                      label: segment.label,
                      value: segment.ratio * distribution.totalValue,
                      color: segment.color,
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _DashboardInsightPanel extends StatelessWidget {
  final int refreshTick;

  const _DashboardInsightPanel({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return FutureBuilder<DashboardSummary>(
          key: ValueKey('insight-summary-$refreshTick-${items.length}'),
          future: _loadDashboardSummary(items),
          builder: (context, summarySnapshot) {
            final summary = summarySnapshot.data ?? _fallbackSummary(items);
            final hasItems = items.isNotEmpty;
            final isPositive = summary.profitLoss >= 0;
            final dominantType = hasItems ? _dominantAssetType(items) : 'Beklemede';

            return Row(
              children: [
                Expanded(
                  child: _MiniInsightCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Akıllı Özet',
                    value: hasItems
                        ? (isPositive ? 'Pozitif seyir' : 'Dikkat gerekli')
                        : 'Hazır',
                    subtitle: hasItems
                        ? '${_formatPercent(summary.profitPercent)} toplam performans'
                        : 'İlk varlığı ekleyerek başla',
                    color: isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInsightCard(
                    icon: Icons.category_rounded,
                    title: 'Yoğunluk',
                    value: dominantType,
                    subtitle: hasItems ? '${items.length} varlık izleniyor' : 'Veri yok',
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MiniInsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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


class _PortfolioPulsePanel extends StatelessWidget {
  final int refreshTick;

  const _PortfolioPulsePanel({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const _SurfaceCard(
            child: _EmptyStateLine(
              icon: Icons.monitor_heart_rounded,
              title: 'Portföy nabzı beklemede',
              subtitle: 'Varlık ekledikçe risk, yoğunluk ve günlük sinyal burada oluşacak.',
            ),
          );
        }

        return FutureBuilder<_PulseData>(
          key: ValueKey('pulse-$refreshTick-${items.length}'),
          future: _loadPulseData(items),
          builder: (context, pulseSnapshot) {
            final pulse = pulseSnapshot.data ?? _PulseData.fromCost(items);
            return PortfolioPulsePanel(
              title: pulse.title,
              message: pulse.message,
              score: pulse.score,
              dominantLabel: pulse.dominantLabel,
              assetCount: items.length,
              color: pulse.color,
              icon: pulse.icon,
            );
          },
        );
      },
    );
  }
}

class _EmptyStateLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon, color: const Color(0xFF008DB9)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


Future<_PulseData> _loadPulseData(List<PortfolioItem> items) async {
  final valuesByType = <String, double>{};
  double totalValue = 0;
  double totalCost = 0;
  double totalProfit = 0;

  for (final item in items) {
    final cost = item.totalCost;
    double currentValue;

    try {
      final quote = await MarketRepository.instance.getQuote(
        symbol: item.symbol,
        type: item.type,
      );
      currentValue = item.quantity * quote.currentPrice;
    } catch (_) {
      currentValue = cost;
    }

    valuesByType[item.type] = (valuesByType[item.type] ?? 0) + currentValue;
    totalValue += currentValue;
    totalCost += cost;
    totalProfit += currentValue - cost;
  }

  return _PulseData.fromValues(
    items: items,
    valuesByType: valuesByType,
    totalValue: totalValue,
    totalCost: totalCost,
    totalProfit: totalProfit,
  );
}

class _PulseData {
  final double score;
  final String title;
  final String message;
  final String dominantLabel;
  final Color color;
  final IconData icon;

  const _PulseData({
    required this.score,
    required this.title,
    required this.message,
    required this.dominantLabel,
    required this.color,
    required this.icon,
  });

  factory _PulseData.fromCost(List<PortfolioItem> items) {
    final valuesByType = <String, double>{};
    double totalCost = 0;

    for (final item in items) {
      valuesByType[item.type] = (valuesByType[item.type] ?? 0) + item.totalCost;
      totalCost += item.totalCost;
    }

    return _PulseData.fromValues(
      items: items,
      valuesByType: valuesByType,
      totalValue: totalCost,
      totalCost: totalCost,
      totalProfit: 0,
    );
  }

  factory _PulseData.fromValues({
    required List<PortfolioItem> items,
    required Map<String, double> valuesByType,
    required double totalValue,
    required double totalCost,
    required double totalProfit,
  }) {
    final dominant = _dominantEntry(valuesByType);
    final dominantRatio = totalValue <= 0 ? 0 : dominant.value / totalValue;
    final double profitPercent =
    totalCost <= 0 ? 0.0 : (totalProfit / totalCost) * 100;
    double score = 88;
    if (items.length < 3) score -= 14;
    if (dominantRatio > .70) score -= 22;
    if (dominantRatio > .50) score -= 10;
    if (profitPercent < -5) score -= 18;
    if (profitPercent > 5) score += 6;
    score = score.clamp(18, 98).toDouble();

    final dominantLabel = dominant.key.isEmpty ? 'Diğer' : _assetTypeLabel(dominant.key);

    if (score >= 75) {
      return _PulseData(
        score: score,
        title: 'Portföy dengesi güçlü',
        message: '$dominantLabel ağırlığı kontrol altında. Güncel performans ${_formatPercent(profitPercent)}.',
        dominantLabel: dominantLabel,
        color: const Color(0xFF16A34A),
        icon: Icons.verified_rounded,
      );
    }

    if (score >= 55) {
      return _PulseData(
        score: score,
        title: 'Portföy dengesi izlenmeli',
        message: '$dominantLabel tarafında yoğunluk artıyor. Dağılımı düzenli takip et.',
        dominantLabel: dominantLabel,
        color: const Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
      );
    }

    return _PulseData(
      score: score,
      title: 'Risk yoğunluğu yüksek',
      message: '$dominantLabel portföyde baskın. Yeni alımlarda çeşitlendirme düşünebilirsin.',
      dominantLabel: dominantLabel,
      color: const Color(0xFFDC2626),
      icon: Icons.report_rounded,
    );
  }
}

MapEntry<String, double> _dominantEntry(Map<String, double> totals) {
  if (totals.isEmpty) return const MapEntry('', 0);
  return totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
}

Future<_DistributionSnapshot> _loadDistributionSnapshot(
  List<PortfolioItem> items,
) async {
  final totals = <String, double>{};

  for (final item in items) {
    try {
      final quote = await MarketRepository.instance.getQuote(
        symbol: item.symbol,
        type: item.type,
      );
      totals[item.type] =
          (totals[item.type] ?? 0) + (item.quantity * quote.currentPrice);
    } catch (_) {
      totals[item.type] = (totals[item.type] ?? 0) + item.totalCost;
    }
  }

  return _DistributionSnapshot.fromTotals(totals);
}

String _dominantAssetType(List<PortfolioItem> items) {
  final totals = <String, double>{};
  for (final item in items) {
    totals[item.type] = (totals[item.type] ?? 0) + item.totalCost;
  }

  if (totals.isEmpty) return 'Veri yok';

  final winner = totals.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );

  return _assetTypeLabel(winner.key);
}

String _assetTypeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'altin':
    case 'altın':
      return 'Altın';
    case 'hisse':
    case 'bist':
      return 'Hisse';
    case 'doviz':
    case 'döviz':
      return 'Döviz';
    case 'fon':
      return 'Fon';
    case 'kripto':
      return 'Kripto';
    case 'endeks':
      return 'Endeks';
    default:
      return type.isEmpty ? 'Diğer' : type;
  }
}

Color _assetTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'altin':
    case 'altın':
      return const Color(0xFFF59E0B);
    case 'hisse':
    case 'bist':
      return const Color(0xFF2563EB);
    case 'doviz':
    case 'döviz':
      return const Color(0xFF16A34A);
    case 'fon':
      return const Color(0xFF7C3AED);
    case 'kripto':
      return const Color(0xFFF97316);
    case 'endeks':
      return const Color(0xFF0F766E);
    default:
      return const Color(0xFF64748B);
  }
}


class _DistributionSnapshot {
  final double totalValue;
  final List<_DistributionSegment> segments;

  const _DistributionSnapshot({
    required this.totalValue,
    required this.segments,
  });

  factory _DistributionSnapshot.fromCost(List<PortfolioItem> items) {
    final totals = <String, double>{};
    for (final item in items) {
      totals[item.type] = (totals[item.type] ?? 0) + item.totalCost;
    }
    return _DistributionSnapshot.fromTotals(totals);
  }

  factory _DistributionSnapshot.fromTotals(Map<String, double> totals) {
    final total = totals.values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      return const _DistributionSnapshot(
        totalValue: 0,
        segments: [
          _DistributionSegment(
            label: 'Diğer',
            ratio: 1,
            color: Color(0xFF64748B),
          ),
        ],
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final segments = entries.take(4).map((entry) {
      return _DistributionSegment(
        label: _assetTypeLabel(entry.key),
        ratio: entry.value / total,
        color: _assetTypeColor(entry.key),
      );
    }).toList();

    return _DistributionSnapshot(totalValue: total, segments: segments);
  }
}

class _DistributionSegment {
  final String label;
  final double ratio;
  final Color color;

  const _DistributionSegment({
    required this.label,
    required this.ratio,
    required this.color,
  });
}

class _SmartInsightsPanel extends StatelessWidget {
  final int refreshTick;

  const _SmartInsightsPanel({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            child: SizedBox(
              height: 138,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const _SurfaceCard(
            child: _EmptyStateLine(
              icon: Icons.psychology_rounded,
              title: 'Akıllı içgörü beklemede',
              subtitle: 'Portföye varlık eklediğinde odak, risk ve aksiyon önerileri oluşacak.',
            ),
          );
        }

        return FutureBuilder<_SmartInsightData>(
          key: ValueKey('smart-insights-$refreshTick-${items.length}'),
          future: _loadSmartInsightData(items),
          builder: (context, insightSnapshot) {
            final data = insightSnapshot.data ?? _SmartInsightData.fromCost(items);
            return SmartInsightsPanel(
              title: data.title,
              message: data.message,
              badge: data.badge,
              actions: data.actions,
              color: data.color,
              icon: data.icon,
            );
          },
        );
      },
    );
  }
}

Future<_SmartInsightData> _loadSmartInsightData(List<PortfolioItem> items) async {
  double totalCost = 0;
  double totalValue = 0;
  final valuesByType = <String, double>{};

  for (final item in items) {
    final cost = item.totalCost;
    double currentValue;

    try {
      final quote = await MarketRepository.instance.getQuote(
        symbol: item.symbol,
        type: item.type,
      );
      currentValue = item.quantity * quote.currentPrice;
    } catch (_) {
      currentValue = cost;
    }

    totalCost += cost;
    totalValue += currentValue;
    valuesByType[item.type] = (valuesByType[item.type] ?? 0) + currentValue;
  }

  return _SmartInsightData.fromValues(
    items: items,
    totalCost: totalCost,
    totalValue: totalValue,
    valuesByType: valuesByType,
  );
}

class _SmartInsightData {
  final String title;
  final String message;
  final String badge;
  final List<String> actions;
  final Color color;
  final IconData icon;

  const _SmartInsightData({
    required this.title,
    required this.message,
    required this.badge,
    required this.actions,
    required this.color,
    required this.icon,
  });

  factory _SmartInsightData.fromCost(List<PortfolioItem> items) {
    final valuesByType = <String, double>{};
    double totalCost = 0;

    for (final item in items) {
      totalCost += item.totalCost;
      valuesByType[item.type] = (valuesByType[item.type] ?? 0) + item.totalCost;
    }

    return _SmartInsightData.fromValues(
      items: items,
      totalCost: totalCost,
      totalValue: totalCost,
      valuesByType: valuesByType,
    );
  }

  factory _SmartInsightData.fromValues({
    required List<PortfolioItem> items,
    required double totalCost,
    required double totalValue,
    required Map<String, double> valuesByType,
  }) {
    final profit = totalValue - totalCost;
    final double profitPercent =
    totalCost <= 0 ? 0.0 : (profit / totalCost) * 100;
    final dominant = _dominantEntry(valuesByType);
    final dominantLabel = dominant.key.isEmpty ? 'Diğer' : _assetTypeLabel(dominant.key);
    final dominantRatio = totalValue <= 0 ? 0 : dominant.value / totalValue;
    final actions = <String>[];

    if (dominantRatio > .60) {
      actions.add('$dominantLabel ağırlığı %${(dominantRatio * 100).toStringAsFixed(0)} seviyesinde. Yeni eklemelerde dengeyi artırmayı düşün.');
    } else {
      actions.add('Dağılım dengeli görünüyor. Mevcut çeşitlendirmeyi koruyarak izlemeye devam et.');
    }

    if (profitPercent >= 5) {
      actions.add('Kâr bölgesi güçlü. En çok yükselen varlıkları ve hedef kâr seviyelerini gözden geçir.');
    } else if (profitPercent <= -5) {
      actions.add('Zarar baskısı oluşmuş. Ortalama maliyet, stop seviyesi ve pozisyon büyüklüğünü yeniden kontrol et.');
    } else {
      actions.add('Performans nötr bölgede. Ani karar yerine piyasa yönünü birkaç gün daha izle.');
    }

    if (items.length < 3) {
      actions.add('Portföyde az sayıda varlık var. Takip listesine yeni alternatifler eklemek riski azaltabilir.');
    } else {
      actions.add('${items.length} varlık izleniyor. Haftalık performans grafiğiyle momentum değişimini karşılaştır.');
    }

    if (profitPercent >= 3 && dominantRatio <= .60) {
      return _SmartInsightData(
        title: 'AI görünümü pozitif',
        message: 'Portföy hem performans hem dağılım açısından sağlıklı sinyal üretiyor.',
        badge: 'Güçlü',
        actions: actions,
        color: const Color(0xFF16A34A),
        icon: Icons.auto_awesome_rounded,
      );
    }

    if (profitPercent <= -4 || dominantRatio > .70) {
      return _SmartInsightData(
        title: 'AI dikkat uyarısı',
        message: '$dominantLabel tarafındaki yoğunluk ve performans birlikte izlenmeli.',
        badge: 'Dikkat',
        actions: actions,
        color: const Color(0xFFDC2626),
        icon: Icons.notification_important_rounded,
      );
    }

    return _SmartInsightData(
      title: 'AI görünümü dengeli',
      message: 'Portföyde net bir alarm yok; takip ve dağılım kontrolü yeterli görünüyor.',
      badge: 'Dengeli',
      actions: actions,
      color: const Color(0xFF008DB9),
      icon: Icons.psychology_rounded,
    );
  }
}




class _WatchlistSection extends StatelessWidget {
  final int refreshTick;

  const _WatchlistSection({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return WatchlistPanel(
      items: const [
        WatchlistItem(
          symbol: 'ASELS',
          name: 'Aselsan',
          price: '₺145,80',
          changePercent: 2.14,
        ),
        WatchlistItem(
          symbol: 'THYAO',
          name: 'Türk Hava Yolları',
          price: '₺318,40',
          changePercent: -0.86,
        ),
        WatchlistItem(
          symbol: 'XAU',
          name: 'Gram Altın',
          price: '₺4.851',
          changePercent: 1.22,
        ),
      ],
    );
  }
}


class _PortfolioList extends StatelessWidget {
  final int refreshTick;
  final List<PortfolioItem>? items;

  const _PortfolioList({required this.refreshTick, this.items});

  @override
  Widget build(BuildContext context) {
    final providedItems = items;
    if (providedItems != null) {
      return _PortfolioListContent(items: providedItems);
    }

    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const _SurfaceCard(
            child: Text(
              'Portföy verisi alınırken bir hata oluştu.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        }

        return _PortfolioListContent(items: snapshot.data ?? []);
      },
    );
  }
}

class _PortfolioListContent extends StatelessWidget {
  final List<PortfolioItem> items;

  const _PortfolioListContent({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SurfaceCard(
        child: Text(
          'Henüz portföy varlığı yok. Yeni Varlık butonuyla ilk varlığını ekleyebilirsin.',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      );
    }

    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _PortfolioAssetTile(item: items[index]),
            if (index != items.length - 1) const _ThinDivider(),
          ],
        ],
      ),
    );
  }
}

class _PortfolioAssetTile extends StatelessWidget {
  final PortfolioItem item;

  const _PortfolioAssetTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.name.isNotEmpty ? item.name : item.symbol;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssetDetailPage(item: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFBAE6FD),
              child: Text(
                item.symbol.isNotEmpty ? item.symbol.characters.first : '?',
                style: const TextStyle(
                  color: Color(0xFF075985),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} adet • ${item.type}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(item.totalCost, item.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alış Birim: ${_formatCurrency(item.averagePrice, item.currency)}',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}


class _PortfolioSummaryCard extends StatelessWidget {
  final PortfolioSummary summary;

  const _PortfolioSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final profitPositive = summary.totalProfit >= 0;
    final profitColor = profitPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final profitPrefix = profitPositive ? '+' : '';

    return _SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.account_balance_wallet_rounded,
                color: Color(0xFF008DB9),
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Portföy Özeti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Canlı fiyat bağlanınca K/Z güncellenecek',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF008DB9).withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${summary.assetCount} varlık',
                  style: const TextStyle(
                    color: Color(0xFF008DB9),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _formatCurrency(summary.totalValue, summary.primaryCurrency),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toplam Yatırım',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: profitColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  profitPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: profitColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$profitPrefix${_formatCurrency(summary.totalProfit.abs(), summary.primaryCurrency)}',
                    style: TextStyle(
                      color: profitColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatPercent(summary.profitPercent),
                  style: TextStyle(
                    color: profitColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PortfolioSummaryMetric(
                  label: 'Toplam Maliyet',
                  value: _formatCurrency(summary.totalCost, summary.primaryCurrency),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PortfolioSummaryMetric(
                  label: 'Beklenen Getiri',
                  value: _formatPercent(summary.profitPercent),
                  valueColor: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioSummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PortfolioSummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: .92,
      children: [
        _QuickAction(
          icon: Icons.add_circle_rounded,
          title: 'Varlık Ekle',
          color: const Color(0xFF008DB9),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddPortfolioItemPage(),
              ),
            );
          },
        ),
        const _QuickAction(icon: Icons.swap_vert_rounded, title: 'İşlem Gir', color: Color(0xFFF97316)),
        const _QuickAction(icon: Icons.notifications_active_rounded, title: 'Alarm Kur', color: Color(0xFF7C3AED)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconBox(icon: icon, color: color, size: 44),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _TransactionRow(symbol: 'ASELS', type: 'Alış', amount: '₺4.586', detail: '10 lot'),
          _ThinDivider(),
          _TransactionRow(symbol: 'THYAO', type: 'Satış', amount: '₺1.562', detail: '5 lot'),
          _ThinDivider(),
          _TransactionRow(symbol: 'Gram Altın', type: 'Alış', amount: '₺4.851', detail: '2 adet'),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String symbol;
  final String type;
  final String amount;
  final String detail;

  const _TransactionRow({
    required this.symbol,
    required this.type,
    required this.amount,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final positive = type == 'Alış';
    final color = positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(.12),
            child: Text(symbol.characters.first,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symbol,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 3),
                Text(type,
                    style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              const SizedBox(height: 3),
              Text(detail,
                  style: const TextStyle(
                      color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
        if (action != null)
          Text(action!,
              style: const TextStyle(
                  color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: size * .56),
    );
  }
}


class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB));
  }
}

class AssetDetailPage extends StatelessWidget {
  final PortfolioItem item;

  const AssetDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final totalCost = item.totalCost;
    final currentPrice = item.averagePrice;
    final currentValue = totalCost;
    final profitLoss = currentValue - totalCost;
    final profitPercent = totalCost <= 0 ? 0.0 : (profitLoss / totalCost) * 100;
    final isProfit = profitLoss >= 0;
    final profitColor = isProfit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final title = item.name.isNotEmpty ? item.name : item.symbol;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(item.symbol),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _SurfaceCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFBAE6FD),
                        child: Text(
                          item.symbol.isNotEmpty ? item.symbol.characters.first : '?',
                          style: const TextStyle(
                            color: Color(0xFF075985),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.symbol} • ${item.type} • ${item.currency}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formatCurrency(currentValue, item.currency),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Güncel değer / canlı veri bağlanana kadar maliyet bazlı',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: profitColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: profitColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${isProfit ? '+' : ''}${_formatCurrency(profitLoss, item.currency)}',
                            style: TextStyle(
                              color: profitColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          _formatPercent(profitPercent),
                          style: TextStyle(
                            color: profitColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SurfaceCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _AssetDetailRow(label: 'Kategori', value: item.type),
                  const _ThinDivider(),
                  _AssetDetailRow(label: 'Miktar / Adet', value: item.quantity.toString()),
                  const _ThinDivider(),
                  _AssetDetailRow(label: 'Alış birim fiyatı', value: _formatCurrency(item.averagePrice, item.currency)),
                  const _ThinDivider(),
                  _AssetDetailRow(label: 'Toplam maliyet', value: _formatCurrency(totalCost, item.currency)),
                  const _ThinDivider(),
                  _AssetDetailRow(label: 'Güncel canlı fiyat', value: 'Piyasa verisi bekleniyor'),
                  const _ThinDivider(),
                  _AssetDetailRow(label: 'Kâr / Zarar', value: '${isProfit ? '+' : ''}${_formatCurrency(profitLoss, item.currency)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _AssetDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portföy'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: PortfolioRepository.instance.watchPortfolio(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: const [
                  _SurfaceCard(
                    child: Text(
                      'Portföy verisi alınırken bir hata oluştu.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            }

            final items = snapshot.data ?? [];

            return FutureBuilder<PortfolioSummary>(
              key: ValueKey('portfolio-summary-${items.length}-${items.fold<double>(0, (sum, item) => sum + item.totalCost)}'),
              future: PortfolioSummaryService.calculate(items),
              builder: (context, summarySnapshot) {
                final summary = summarySnapshot.data ??
                    PortfolioSummaryService.calculateFromCost(items);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    const _SectionTitle(title: 'Portföyüm'),
                    const SizedBox(height: 12),
                    _PortfolioSummaryCard(summary: summary),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Varlıklar'),
                    const SizedBox(height: 12),
                    _PortfolioList(refreshTick: 0, items: items),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddPortfolioItemPage(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Varlık'),
      ),
    );
  }
}






