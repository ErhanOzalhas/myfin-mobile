import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/ai/portfolio_score_v2.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/services/ai/portfolio_analyzer.dart';
import 'package:myfin_mobile/services/ai/portfolio_score_engine_v2.dart';
import 'package:myfin_mobile/services/ai/portfolio_score_service_v2.dart';
import 'package:myfin_mobile/services/ai_score_service.dart';
import 'package:myfin_mobile/services/portfolio_valuation_service.dart';

void main() {
  const engine = PortfolioScoreEngineV2();

  test('empty portfolio is explicitly insufficient', () {
    final result = engine.calculate(const PortfolioScoreInput(positions: []));

    expect(result.overallScore, 0);
    expect(result.confidence, 0);
    expect(result.dataQuality, ScoreDataQuality.insufficient);
  });

  test('balanced portfolio scores above a concentrated portfolio', () {
    final concentrated = engine.calculate(
      PortfolioScoreInput(
        positions: [
          _position('AAA', 90, assetClass: 'stock', sector: 'tech'),
          _position('GLD', 10, assetClass: 'gold', sector: 'gold'),
        ],
      ),
    );
    final balanced = engine.calculate(
      PortfolioScoreInput(
        positions: [
          _position(
            'AAA',
            25,
            assetClass: 'stock',
            sector: 'tech',
            country: 'tr',
          ),
          _position(
            'BBB',
            25,
            assetClass: 'stock',
            sector: 'finance',
            country: 'us',
          ),
          _position(
            'GLD',
            25,
            assetClass: 'gold',
            sector: 'gold',
            country: 'global',
          ),
          _position(
            'ETF',
            25,
            assetClass: 'etf',
            sector: 'broad',
            country: 'us',
          ),
        ],
      ),
    );

    expect(balanced.overallScore, greaterThan(concentrated.overallScore));
    expect(
      balanced.breakdown.concentration,
      greaterThan(concentrated.breakdown.concentration),
    );
    expect(
      balanced.effectiveAssetCount,
      greaterThan(concentrated.effectiveAssetCount),
    );
    expect(concentrated.largestPositionWeight, closeTo(.9, .001));
  });

  test('live market and history coverage increase confidence', () {
    final fallback = engine.calculate(
      PortfolioScoreInput(positions: [_position('AAA', 100)]),
    );
    final enriched = engine.calculate(
      PortfolioScoreInput(
        positions: [
          _position(
            'AAA',
            100,
            usesLivePrice: true,
            usesLiveFx: true,
            volatility: .20,
            drawdown: .12,
          ),
        ],
      ),
    );

    expect(enriched.confidence, greaterThan(fallback.confidence));
  });

  test('adapter normalizes currencies before calculating weights', () {
    const items = [
      PortfolioItem(
        id: '1',
        name: 'TRY asset',
        symbol: 'AAA',
        type: 'Hisse',
        quantity: 1,
        averagePrice: 100,
        currency: 'TRY',
      ),
      PortfolioItem(
        id: '2',
        name: 'USD asset',
        symbol: 'BBB',
        type: 'Hisse',
        quantity: 1,
        averagePrice: 10,
        currency: 'USD',
      ),
    ];
    const snapshot = PortfolioMarketSnapshot(fxToBase: {'USD': 10});

    final input = const PortfolioScoreServiceV2().buildInput(
      items,
      snapshot: snapshot,
    );

    expect(input.positions[0].marketValue, 100);
    expect(input.positions[1].marketValue, 100);
    expect(input.positions[1].usesLiveFx, isTrue);
  });

  test('valuation adapter uses normalized live market values', () {
    const usdItem = PortfolioItem(
      id: 'usd',
      name: 'Apple',
      symbol: 'AAPL',
      type: 'Hisse',
      quantity: 1,
      averagePrice: 100,
      currency: 'USD',
    );
    const tryItem = PortfolioItem(
      id: 'try',
      name: 'Altın',
      symbol: 'ALTIN',
      type: 'Altın',
      quantity: 1,
      averagePrice: 100,
      currency: 'TRY',
    );
    final valuation = PortfolioValuation(
      baseCurrency: 'TRY',
      items: const [
        PortfolioItemValuation(
          item: usdItem,
          costInBaseCurrency: 4000,
          currentValueInBaseCurrency: 6000,
          profitLossInBaseCurrency: 2000,
          profitPercent: 50,
          hasLivePrice: true,
        ),
        PortfolioItemValuation(
          item: tryItem,
          costInBaseCurrency: 4000,
          currentValueInBaseCurrency: 4000,
          profitLossInBaseCurrency: 0,
          profitPercent: 0,
          hasLivePrice: true,
        ),
      ],
      totalCost: 8000,
      totalValue: 10000,
      totalProfit: 2000,
      profitPercent: 25,
      updatedAt: DateTime(2026, 7, 21),
    );

    final result = const PortfolioScoreServiceV2().calculateFromValuation(
      valuation,
    );

    expect(result.largestPositionWeight, closeTo(.6, .001));
    expect(result.breakdown.riskAdjustedPerformance, greaterThan(50));
    expect(
      result.warnings,
      everyElement(isNot(contains('Güncel fiyat bulunmadığı'))),
    );
  });

  test('legacy score entry points return the same overall score', () {
    const items = [
      PortfolioItem(
        id: '1',
        name: 'Apple',
        symbol: 'AAPL',
        type: 'Hisse',
        quantity: 2,
        averagePrice: 100,
        currency: 'USD',
      ),
      PortfolioItem(
        id: '2',
        name: 'Altın',
        symbol: 'ALTIN',
        type: 'Altın',
        quantity: 1,
        averagePrice: 100,
        currency: 'TRY',
      ),
    ];

    final canonical = const PortfolioScoreServiceV2()
        .calculate(items)
        .overallScore;
    final dashboard = const AIScoreService().calculate(items).overallScore;
    final intelligence = PortfolioAnalyzer.analyze(items).aiScore;

    expect(dashboard, canonical);
    expect(intelligence, canonical);
  });
}

PortfolioScorePosition _position(
  String symbol,
  double value, {
  String assetClass = 'stock',
  String sector = 'tech',
  String country = 'tr',
  bool usesLivePrice = false,
  bool usesLiveFx = false,
  double? volatility,
  double? drawdown,
}) {
  return PortfolioScorePosition(
    symbol: symbol,
    assetClass: assetClass,
    sector: sector,
    country: country,
    currency: 'TRY',
    marketValue: value,
    costBasis: value,
    usesLivePrice: usesLivePrice,
    usesLiveFx: usesLiveFx,
    annualizedVolatility: volatility,
    maxDrawdown: drawdown,
  );
}
