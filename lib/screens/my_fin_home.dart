import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfin_mobile/screens/intelligence/intelligence_page.dart';
import '../models/dashboard_summary.dart';
import '../models/ai/portfolio_intelligence.dart';
import '../models/portfolio_item.dart';
import '../models/portfolio_performance.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/market_repository.dart';
import '../repositories/portfolio_repository.dart';
import '../services/ai_analysis_service.dart';
import '../services/portfolio_intelligence_service.dart';
import '../services/portfolio_valuation_service.dart';
import '../services/portfolio_performance_service.dart';
import '../services/market/market_favorites_service.dart';
import '../services/market/market_service.dart';
import '../widgets/dashboard/distribution_card.dart';
import '../widgets/dashboard/market_ticker.dart';
import '../widgets/dashboard/portfolio_list.dart';
import '../widgets/dashboard/portfolio_pulse_panel.dart';
import '../widgets/dashboard/smart_insights_panel.dart';
import '../widgets/dashboard/watchlist_panel.dart';
import '../widgets/dashboard/weekly_performance_card.dart';
import 'package:myfin_mobile/auth/login_page.dart';
import 'package:myfin_mobile/screens/intelligence/ai_chat_page.dart';
import 'package:myfin_mobile/services/ai/portfolio_analyzer.dart';
import '../widgets/navigation/myfin_bottom_nav.dart';
import 'transactions/transaction_history_page.dart';
import 'transactions/transaction_detail_page.dart';
import '../widgets/common/surface_card.dart';
import '../widgets/common/section_title.dart';
import '../widgets/common/icon_box.dart';
import '../widgets/common/thin_divider.dart';
import '../widgets/common/empty_state_line.dart';
import '../utils/myfin_formatters.dart';
import 'portfolio/portfolio_page.dart';
import 'portfolio/portfolio_asset_page.dart';
import 'performance/performance_report_page.dart';
import 'performance/profit_loss_detail_page.dart';
import 'market/live_market_page.dart';
import 'settings/settings_page.dart';
import 'transactions/transaction_entry_page.dart';
import '../services/portfolio_summary_service.dart';
import '../utils/no_animation_route.dart';

void _openPortfolioPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(noAnimationRoute(builder: (_) => const PortfolioPage()));
}

void _openPortfolioCategory(BuildContext context, String category) {
  Navigator.of(context).push(
    noAnimationRoute(builder: (_) => PortfolioPage(initialCategory: category)),
  );
}

void _openIntelligencePage(BuildContext context) {
  Navigator.of(
    context,
  ).push(noAnimationRoute(builder: (_) => const IntelligencePage()));
}

void _openPerformanceReportPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(noAnimationRoute(builder: (_) => const PerformanceReportPage()));
}

void _openProfitLossDetailPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(noAnimationRoute(builder: (_) => const ProfitLossDetailPage()));
}

void _openLiveMarketPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(noAnimationRoute(builder: (_) => const LiveMarketPage()));
}

void _openTransactionHistoryPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(noAnimationRoute(builder: (_) => const TransactionHistoryPage()));
}

class MyFinHome extends StatefulWidget {
  final bool showBottomNav;

  const MyFinHome({super.key, this.showBottomNav = true});

  @override
  State<MyFinHome> createState() => _MyFinHomeState();
}

class _MyFinHomeState extends State<MyFinHome> {
  int _refreshTick = 0;

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

              const SizedBox(height: 16),

              _DashboardFadeIn(
                delay: 40,
                child: _MyFinIntelligenceHero(refreshTick: _refreshTick),
              ),

              const SizedBox(height: 16),

              _DashboardFadeIn(
                delay: 80,
                child: _MarketTicker(refreshTick: _refreshTick),
              ),

              const SizedBox(height: 16),

              const _RowQuickActions(),

              const SizedBox(height: 16),

              _KpiGrid(refreshTick: _refreshTick),
              const SizedBox(height: 14),

              const SizedBox(height: 24),
              SectionTitle(
                title: 'Son 7 Gün Performansı',
                action: 'Trend',
                onActionTap: () => _openPerformanceReportPage(context),
              ),
              _WeeklyPerformanceCard(refreshTick: _refreshTick),
              const SizedBox(height: 24),
              SectionTitle(
                title: 'Portföy Dağılımı',
                action: 'Detay',
                onActionTap: () => _openPortfolioPage(context),
              ),
              _DashboardFadeIn(
                delay: 200,
                child: _DistributionCard(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 14),

              const SizedBox(height: 24),
              const SectionTitle(title: 'Portföy Nabzı'),
              _DashboardFadeIn(
                delay: 260,
                child: _PortfolioPulsePanel(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                title: 'Akıllı İçgörüler',
                action: 'AI',
                onActionTap: () => _openIntelligencePage(context),
              ),
              _DashboardFadeIn(
                delay: 320,
                child: _SmartInsightsPanel(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                title: 'Takip Listesi',
                action: 'İzle',
                onActionTap: () => _openLiveMarketPage(context),
              ),
              _DashboardFadeIn(
                delay: 360,
                child: _WatchlistSection(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                title: 'İşlemler',
                action: 'Tümü',
                onActionTap: () => _openTransactionHistoryPage(context),
              ),
              const _RecentTransactions(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: widget.showBottomNav
          ? const MyFinBottomNav(selectedIndex: 0)
          : null,
    );
  }
}

Future<DashboardSummary> _loadDashboardSummary(List<PortfolioItem> items) {
  return DashboardRepository.instance.calculate(items);
}

DashboardSummary _fallbackSummary(List<PortfolioItem> items) {
  final cached = DashboardRepository.instance.peek(items);
  if (cached != null) return cached;

  final totalCost = items.fold<double>(0, (sum, item) => sum + item.totalCost);

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

  final portfolioSnapshot = const PortfolioIntelligenceService().build(items);
  final total = portfolioSnapshot.totalValue;
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
      signals: ['Maliyet bilgisi olmayan varlıklar analize dahil edilemez.'],
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
    final currency = item.currency.trim().isEmpty
        ? 'TRY'
        : item.currency.trim().toUpperCase();
    final country = _inferCountry(item);

    symbolWeights[symbol] = (symbolWeights[symbol] ?? 0) + weight;
    sectorWeights[sector] = (sectorWeights[sector] ?? 0) + weight;
    currencyWeights[currency] = (currencyWeights[currency] ?? 0) + weight;
    countryWeights[country] = (countryWeights[country] ?? 0) + weight;
  }

  final fallbackBiggestPosition = _maxWeight(symbolWeights);
  final biggestPosition = portfolioSnapshot.dominantAssetSymbol.isEmpty
      ? fallbackBiggestPosition
      : MapEntry(
          portfolioSnapshot.dominantAssetSymbol,
          portfolioSnapshot.dominantAssetWeight,
        );
  final topSector = _maxWeight(sectorWeights);
  final topCurrency = _maxWeight(currencyWeights);
  final topCountry = _maxWeight(countryWeights);

  final concentrationPenalty = (biggestPosition.value * 58).round();
  final sectorPenalty = (topSector.value * 24).round();

  final itemBonus = (items.length * 6).clamp(0, 24).round();

  final diversificationScore =
      (100 - concentrationPenalty - sectorPenalty + itemBonus)
          .clamp(0, 100)
          .round();

  final riskScore =
      (34 +
              (biggestPosition.value * 38) +
              (topSector.value * 18) +
              (topCurrency.value > .85 ? 10 : 0) -
              (items.length >= 5 ? 8 : 0))
          .clamp(0, 100)
          .round();

  final sectorScore = (100 - (topSector.value * 52)).clamp(0, 100).round();
  final currencyScore = (100 - (topCurrency.value * 42)).clamp(0, 100).round();

  final overallScore =
      ((diversificationScore * .38) +
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

  if (type.contains('ALTIN') ||
      name.contains('ALTIN') ||
      symbol.contains('GOLD')) {
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

  if (symbol.contains('USD') ||
      symbol.contains('EUR') ||
      type.contains('DÖVİZ')) {
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

class _HomeAIScoreSection extends StatelessWidget {
  final int refreshTick;

  const _HomeAIScoreSection({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SurfaceCard(
            child: SizedBox(
              height: 124,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SurfaceCard(
            child: Text(
              'AI skoru hesaplanırken bir hata oluştu.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }

        final intelligence = _buildPortfolioIntelligence(snapshot.data ?? []);
        return _PortfolioIntelligenceCard(intelligence: intelligence);
      },
    );
  }
}

class _PortfolioIntelligenceCard extends StatelessWidget {
  final _PortfolioIntelligence intelligence;

  const _PortfolioIntelligenceCard({required this.intelligence});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBox(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portföy AI Skoru',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Genel portföy skoru',
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

class _RowQuickActions extends StatelessWidget {
  const _RowQuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeShortcut(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Portföy',
            foreground: const Color(0xFF2563EB),
            gradientColors: const [Color(0xFFDCE7FF), Color(0xFFA9C4FF)],
            onTap: () => _openPortfolioPage(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HomeShortcut(
            icon: Icons.add_rounded,
            label: 'Yeni',
            foreground: const Color(0xFF0369A1),
            gradientColors: const [Color(0xFFDDF4FF), Color(0xFF9CCAE9)],
            onTap: () {
              Navigator.of(context).push(
                noAnimationRoute(
                  builder: (_) =>
                      const TransactionEntryPage(showBottomNav: true),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HomeShortcut(
            icon: Icons.trending_up_rounded,
            label: 'Piyasa',
            foreground: const Color(0xFF16A34A),
            gradientColors: const [Color(0xFFE2FBEA), Color(0xFFA8E3BD)],
            onTap: () => _openLiveMarketPage(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HomeShortcut(
            icon: Icons.receipt_long_rounded,
            label: 'Geçmiş',
            foreground: const Color(0xFFF97316),
            gradientColors: const [Color(0xFFFFEBDD), Color(0xFFFFC79F)],
            onTap: () => _openTransactionHistoryPage(context),
          ),
        ),
      ],
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .72),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: foreground.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: .75),
                    blurRadius: 8,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 7,
                    right: 7,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: .55),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Center(child: Icon(icon, color: foreground, size: 29)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        color: const Color(0xFF7C3AED).withValues(alpha: .1),
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
    final scoreColor = value <= 40
        ? const Color(0xFFDC2626)
        : value <= 70
        ? const Color(0xFFF59E0B)
        : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scoreColor.withValues(alpha: .24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: scoreColor,
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) => _buildHeader(context, snapshot.data),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final isLoggedIn = user != null;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'MyFin kullanıcısı';
    final email = user?.email ?? 'Giriş yapılmadı';

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
          child: const Icon(
            Icons.trending_up_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Finans',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Akıllı yatırım takibi',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Hesap',
          offset: const Offset(0, 52),
          constraints: const BoxConstraints(minWidth: 250, maxWidth: 300),
          onSelected: (value) async {
            if (value == 'settings') {
              Navigator.of(
                context,
              ).push(noAnimationRoute(builder: (_) => const SettingsPage()));
            }

            if (value == 'login') {
              Navigator.of(
                context,
              ).push(noAnimationRoute(builder: (_) => const LoginPage()));
            }

            if (value == 'logout') {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                noAnimationRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFE7F6FB),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF008DB9),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? displayName : 'Misafir kullanıcı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.manage_accounts_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Hesap ayarlarım'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: isLoggedIn ? 'logout' : 'login',
              child: Row(
                children: [
                  Icon(
                    isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(isLoggedIn ? 'Çıkış yap' : 'Giriş yap'),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0F172A),
            child: Icon(
              isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
              color: Colors.white,
            ),
          ),
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

            return _PrimaryDashboardCard(
              totalValueText: formatCurrency(summary.currentValue),
              profitText:
                  '${isPositive ? '+' : ''}${formatCurrency(summary.profitLoss)}',
              profitPercentText: formatPercent(summary.profitPercent),
              isProfit: isPositive,
              onProfitTap: () => _openProfitLossDetailPage(context),
              onTap: () {
                _openPortfolioPage(context);
              },
            );
          },
        );
      },
    );
  }
}

class _PrimaryDashboardCard extends StatelessWidget {
  final String totalValueText;
  final String profitText;
  final String profitPercentText;
  final bool isProfit;
  final VoidCallback onTap;
  final VoidCallback onProfitTap;

  const _PrimaryDashboardCard({
    required this.totalValueText,
    required this.profitText,
    required this.profitPercentText,
    required this.isProfit,
    required this.onTap,
    required this.onProfitTap,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = isProfit
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final trendIcon = isProfit
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF008DB9)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF008DB9).withValues(alpha: .24),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Portföy Özeti',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6,
                        ),
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Toplam Portföy',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .74),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      totalValueText,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onProfitTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(trendIcon, color: trendColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$profitText ($profitPercentText)',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: trendColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: trendColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final int refreshTick;

  const _KpiGrid({required this.refreshTick});

  void _openPortfolio(BuildContext context) {
    Navigator.of(
      context,
    ).push(noAnimationRoute(builder: (_) => const PortfolioPage()));
  }

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
                    title: 'Güncel Değer',
                    value: formatCurrency(summary.currentValue),
                    subtitle: 'Maliyet: ${formatCurrency(summary.totalCost)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () => _openPortfolio(context),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Kâr / Zarar',
                    value:
                        '${isPositive ? '+' : ''}${formatCurrency(summary.profitLoss)}',
                    subtitle: '${formatPercent(summary.profitPercent)} • Detay',
                    icon: isPositive
                        ? Icons.north_east_rounded
                        : Icons.south_east_rounded,
                    color: isPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    onTap: () => _openProfitLossDetailPage(context),
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
                    subtitle: hasItems
                        ? formatPercent(summary.bestPerformance)
                        : 'Veri yok',
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'En Zayıf',
                    value: hasItems ? (summary.worstPerformer ?? '-') : '-',
                    subtitle: hasItems
                        ? formatPercent(summary.worstPerformance)
                        : 'Veri yok',
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
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBox(icon: icon, color: color),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black.withValues(alpha: .24),
                        size: 24,
                      ),
                    ],
                  ],
                ),
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
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          return const SurfaceCard(
            child: SizedBox(
              height: 190,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const SurfaceCard(
            child: EmptyStateLine(
              icon: Icons.show_chart_rounded,
              title: 'Trend grafiği beklemede',
              subtitle:
                  'Portföye varlık eklediğinde 7 günlük performans simülasyonu oluşacak.',
            ),
          );
        }

        final end = DateTime.now();
        final start = end.subtract(const Duration(days: 6));
        return FutureBuilder<PortfolioPerformance>(
          key: ValueKey('weekly-performance-$refreshTick-${items.length}'),
          future: PortfolioPerformanceService.instance.load(
            items: items,
            start: start,
            end: end,
          ),
          builder: (context, performanceSnapshot) {
            final performance = performanceSnapshot.data;
            final hasHistory = performance?.hasHistory ?? false;
            final isPositive = performance?.isPositive ?? true;
            final color = isPositive
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626);

            return WeeklyPerformanceCard(
              title: !hasHistory
                  ? 'Geçmiş oluşturuluyor'
                  : isPositive
                  ? 'Gidişat olumlu'
                  : 'Gidişat zayıflıyor',
              subtitle: hasHistory
                  ? 'Son 7 günün gerçek portföy kapanışları.'
                  : 'İlk günlük kapanış kaydedildi.',
              changeText: formatPercent(performance?.totalReturnPercent ?? 0),
              values: performance?.chartValues ?? const [],
              isPositive: isPositive,
              color: color,
              momentumLabel: performance?.momentumLabel ?? 'Bekleniyor',
              riskLabel: performance?.riskLabel ?? 'Bekleniyor',
              riskColor: _performanceRiskColor(performance),
              dailyLabel: formatPercent(
                performance?.averageDailyReturnPercent ?? 0,
              ),
              hasHistory: hasHistory,
            );
          },
        );
      },
    );
  }
}

Color _performanceRiskColor(PortfolioPerformance? performance) {
  if (performance == null || !performance.hasHistory) {
    return const Color(0xFF64748B);
  }
  if (performance.volatilityPercent >= 3) return const Color(0xFFDC2626);
  if (performance.volatilityPercent >= 1.25) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFF16A34A);
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
    return MarketTicker(
      onTap: () => _openLiveMarketPage(context),
      rows: const [
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
          value: '4.851,00 TL',
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
          return const SurfaceCard(
            child: SizedBox(
              height: 145,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const SurfaceCard(
            child: EmptyStateLine(
              icon: Icons.donut_large_rounded,
              title: 'Dağılım için veri yok',
              subtitle:
                  'Varlık eklediğinde portföy dağılımı otomatik hesaplanacak.',
            ),
          );
        }

        return FutureBuilder<PortfolioValuation>(
          key: ValueKey('distribution-$refreshTick-${items.length}'),
          initialData: PortfolioValuationService.instance.peek(items),
          future: PortfolioValuationService.instance.calculate(
            items,
            forceRefresh: refreshTick > 0,
          ),
          builder: (context, distributionSnapshot) {
            final valuation = distributionSnapshot.data;
            final distribution = valuation == null
                ? _DistributionSnapshot.fromCost(items)
                : _DistributionSnapshot.fromValuation(valuation);
            final performance = _HomeCategoryPerformance.fromValuation(
              valuation,
            );
            return DistributionCard(
              items: distribution.segments
                  .map(
                    (segment) => DistributionItem(
                      label: segment.label,
                      value: segment.ratio * distribution.totalValue,
                      color: segment.color,
                      changePercent: performance[segment.label],
                    ),
                  )
                  .toList(),
              onItemTap: (item) => _openPortfolioCategory(context, item.label),
            );
          },
        );
      },
    );
  }
}

class _HomeCategoryPerformance {
  static Map<String, double> fromValuation(PortfolioValuation? valuation) {
    if (valuation == null) return const {};

    final costs = <String, double>{};
    final currentValues = <String, double>{};
    final hasLivePrice = <String, bool>{};

    for (final itemValuation in valuation.items) {
      final category = _assetTypeLabel(itemValuation.item.type);
      costs[category] =
          (costs[category] ?? 0) + itemValuation.costInBaseCurrency;
      currentValues[category] =
          (currentValues[category] ?? 0) +
          itemValuation.currentValueInBaseCurrency;
      hasLivePrice[category] =
          (hasLivePrice[category] ?? false) || itemValuation.hasLivePrice;
    }

    final result = <String, double>{};
    for (final entry in costs.entries) {
      if (entry.value <= 0 || hasLivePrice[entry.key] != true) continue;
      final currentValue = currentValues[entry.key] ?? entry.value;
      result[entry.key] = ((currentValue - entry.value) / entry.value) * 100;
    }
    return result;
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
        final hasItems = items.isNotEmpty;
        final portfolio = const PortfolioIntelligenceService().build(items);

        final needsAttention =
            hasItems &&
            (portfolio.profitLossPercent < 0 || portfolio.hasDominantType);

        final dominantType = hasItems && portfolio.dominantType.isNotEmpty
            ? _assetTypeLabel(portfolio.dominantType)
            : 'Beklemede';

        return Row(
          children: [
            Expanded(
              child: _MiniInsightCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Akıllı Özet',
                value: hasItems
                    ? (needsAttention ? 'Dikkat gerekli' : 'Pozitif seyir')
                    : 'Hazır',
                subtitle: hasItems
                    ? 'AI Puanı ${_buildPortfolioIntelligence(items).overallScore}/100'
                    : 'İlk varlığı ekleyerek başla',
                color: needsAttention
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
                onTap: () => _openIntelligencePage(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniInsightCard(
                icon: Icons.category_rounded,
                title: 'Yoğunluk',
                value: dominantType,
                subtitle: hasItems
                    ? '${items.length} varlık izleniyor'
                    : 'Veri yok',
                color: const Color(0xFF7C3AED),
                onTap: () => _openPortfolioPage(context),
              ),
            ),
          ],
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
  final VoidCallback? onTap;

  const _MiniInsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                IconBox(icon: icon, color: color, size: 34),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
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
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: color.withValues(alpha: .55),
                  ),
                ],
              ],
            ),
          ),
        ),
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
          return const SurfaceCard(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const SurfaceCard(
            child: EmptyStateLine(
              icon: Icons.monitor_heart_rounded,
              title: 'Portföy nabzı beklemede',
              subtitle:
                  'Varlık ekledikçe risk, yoğunluk ve günlük sinyal burada oluşacak.',
            ),
          );
        }

        final intelligence = _buildPortfolioIntelligence(items);
        final portfolio = const PortfolioIntelligenceService().build(items);
        final pulse = _PulseData.fromIntelligence(
          portfolio: portfolio,
          score: PortfolioAnalyzer.analyze(items).aiScore,
        );

        final dominantType = portfolio.dominantType;
        final dominantAssetCount = items
            .where((item) => _sameAssetCategory(item.type, dominantType))
            .length;

        return InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: dominantType.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    noAnimationRoute(
                      builder: (_) =>
                          PortfolioAssetPage(initialCategory: dominantType),
                    ),
                  );
                },
          child: PortfolioPulsePanel(
            title: pulse.title,
            message: pulse.message,
            score: pulse.score,
            dominantLabel: pulse.dominantLabel,
            assetCount: dominantAssetCount,
            color: pulse.color,
            icon: pulse.icon,
          ),
        );
      },
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

  factory _PulseData.fromIntelligence({
    required PortfolioIntelligence portfolio,
    required int score,
  }) {
    final dominantLabel = portfolio.dominantType.isEmpty
        ? 'Diğer'
        : _assetTypeLabel(portfolio.dominantType);

    final safeScore = score.clamp(0, 100).toDouble();
    final dominantPercent = (portfolio.dominantTypeWeight * 100).round();

    if (safeScore >= 75 && !portfolio.hasDominantType) {
      return _PulseData(
        score: safeScore,
        title: 'Portföy dengesi güçlü',
        message:
            '$dominantLabel ağırlığı kontrol altında. Genel AI görünümü güçlü.',
        dominantLabel: dominantLabel,
        color: const Color(0xFF16A34A),
        icon: Icons.verified_rounded,
      );
    }

    if (safeScore >= 55) {
      return _PulseData(
        score: safeScore,
        title: 'Portföy dengesi izlenmeli',
        message: portfolio.hasDominantType
            ? '$dominantLabel ağırlığı %$dominantPercent seviyesinde. Dağılımı düzenli takip et.'
            : 'Portföy genel olarak izlenebilir seviyede. Yeni alımlarda dengeyi koru.',
        dominantLabel: dominantLabel,
        color: const Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
      );
    }

    return _PulseData(
      score: safeScore,
      title: 'Risk yoğunluğu yüksek',
      message: portfolio.hasDominantType
          ? '$dominantLabel portföyde baskın. Yeni alımlarda çeşitlendirme düşünebilirsin.'
          : 'Portföyde risk sinyali yüksek. Dağılımı ve pozisyon büyüklüklerini gözden geçir.',
      dominantLabel: dominantLabel,
      color: const Color(0xFFDC2626),
      icon: Icons.report_rounded,
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
    final double profitPercent = totalCost <= 0
        ? 0.0
        : (totalProfit / totalCost) * 100;
    double score = 88;
    if (items.length < 3) score -= 14;
    if (dominantRatio > .70) score -= 22;
    if (dominantRatio > .50) score -= 10;
    if (profitPercent < -5) score -= 18;
    if (profitPercent > 5) score += 6;
    score = score.clamp(18, 98).toDouble();

    final dominantLabel = dominant.key.isEmpty
        ? 'Diğer'
        : _assetTypeLabel(dominant.key);

    if (score >= 75) {
      return _PulseData(
        score: score,
        title: 'Portföy dengesi güçlü',
        message:
            '$dominantLabel ağırlığı kontrol altında. Güncel performans ${formatPercent(profitPercent)}.',
        dominantLabel: dominantLabel,
        color: const Color(0xFF16A34A),
        icon: Icons.verified_rounded,
      );
    }

    if (score >= 55) {
      return _PulseData(
        score: score,
        title: 'Portföy dengesi izlenmeli',
        message:
            '$dominantLabel tarafında yoğunluk artıyor. Dağılımı düzenli takip et.',
        dominantLabel: dominantLabel,
        color: const Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
      );
    }

    return _PulseData(
      score: score,
      title: 'Risk yoğunluğu yüksek',
      message:
          '$dominantLabel portföyde baskın. Yeni alımlarda çeşitlendirme düşünebilirsin.',
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

String _normalizedAssetCategory(String type) {
  switch (type.trim().toLowerCase()) {
    case 'altin':
    case 'altın':
      return 'altin';
    case 'hisse':
    case 'bist':
      return 'hisse';
    case 'doviz':
    case 'döviz':
      return 'doviz';
    case 'kripto':
      return 'kripto';
    case 'fon':
      return 'fon';
    case 'endeks':
      return 'endeks';
    default:
      return type.trim().toLowerCase();
  }
}

bool _sameAssetCategory(String first, String second) {
  return _normalizedAssetCategory(first) == _normalizedAssetCategory(second);
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

  factory _DistributionSnapshot.fromValuation(PortfolioValuation valuation) {
    final totals = <String, double>{};

    for (final itemValuation in valuation.items) {
      final category = _assetTypeLabel(itemValuation.item.type);
      totals[category] =
          (totals[category] ?? 0) + itemValuation.currentValueInBaseCurrency;
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
          return const SurfaceCard(
            child: SizedBox(
              height: 138,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const SurfaceCard(
            child: EmptyStateLine(
              icon: Icons.psychology_rounded,
              title: 'Akıllı içgörü beklemede',
              subtitle:
                  'Portföye varlık eklediğinde odak, risk ve aksiyon önerileri oluşacak.',
            ),
          );
        }

        return FutureBuilder<_SmartInsightData>(
          key: ValueKey('smart-insights-$refreshTick-${items.length}'),
          future: _loadSmartInsightData(items),
          builder: (context, insightSnapshot) {
            final data =
                insightSnapshot.data ?? _SmartInsightData.fromCost(items);
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

Future<_SmartInsightData> _loadSmartInsightData(
  List<PortfolioItem> items,
) async {
  final portfolio = const PortfolioIntelligenceService().build(items);
  final intelligence = _buildPortfolioIntelligence(items);

  return _SmartInsightData.fromPortfolio(
    portfolio: portfolio,
    score: intelligence.overallScore,
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
    final portfolio = const PortfolioIntelligenceService().build(items);
    final intelligence = _buildPortfolioIntelligence(items);

    return _SmartInsightData.fromPortfolio(
      portfolio: portfolio,
      score: intelligence.overallScore,
    );
  }

  factory _SmartInsightData.fromPortfolio({
    required PortfolioIntelligence portfolio,
    required int score,
  }) {
    final dominantLabel = portfolio.dominantType.isEmpty
        ? 'Diğer'
        : _assetTypeLabel(portfolio.dominantType);
    final dominantRatio = portfolio.dominantTypeWeight;
    final dominantPercent = (dominantRatio * 100).round();
    final profitPercent = portfolio.profitLossPercent;
    final assetCount = portfolio.assetCount;
    final safeScore = score.clamp(0, 100);
    final actions = <String>[];

    if (dominantRatio > .60) {
      actions.add(
        '$dominantLabel ağırlığı %$dominantPercent seviyesinde. Yeni eklemelerde dengeyi artırmayı düşün.',
      );
    } else {
      actions.add(
        'Dağılım dengeli görünüyor. Mevcut çeşitlendirmeyi koruyarak izlemeye devam et.',
      );
    }

    if (profitPercent >= 5) {
      actions.add(
        'Kâr bölgesi güçlü. En çok yükselen varlıkları ve hedef kâr seviyelerini gözden geçir.',
      );
    } else if (profitPercent <= -5) {
      actions.add(
        'Zarar baskısı oluşmuş. Ortalama maliyet, stop seviyesi ve pozisyon büyüklüğünü yeniden kontrol et.',
      );
    } else {
      actions.add(
        'Performans nötr bölgede. Ani karar yerine piyasa yönünü birkaç gün daha izle.',
      );
    }

    if (assetCount < 3) {
      actions.add(
        'Portföyde az sayıda varlık var. Takip listesine yeni alternatifler eklemek riski azaltabilir.',
      );
    } else {
      actions.add(
        '$assetCount varlık izleniyor. Haftalık performans grafiğiyle gidişat değişimini karşılaştır.',
      );
    }

    if (safeScore >= 75 && !portfolio.hasDominantType && profitPercent >= -4) {
      return _SmartInsightData(
        title: 'AI görünümü pozitif',
        message:
            'Portföy hem performans hem dağılım açısından sağlıklı sinyal üretiyor.',
        badge: 'Güçlü',
        actions: actions,
        color: const Color(0xFF16A34A),
        icon: Icons.auto_awesome_rounded,
      );
    }

    if (safeScore < 60 || profitPercent <= -4 || portfolio.hasDominantType) {
      return _SmartInsightData(
        title: 'AI dikkat uyarısı',
        message:
            '$dominantLabel tarafındaki yoğunluk ve performans birlikte izlenmeli.',
        badge: 'Dikkat',
        actions: actions,
        color: const Color(0xFFDC2626),
        icon: Icons.notification_important_rounded,
      );
    }

    return _SmartInsightData(
      title: 'AI görünümü dengeli',
      message:
          'Portföyde net bir alarm yok; takip ve dağılım kontrolü yeterli görünüyor.',
      badge: 'Dengeli',
      actions: actions,
      color: const Color(0xFF008DB9),
      icon: Icons.psychology_rounded,
    );
  }
}

class _WatchlistSection extends StatefulWidget {
  final int refreshTick;

  const _WatchlistSection({required this.refreshTick});

  @override
  State<_WatchlistSection> createState() => _WatchlistSectionState();
}

class _WatchlistSectionState extends State<_WatchlistSection> {
  Future<List<WatchlistItem>>? _itemsFuture;
  String? _fingerprint;

  Future<List<WatchlistItem>> _itemsFor(List<FavoriteMarketAsset> favorites) {
    final fingerprint = [
      widget.refreshTick,
      ...favorites.map((favorite) => favorite.asset.symbol),
    ].join('|');

    if (_itemsFuture != null && _fingerprint == fingerprint) {
      return _itemsFuture!;
    }

    _fingerprint = fingerprint;
    return _itemsFuture = Future.wait(
      favorites.map((favorite) async {
        var quote = favorite.lastQuote;
        try {
          quote = await MarketService.instance.getQuote(
            favorite.asset.symbol,
            exchange: favorite.asset.exchange,
            forceRefresh: widget.refreshTick > 0,
          );
        } catch (_) {
          // Son başarılı fiyat varsa kartta gösterilmeye devam edilir.
        }

        return WatchlistItem(
          symbol: favorite.asset.symbol,
          name: favorite.asset.name,
          price: quote == null
              ? 'Veri yok'
              : formatCurrency(quote.price, quote.currency),
          changePercent: quote?.changePercent ?? 0,
          hasLiveData: quote != null,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<FavoriteMarketAsset>>(
      valueListenable: MarketFavoritesService.instance.favorites,
      builder: (context, favorites, child) {
        if (favorites.isEmpty) {
          return const WatchlistPanel(items: []);
        }

        return FutureBuilder<List<WatchlistItem>>(
          future: _itemsFor(favorites),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const WatchlistPanel(items: [], isLoading: true);
            }
            return WatchlistPanel(
              items: snapshot.data!.take(3).toList(growable: false),
            );
          },
        );
      },
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '-';
    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PortfolioRepository.instance.watchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SurfaceCard(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SurfaceCard(
            padding: EdgeInsets.all(18),
            child: Text(
              'Son işlemler alınırken bir sorun oluştu.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }

        final transactions = snapshot.data?.docs ?? [];

        if (transactions.isEmpty) {
          return SurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF008DB9).withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF008DB9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Henüz işlem yok',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Alış veya satış işlemi eklediğinde burada görünecek.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        noAnimationRoute(
                          builder: (_) =>
                              const TransactionEntryPage(showBottomNav: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Yeni İşlem'),
                  ),
                ),
              ],
            ),
          );
        }

        final recentTransactions = transactions.take(3).toList(growable: false);
        final List<Widget> rows = <Widget>[];

        for (int index = 0; index < recentTransactions.length; index++) {
          final transaction = recentTransactions[index];
          final data = transaction.data();
          final symbol = (data['symbol'] ?? '-').toString();
          final assetName = (data['assetName'] ?? '').toString();
          final type = (data['type'] ?? '-').toString();
          final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
          final total = (data['total'] as num?)?.toDouble() ?? 0;
          final currency = (data['currency'] ?? 'TRY').toString();
          final formattedDate = _formatDate(
            data['transactionDate'] ?? data['createdAt'],
          );

          rows.add(
            _TransactionRow(
              symbol: assetName.isEmpty || assetName == symbol
                  ? symbol
                  : '$symbol • $assetName',
              type: type,
              amount: formatCurrency(total, currency),
              detail: '${formatQuantity(quantity)} adet • $formattedDate',
              isSell: type == 'Satış',
              onTap: () {
                Navigator.of(context).push(
                  noAnimationRoute(
                    builder: (_) => TransactionDetailPage(
                      transactionId: transaction.id,
                      data: data,
                      formattedDate: formattedDate,
                    ),
                  ),
                );
              },
            ),
          );

          if (index != recentTransactions.length - 1) {
            rows.add(const ThinDivider());
          }
        }

        return SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(children: rows),
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String symbol;
  final String type;
  final String amount;
  final String detail;
  final bool isSell;
  final VoidCallback? onTap;

  const _TransactionRow({
    required this.symbol,
    required this.type,
    required this.amount,
    required this.detail,
    required this.isSell,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final String avatarText = symbol.trim().isEmpty
        ? '?'
        : symbol.characters.first;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: .12),
              child: Text(
                avatarText,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyFinIntelligenceHero extends StatefulWidget {
  final int refreshTick;

  const _MyFinIntelligenceHero({required this.refreshTick});

  @override
  State<_MyFinIntelligenceHero> createState() => _MyFinIntelligenceHeroState();
}

class _MyFinIntelligenceHeroState extends State<_MyFinIntelligenceHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) {
    if (score <= 40) return const Color(0xFFDC2626);
    if (score <= 70) return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final intelligence = _buildPortfolioIntelligence(items);
        final analysis = PortfolioAnalyzer.analyze(items);
        final aiScore = analysis.aiScore;
        final scoreColor = _scoreColor(aiScore);

        final summary = items.isEmpty
            ? 'İlk varlığını eklediğinde MyFin portföyünü analiz etmeye başlayacak.'
            : intelligence.summary;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _openIntelligencePage(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .055),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final glow = .12 + (_controller.value * .18);
                          return Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF0EA5E9)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: glow),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'MyFin Intelligence',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.15,
                                height: 1.24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$aiScore/100',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 72),
                    child: Text(
                      'AI destekli portföy merkezi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push(
                                noAnimationRoute(
                                  builder: (_) => AiChatPage(
                                    analysis: analysis,
                                    portfolioItems: items,
                                  ),
                                ),
                              );
                            },
                            child: Ink(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0F172A),
                                    Color(0xFF008DB9),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF008DB9,
                                    ).withValues(alpha: .24),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PulsingAiGlowIcon(),
                                    SizedBox(width: 10),
                                    Text(
                                      "MyFin AI'ye Sor",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// "MyFin AI'ye Sor" butonundaki yıldız ikonunun etrafında yumuşak,
/// nabız gibi atan (pulsing) sarı bir AI ışıltısı oluşturan widget.
class _PulsingAiGlowIcon extends StatefulWidget {
  const _PulsingAiGlowIcon();

  @override
  State<_PulsingAiGlowIcon> createState() => _PulsingAiGlowIconState();
}

class _PulsingAiGlowIconState extends State<_PulsingAiGlowIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double glowStrength = 0.30 + (_controller.value * 0.35);
        final double scale = 1.0 + (_controller.value * 0.10);

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withOpacity(glowStrength),
                blurRadius: 22,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFFF5A623),
        size: 22,
      ),
    );
  }
}
