import 'dart:async';
import 'dart:math' as math;
import '../services/market_asset_catalog_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfin_mobile/screens/intelligence/intelligence_page.dart';
import 'package:myfin_mobile/services/portfolio_summary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_summary.dart';
import '../models/ai/portfolio_intelligence.dart';
import '../models/portfolio_item.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/market_repository.dart';
import '../repositories/portfolio_repository.dart';
import '../services/ai_analysis_service.dart';
import '../services/portfolio_intelligence_service.dart';
import '../widgets/dashboard/distribution_card.dart';
import '../widgets/dashboard/market_ticker.dart';
import '../widgets/dashboard/portfolio_list.dart';
import '../widgets/dashboard/portfolio_pulse_panel.dart';
import '../widgets/dashboard/smart_insights_panel.dart';
import '../widgets/dashboard/watchlist_panel.dart';
import '../widgets/dashboard/weekly_performance_card.dart';
import 'add_portfolio_item_page.dart';
import 'package:myfin_mobile/auth/login_page.dart';
import 'package:myfin_mobile/screens/intelligence/ai_chat_page.dart';
import 'package:myfin_mobile/services/ai/portfolio_analyzer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/portfolio_rebuild_service.dart';
import '../widgets/navigation/myfin_bottom_nav.dart';
void _openPortfolioPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PortfolioPage()),
  );
}

void _openIntelligencePage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const IntelligencePage()),
  );
}

void _openPerformanceReportPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PerformanceReportPage()),
  );
}

void _openLiveMarketPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LiveMarketPage()),
  );
}

void _openTransactionHistoryPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
  );
}

class MyFinHome extends StatefulWidget {
  const MyFinHome({super.key});

  @override
  State<MyFinHome> createState() => _MyFinHomeState();
}

class _MyFinHomeState extends State<MyFinHome> {
 
  int _refreshTick = 0;

  @override
void initState() {
  super.initState();
}

  @override
  void dispose() {
   
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

const SizedBox(height: 16),

const _RowQuickActions(),

const SizedBox(height: 16),


_DashboardFadeIn(
  delay: 40,
  child: _MyFinIntelligenceHero(

    refreshTick: _refreshTick,

  ),

),

const SizedBox(height: 16),
_KpiGrid(refreshTick: _refreshTick),
              const SizedBox(height: 14),
              
              const SizedBox(height: 24),
              _SectionTitle(title: 'Son 7 Gün Performansı', action: 'Trend', onActionTap: () => _openPerformanceReportPage(context)),
              _WeeklyPerformanceCard(refreshTick: _refreshTick),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Canlı Piyasa', action: 'Tümü', onActionTap: () => _openLiveMarketPage(context)),
              _DashboardFadeIn(
                delay: 140,
                child: _MarketTicker(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Portföy Dağılımı', action: 'Detay', onActionTap: () => _openPortfolioPage(context)),
              _DashboardFadeIn(
                delay: 200,
                child: _DistributionCard(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 14),
             
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Portföy Nabzı'),
              _DashboardFadeIn(
                delay: 260,
                child: _PortfolioPulsePanel(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
  title: 'Akıllı İçgörüler',
  action: 'AI',
  onActionTap: () => _openIntelligencePage(context),
),
_DashboardFadeIn(
  delay: 320,
  child: _SmartInsightsPanel(refreshTick: _refreshTick),
),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Takip Listesi', action: 'İzle', onActionTap: () => _openLiveMarketPage(context)),
              _DashboardFadeIn(
                delay: 360,
                child: _WatchlistSection(refreshTick: _refreshTick),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Hızlı İşlemler'),
              const _QuickActions(),
              const SizedBox(height: 24),
              _SectionTitle(title: 'İşlemler', action: 'Tümü', onActionTap: () => _openTransactionHistoryPage(context)),
              const _RecentTransactions(),
            ],
          ),
        ),
      ),
    
   bottomNavigationBar: const MyFinBottomNav(selectedIndex: 0),
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
  final normalizedCurrency =
      currency.trim().isEmpty ? 'TRY' : currency.trim().toUpperCase();
  final formattedValue = _formatTurkishDecimal(value);

  if (normalizedCurrency == 'TRY') {
    return '$formattedValue TL';
  }

  return '$formattedValue $normalizedCurrency';
}
String _formatPercent(double value) {

  final prefix = value >= 0 ? '+' : '';

  return '$prefix${value.toStringAsFixed(2).replaceAll('.', ',')}%';

}
String _formatTurkishDecimal(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final decimal = parts.length > 1 ? parts.last : '00';

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${isNegative ? '-' : ''}${buffer.toString()},$decimal';
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value
      .toStringAsFixed(4)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll('.', ',');
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

class _HomeAIScoreSection extends StatelessWidget {
  final int refreshTick;

  const _HomeAIScoreSection({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            child: SizedBox(
              height: 124,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _SurfaceCard(
            child: Text(
              'AI skoru hesaplanırken bir hata oluştu.',
              style: TextStyle(fontWeight: FontWeight.w700),
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
                      'Portföy AI Skoru',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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
          child: _QuickMiniAction(
            icon: Icons.add_circle_outline_rounded,
            title: 'Yeni İşlem',
            subtitle: '',
            color: const Color(0xFF008DB9),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TransactionEntryPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickMiniAction(
            icon: Icons.receipt_long_rounded,
            title: 'İşlemler',
            subtitle: '',
            color: const Color(0xFFF97316),
            onTap: () => _openTransactionHistoryPage(context),
          ),
        ),
      ],
    );
  }
}

class _QuickMiniAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickMiniAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: _SurfaceCard(
        child: SizedBox(
          height: 46,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IconBox(
                icon: icon,
                color: color,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              fontWeight: FontWeight.w700,
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
    final user = FirebaseAuth.instance.currentUser;
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
        PopupMenuButton<String>(
          tooltip: 'Hesap',
          offset: const Offset(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          onSelected: (value) async {
            if (value == 'settings') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            }

            if (value == 'login') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }

            if (value == 'logout') {
              await FirebaseAuth.instance.signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? displayName : 'Misafir kullanıcı',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
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
                  Icon(isLoggedIn ? Icons.logout_rounded : Icons.login_rounded, size: 20),
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
              totalValueText: _formatCurrency(summary.currentValue),
              profitText:
                  '${isPositive ? '+' : ''}${_formatCurrency(summary.profitLoss)}',
              profitPercentText: _formatPercent(summary.profitPercent),
              isProfit: isPositive,
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

  const _PrimaryDashboardCard({
    required this.totalValueText,
    required this.profitText,
    required this.profitPercentText,
    required this.isProfit,
    required this.onTap,
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
              colors: [
                Color(0xFF0F172A),
                Color(0xFF008DB9),
              ],
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
                    fontWeight: FontWeight.w700,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$profitText ($profitPercentText)',
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PortfolioPage(),
      ),
    );
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
                    value: _formatCurrency(summary.currentValue),
                    subtitle: 'Maliyet: ${_formatCurrency(summary.totalCost)}',
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
        '${isPositive ? '+' : ''}${_formatCurrency(summary.profitLoss)}',
    subtitle: '${_formatPercent(summary.profitPercent)} • Detay',
    icon: isPositive
        ? Icons.north_east_rounded
        : Icons.south_east_rounded,
    color: isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626),
        onTap: () => _openPortfolio(context),
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
    return _SurfaceCard(
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
                    _IconBox(icon: icon, color: color),
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
      title: change >= 0 ? 'Gidişat olumlu' : 'Gidişat zayıflıyor',
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
        final hasItems = items.isNotEmpty;
        final portfolio = const PortfolioIntelligenceService().build(items);

        final needsAttention =
            hasItems && (portfolio.profitLossPercent < 0 || portfolio.hasDominantType);

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
                onTap: () {
  final analysis = PortfolioAnalyzer.analyze(items);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AiChatPage(analysis: analysis),
    ),
  );
},
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
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  ),
  child: Row(
    children: [
      _IconBox(
        icon: icon,
        color: color,
        size: 34,
      ),
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
                  Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: .55)),
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

        final intelligence = _buildPortfolioIntelligence(items);
        final portfolio = const PortfolioIntelligenceService().build(items);
        final pulse = _PulseData.fromIntelligence(
          portfolio: portfolio,
         score: PortfolioAnalyzer.analyze(items).aiScore,
        );

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
        message: '$dominantLabel ağırlığı kontrol altında. Genel AI görünümü güçlü.',
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
  // Keep portfolio allocation aligned with the rest of the dashboard.
  //
  // Portfolio Pulse, Smart Summary and Smart Insights all use cost-based
  // portfolio intelligence today. Using live market quotes here caused the
  // allocation card to show a different dominant weight for the same portfolio.
  return _DistributionSnapshot.fromCost(items);
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
      actions.add('$dominantLabel ağırlığı %$dominantPercent seviyesinde. Yeni eklemelerde dengeyi artırmayı düşün.');
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

    if (assetCount < 3) {
      actions.add('Portföyde az sayıda varlık var. Takip listesine yeni alternatifler eklemek riski azaltabilir.');
    } else {
      actions.add('$assetCount varlık izleniyor. Haftalık performans grafiğiyle gidişat değişimini karşılaştır.');
    }

    if (safeScore >= 75 && !portfolio.hasDominantType && profitPercent >= -4) {
      return _SmartInsightData(
        title: 'AI görünümü pozitif',
        message: 'Portföy hem performans hem dağılım açısından sağlıklı sinyal üretiyor.',
        badge: 'Güçlü',
        actions: actions,
        color: const Color(0xFF16A34A),
        icon: Icons.auto_awesome_rounded,
      );
    }

    if (safeScore < 60 || profitPercent <= -4 || portfolio.hasDominantType) {
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
          price: '145,80 TL',
          changePercent: 2.14,
        ),
        WatchlistItem(
          symbol: 'THYAO',
          name: 'Türk Hava Yolları',
          price: '318,40 TL',
          changePercent: -0.86,
        ),
        WatchlistItem(
          symbol: 'XAU',
          name: 'Gram Altın',
          price: '4.851,00 TL',
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFBAE6FD),
              child: Text(
                item.symbol.isNotEmpty ? item.symbol.characters.first : '?',
                style: const TextStyle(
                  color: Color(0xFF075985),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatQuantity(item.quantity)} adet • ${item.type}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Alış: ${_formatCurrency(item.averagePrice, item.currency)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
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
                  'Maliyet',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
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
                  color: const Color(0xFF008DB9).withValues(alpha: .10),
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
              color: profitColor.withValues(alpha: .10),
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
          title: 'Yeni İşlem',
          color: const Color(0xFF008DB9),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionEntryPage(),
              ),
            );
          },
        ),
        _QuickAction(
          icon: Icons.swap_vert_rounded,
          title: 'İşlem Gir',
          color: const Color(0xFFF97316),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionEntryPage(),
              ),
            );
          },
        ),
        _QuickAction(
          icon: Icons.notifications_active_rounded,
          title: 'Alarm Kur',
          color: const Color(0xFF7C3AED),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PriceAlertPage(),
              ),
            );
          },
        ),
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
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SurfaceCard(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const _SurfaceCard(
            padding: EdgeInsets.all(18),
            child: Text(
              'Son işlemler alınırken bir sorun oluştu.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }

        final List<PortfolioItem> items = snapshot.data ?? <PortfolioItem>[];

        if (items.isEmpty) {
          return _SurfaceCard(
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
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'İlk varlığını eklediğinde burada görünecek.',
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
                        MaterialPageRoute(
                          builder: (_) => const TransactionEntryPage(),
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

        final List<PortfolioItem> recentItems = items.reversed.take(3).toList();
        final List<Widget> rows = <Widget>[];

        for (int index = 0; index < recentItems.length; index++) {
          final PortfolioItem item = recentItems[index];
          rows.add(
            _TransactionRow(
              symbol: item.symbol.trim().isEmpty ? item.name : item.symbol.trim().toUpperCase(),
              type: 'Portföy Girişi',
              amount: _formatCurrency(item.totalCost, item.currency),
              detail: '${_formatQuantity(item.quantity)} adet • ${item.type}',
            ),
          );

          if (index != recentItems.length - 1) {
            rows.add(const _ThinDivider());
          }
        }

        return _SurfaceCard(
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

  const _TransactionRow({
    required this.symbol,
    required this.type,
    required this.amount,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    const Color color = Color(0xFF008DB9);
    final String avatarText = symbol.trim().isEmpty ? '?' : symbol.characters.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .12),
            child: Text(
              avatarText,
              style: const TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type,
                  style: const TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ),
        if (action != null)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onActionTap != null) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
            color: Colors.black.withValues(alpha: .045),
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
        color: color.withValues(alpha: .12),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
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
                      color: profitColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isProfit
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
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
                  _AssetDetailRow(
                    label: 'Miktar / Adet',
                    value: item.quantity.toString(),
                  ),
                  const _ThinDivider(),
                  _AssetDetailRow(
                    label: 'Alış birim fiyatı',
                    value: _formatCurrency(item.averagePrice, item.currency),
                  ),
                  const _ThinDivider(),
                  _AssetDetailRow(
                    label: 'Toplam maliyet',
                    value: _formatCurrency(totalCost, item.currency),
                  ),
                  const _ThinDivider(),
                  _AssetDetailRow(
                    label: 'Güncel canlı fiyat',
                    value: 'Piyasa verisi bekleniyor',
                  ),
                  const _ThinDivider(),
                  _AssetDetailRow(
                    label: 'Kâr / Zarar',
                    value:
                        '${isProfit ? '+' : ''}${_formatCurrency(profitLoss, item.currency)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 1,
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
              key: ValueKey(
                'portfolio-summary-${items.length}-${items.fold<double>(0, (sum, item) => sum + item.totalCost)}',
              ),
              future: PortfolioSummaryService.calculate(items),
              builder: (context, summarySnapshot) {
                final summary = summarySnapshot.data ??
                    PortfolioSummaryService.calculateFromCost(items);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    const _SectionTitle(title: 'Portföyüm'),
                    const SizedBox(height: 12),
                    _DistributionCard(refreshTick: items.length),
                    const SizedBox(height: 14),
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
              builder: (_) => const TransactionEntryPage(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni İşlem'),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 1,
      ),
    );
  }
}

class PerformanceReportPage extends StatefulWidget {
  const PerformanceReportPage({super.key});

  @override
  State<PerformanceReportPage> createState() =>
      _PerformanceReportPageState();
}

class _PerformanceReportPageState
    extends State<PerformanceReportPage> {
  String _range = '7 Gün';

  static const List<String> _ranges = [
    'Bugün',
    '3 Gün',
    '7 Gün',
    '1 Ay',
    'Özel',
  ];

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
                    const _SectionTitle(title: 'Performans'),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _ranges.map((range) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: 8),
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
                      changeText:
                          _formatPercent(trend.totalChange),
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

                    _SurfaceCard(
                      child: Column(
                        children: [
                          _ReportRow(
                            label: 'Toplam Portföy',
                            value: _formatCurrency(
                              summary.currentValue,
                            ),
                          ),
                          _ReportRow(
                            label: 'Toplam Kâr / Zarar',
                            value:
                                '${summary.profitLoss >= 0 ? '+' : ''}${_formatCurrency(summary.profitLoss)}',
                          ),
                          _ReportRow(
                            label: 'Getiri Oranı',
                            value: _formatPercent(
                              summary.profitPercent,
                            ),
                          ),
                          _ReportRow(
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

class LiveMarketPage extends StatefulWidget {
  const LiveMarketPage({super.key});

  @override
  State<LiveMarketPage> createState() => _LiveMarketPageState();
}

class _LiveMarketPageState extends State<LiveMarketPage> {
  final Set<String> _favorites = <String>{'XAU'};
  String _category = 'Tümü';

  static const List<String> _categories = ['Tümü', 'Altın', 'Döviz', 'BIST'];

  static const List<_MarketAsset> _assets = [
    _MarketAsset(
      category: 'Döviz',
      symbol: 'USDTRY',
      name: 'USD / TRY',
      price: '39,82',
      change: '+0,18%',
      positive: true,
    ),
    _MarketAsset(
      category: 'Döviz',
      symbol: 'EURTRY',
      name: 'EUR / TRY',
      price: '46,73',
      change: '+0,09%',
      positive: true,
    ),
    _MarketAsset(
      category: 'Altın',
      symbol: 'XAU',
      name: 'Gram Altın',
      price: '4.851,00 TL',
      change: '-0,12%',
      positive: false,
    ),
    _MarketAsset(
      category: 'BIST',
      symbol: 'XU100',
      name: 'BIST 100',
      price: '10.421',
      change: '+1,34%',
      positive: true,
    ),
    _MarketAsset(
      category: 'BIST',
      symbol: 'ASELS',
      name: 'Aselsan',
      price: '145,80 TL',
      change: '+2,14%',
      positive: true,
    ),
    _MarketAsset(
      category: 'BIST',
      symbol: 'THYAO',
      name: 'Türk Hava Yolları',
      price: '318,40 TL',
      change: '-0,86%',
      positive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final assets = _category == 'Tümü'
        ? _assets
        : _assets.where((asset) => asset.category == _category).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Piyasa'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const _SectionTitle(title: 'Piyasa'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < assets.length; i++) ...[
                    _MarketAssetRow(
                      asset: assets[i],
                      favorite: _favorites.contains(assets[i].symbol),
                      onFavorite: () {
                        setState(() {
                          if (!_favorites.add(assets[i].symbol)) {
                            _favorites.remove(assets[i].symbol);
                          }
                        });
                      },
                    ),
                    if (i != assets.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 0,
      ),
    );
  }
}
class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day.$month.${date.year}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemler'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: PortfolioRepository.instance.watchTransactions(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                const _SectionTitle(title: 'İşlem Geçmişi'),
                const SizedBox(height: 12),
                _SurfaceCard(
                  child: Text(
                    docs.isEmpty
                        ? 'Henüz işlem kaydı yok. Alış veya satış işlemi girdiğinde burada görünecek.'
                        : '${docs.length} işlem kaydı bulundu.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (final doc in docs)
                  _TransactionHistoryTile(
                    transactionId: doc.id,
                    data: doc.data(),
                    formattedDate: _formatDate(
                      doc.data()['transactionDate'] ?? doc.data()['createdAt'],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 2,
      ),
    );
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String formattedDate;
  final String transactionId;

  const _TransactionHistoryTile({
    required this.data,
    required this.formattedDate,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = (data['symbol'] ?? '-').toString();
    final assetName = (data['assetName'] ?? '').toString();
    final type = (data['type'] ?? '-').toString();
    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final currency = (data['currency'] ?? 'TRY').toString();

    final isSell = type == 'Satış';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon = isSell ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailPage(
                transactionId: transactionId,
                data: data,
                formattedDate: formattedDate,
              ),
            ),
          );
        },
        child: _SurfaceCard(
          child: Row(
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assetName.isEmpty || assetName == symbol
                          ? symbol
                          : '$symbol • $assetName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type • ${_formatQuantity(quantity)} adet • Birim: ${_formatCurrency(price, currency)} • $formattedDate',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(total, currency),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'İşlem Tutarı',
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class TransactionDetailPage extends StatelessWidget {
  final String transactionId;
  final Map<String, dynamic> data;
  final String formattedDate;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    required this.data,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = (data['symbol'] ?? '-').toString();
    final assetName = (data['assetName'] ?? '').toString();
    final type = (data['type'] ?? '-').toString();
    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final currency = (data['currency'] ?? 'TRY').toString();
    final note = (data['note'] ?? '').toString();

    final isSell = type == 'Satış';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Detayı'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetName.isEmpty || assetName == symbol
                        ? symbol
                        : '$symbol • $assetName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ReportRow(
                    label: 'Adet / Miktar',
                    value: _formatQuantity(quantity),
                  ),
                  _ReportRow(
                    label: 'Birim Fiyat',
                    value: _formatCurrency(price, currency),
                  ),
                  _ReportRow(
                    label: 'İşlem Tutarı',
                    value: _formatCurrency(total, currency),
                  ),
                  _ReportRow(label: 'Para Birimi', value: currency),
                  _ReportRow(label: 'İşlem Tarihi', value: formattedDate),
                  if (note.isNotEmpty)
                    _ReportRow(label: 'Not', value: note),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionEntryPage(
                      transactionId: transactionId,
                      transactionData: data,
                      formattedDate: formattedDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('İşlemi Düzenle'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('İşlemi Sil'),
                    content: const Text(
                      'Bu işlem kalıcı olarak silinecek.\n\nDevam etmek istiyor musun?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );

                if (result != true) return;

                await PortfolioRepository.instance
                    .deleteTransaction(transactionId);

                await PortfolioRebuildService()
                    .rebuildFromTransactions();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İşlem silindi.'),
                  ),
                );

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('İşlemi Sil'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 2,
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
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
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
class _MarketAsset {
  final String category;
  final String symbol;
  final String name;
  final String price;
  final String change;
  final bool positive;

  const _MarketAsset({
    required this.category,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.positive,
  });
}

class _MarketAssetRow extends StatelessWidget {
  final _MarketAsset asset;
  final bool favorite;
  final VoidCallback onFavorite;

  const _MarketAssetRow({
    required this.asset,
    required this.favorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final color = asset.positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: favorite ? const Color(0xFFF59E0B) : Colors.black26,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.symbol, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(asset.name, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(asset.price, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 3),
              Text(asset.change, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class TransactionEntryPage extends StatefulWidget {
  final String? transactionId;
  final Map<String, dynamic>? transactionData;
  final String? formattedDate;

  const TransactionEntryPage({
    super.key,
    this.transactionId,
    this.transactionData,
    this.formattedDate,
  });

  bool get isEdit => transactionId != null && transactionData != null;

  @override
  State<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _TransactionEntryPageState extends State<TransactionEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _assetSearchController = TextEditingController();
final _catalogService = const MarketAssetCatalogService();

List<MarketAsset> _suggestions = const [];
bool _isSearching = false;

String _assetName = '';
String _assetType = 'Hisse';
  final _noteController = TextEditingController();

  String _transactionType = 'Alış';
  String _currency = 'TRY';
  DateTime _transactionDate = DateTime.now();
  @override

void initState() {

  super.initState();

  final data = widget.transactionData;

  if (data == null) return;

  final symbol = (data['symbol'] ?? '').toString();

  final assetName = (data['assetName'] ?? '').toString();

  final type = (data['type'] ?? 'Alış').toString();

  final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;

  final price = (data['price'] as num?)?.toDouble() ?? 0;

  final currency = (data['currency'] ?? 'TRY').toString();

  final note = (data['note'] ?? '').toString();

  _transactionType = type;

  _currency = currency;

  _assetName = assetName;
_assetType = (data['assetType'] ?? _assetType).toString();
  _symbolController.text = symbol;

  _assetSearchController.text =

      assetName.isEmpty || assetName == symbol ? symbol : '$symbol • $assetName';

  _quantityController.text = _formatQuantity(quantity);

  _priceController.text = price.toString().replaceAll('.', ',');

  _noteController.text = note;

  final rawDate = data['transactionDate'];

  if (rawDate is Timestamp) {

    _transactionDate = rawDate.toDate();

  }

}
  @override
void dispose() {
  _assetSearchController.dispose(); 

  _symbolController.dispose();
  _quantityController.dispose();
  _priceController.dispose();
  _noteController.dispose();

  super.dispose();
}
Future<void> _searchAssets(String value) async {
  final query = value.trim();

  if (query.length < 2) {
    setState(() => _suggestions = const []);
    return;
  }

  setState(() => _isSearching = true);

  final results = await _catalogService.search(
  query: query,
);

  if (!mounted) return;

  setState(() {
    _suggestions = results;
    _isSearching = false;
  });
}

void _selectAsset(MarketAsset asset) {
  setState(() {
    _symbolController.text = asset.symbol;
    _assetSearchController.text = '${asset.symbol} • ${asset.name}';
    _assetName = asset.name;
    _assetType = asset.type;
    _currency = asset.currency;
    _suggestions = const [];
  });

  FocusScope.of(context).unfocus();
}
  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked == null) return;

    setState(() => _transactionDate = picked);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final quantity = _parseDouble(_quantityController.text);
    final price = _parseDouble(_priceController.text);
final resolvedAssetType = _resolveAssetType(symbol, _assetType);
final resolvedAssetName =
    _assetName.trim().isEmpty ? _resolveAssetName(symbol) : _assetName.trim();
    try {
      final items = await PortfolioRepository.instance.watchPortfolio().first;
      if (widget.isEdit) {
  await PortfolioRepository.instance.updateTransaction(
  widget.transactionId!,
  {
    'symbol': symbol,
    'assetName': _assetName.isEmpty ? symbol : _assetName,
    'assetType': _assetType,
    'type': _transactionType,
    'quantity': quantity,
    'price': price,
    'total': quantity * price,
    'currency': _currency,
    'transactionDate': Timestamp.fromDate(_transactionDate),
    'note': _noteController.text.trim(),
  },
);

await PortfolioRebuildService().rebuildFromTransactions();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('İşlem güncellendi.')),
  );

  Navigator.of(context).pop();
  Navigator.of(context).pop();
  return;
}
      PortfolioItem? existingItem;
      for (final item in items) {
       final itemSymbol = item.symbol.trim().toUpperCase();
final itemName = item.name.trim().toUpperCase();

if (itemSymbol == symbol || itemName == symbol || itemName == _assetName.trim().toUpperCase()) {
  existingItem = item;
  break;
} 
      }

      if (_transactionType == 'Alış') {
        if (existingItem == null) {
          await PortfolioRepository.instance.addPortfolioItem(
         PortfolioItem(
  id: '',
  name: resolvedAssetName,
  symbol: symbol,
  type: resolvedAssetType,  

  quantity: quantity,

  averagePrice: price,

  currency: _currency,

),
          );
        } else {
          final oldTotalCost = existingItem.totalCost;
          final newTotalCost = quantity * price;
          final newQuantity = existingItem.quantity + quantity;
          final newAveragePrice = (oldTotalCost + newTotalCost) / newQuantity;

          await PortfolioRepository.instance.updatePortfolioItem(
          existingItem.copyWith(
  quantity: newQuantity,
  averagePrice: newAveragePrice,
  currency: _currency,
  type: resolvedAssetType,
),  
          );
        }
      } else {
        if (existingItem == null) {
          throw Exception('Bu varlık portföyde bulunamadı.');
        }

        if (quantity > existingItem.quantity) {
          throw Exception('Satış adedi portföydeki adetten büyük olamaz.');
        }

        final remainingQuantity = existingItem.quantity - quantity;

        if (remainingQuantity <= 0) {
          await PortfolioRepository.instance.deletePortfolioItem(existingItem.id);
        } else {
          await PortfolioRepository.instance.updatePortfolioItem(
            existingItem.copyWith(quantity: remainingQuantity),
          );
        }
      }

      await PortfolioRepository.instance.addTransaction({
        'symbol': symbol,
        'assetName': resolvedAssetName,
'assetType': resolvedAssetType,
        'type': _transactionType,
        'quantity': quantity,
        'price': price,
        'total': quantity * price,
        'currency': _currency,
        'transactionDate': Timestamp.fromDate(_transactionDate),
        'note': _noteController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$symbol için $_transactionType işlemi kaydedildi.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('TRANSACTION ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem kaydedilemedi: $error')),
      );
    }
  }
String _resolveAssetType(String symbol, String currentType) {
  switch (symbol) {
    case 'USD':
    case 'EUR':
    case 'GBP':
    case 'CHF':
      return 'Döviz';
    case 'XAU':
    case 'ALTIN':
    case 'GAU':
    case 'XAUUSD':
      return 'Altın';
    case 'BTC':
    case 'ETH':
    case 'SOL':
      return 'Kripto';
    default:
      return currentType.trim().isEmpty ? 'Hisse' : currentType;
  }
}

String _resolveAssetName(String symbol) {
  switch (symbol) {
    case 'USD':
      return 'Amerikan Doları';
    case 'EUR':
      return 'Euro';
    case 'GBP':
      return 'İngiliz Sterlini';
    case 'CHF':
      return 'İsviçre Frangı';
    case 'XAU':
    case 'ALTIN':
    case 'GAU':
      return 'Gram Altın';
    case 'BTC':
      return 'Bitcoin';
    case 'ETH':
      return 'Ethereum';
    case 'SOL':
      return 'Solana';
    default:
      return symbol;
  }
}
  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bu alan zorunlu.';
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bu alan zorunlu.';
    final parsed = _parseDouble(value);
    if (parsed <= 0) return 'Geçerli bir sayı gir.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İşlem'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const _SectionTitle(title: 'İşlem'),
              const SizedBox(height: 12),
              _SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portföyüne alış veya satış işlemi ekle. İşlem geçmişin otomatik güncellenir.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Alış', label: Text('Alış')),
                        ButtonSegment(value: 'Satış', label: Text('Satış')),
                      ],
                      selected: {_transactionType},
                      onSelectionChanged: (value) {
                        setState(() => _transactionType = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
  controller: _assetSearchController,
  decoration: const InputDecoration(
    labelText: 'Varlık Ara',
    hintText: 'ASELS, THYAO, AAPL, BTC...',
    prefixIcon: Icon(Icons.search_rounded),
    border: OutlineInputBorder(),
  ),
  validator: _requiredText,
  onChanged: _searchAssets,
),
const SizedBox(height: 8),
if (_isSearching) const LinearProgressIndicator(),
if (_suggestions.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: _SuggestionPanel(
      suggestions: _suggestions,
      onSelected: _selectAsset,
    ),
  ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Adet / Miktar',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Birim fiyat',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Para birimi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'İşlem tarihi',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        child: Text(_formatDate(_transactionDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Not',
                        hintText: 'Opsiyonel',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saveTransaction,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
  widget.isEdit
      ? 'Değişiklikleri Kaydet'
      : 'İşlemi Kaydet',
),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(

        selectedIndex: 2,

      ),
    );
  }
}

class PriceAlertPage extends StatefulWidget {
  const PriceAlertPage({super.key});

  @override
  State<PriceAlertPage> createState() => _PriceAlertPageState();
}

class _PriceAlertPageState extends State<PriceAlertPage> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _targetController = TextEditingController();
  String _direction = 'Üstüne çıkarsa';

  @override
  void dispose() {
    _symbolController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _saveAlert() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_symbolController.text.toUpperCase()} alarmı oluşturuldu.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Kur'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const _SectionTitle(title: 'Fiyat Alarmı'),
            const SizedBox(height: 12),
            _SurfaceCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Takip etmek istediğin fiyat seviyesini belirle. Bildirim altyapısı bağlandığında bu ekran canlı alarma dönüşecek.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _symbolController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Sembol / Varlık',
                        hintText: 'Örn: GARAN, BTC, AAPL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Varlık adı gerekli.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _direction,
                      decoration: const InputDecoration(
                        labelText: 'Koşul',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Üstüne çıkarsa', child: Text('Üstüne çıkarsa')),
                        DropdownMenuItem(value: 'Altına inerse', child: Text('Altına inerse')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _direction = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Hedef Fiyat',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                        if (parsed == null || parsed <= 0) {
                          return 'Geçerli bir hedef fiyat gir.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveAlert,
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text('Alarmı Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const _SectionTitle(title: 'Hesap'),
            const SizedBox(height: 12),
            _SurfaceCard(
              child: Row(
                children: [
                  const _IconBox(
                    icon: Icons.person_rounded,
                    color: Color(0xFF008DB9),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName!
                              : 'MyFin kullanıcısı',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'E-posta bağlı değil',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Uygulama'),
            const SizedBox(height: 12),
            _SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'MyFin Intelligence',
                    subtitle: 'AI analiz ve sohbet merkezi',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IntelligencePage(),
                        ),
                      );
                    },
                  ),
                  const _ThinDivider(),
                  _SettingsRow(
                    icon: Icons.security_rounded,
                    title: 'Gizlilik ve güvenlik',
                    subtitle: 'Yakında aktif olacak',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gizlilik ayarları sonraki sprintte bağlanacak.',
                          ),
                        ),
                      );
                    },
                  ),
                  const _ThinDivider(),
                  _SettingsRow(
                    icon: Icons.palette_rounded,
                    title: 'Görünüm',
                    subtitle: 'Premium açık tema aktif',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tema ayarları sonraki sprintte genişletilecek.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış Yap'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 4,
      ),
    );
  }
}
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF008DB9)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
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
            onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AiChatPage(analysis: analysis),
    ),
  );
},
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
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF0EA5E9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: glow),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MyFin Intelligence',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'AI destekli portföy merkezi',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      
                      FilledButton.icon(
                       onPressed: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AiChatPage(analysis: analysis),
    ),
  );
},
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                        label: const Text("MyFin AI'ye Sor"),
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
class _SuggestionPanel extends StatelessWidget {
  final List<MarketAsset> suggestions;
  final ValueChanged<MarketAsset> onSelected;

  const _SuggestionPanel({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: suggestions.map((item) {
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF008DB9).withValues(alpha: .12),
              child: Text(
                item.symbol.characters.first,
                style: const TextStyle(
                  color: Color(0xFF008DB9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              '${item.symbol} • ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${item.market} • ${item.currency}'),
            onTap: () => onSelected(item),
          );
        }).toList(),
      ),
    );
  }
}