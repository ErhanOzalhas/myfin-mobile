import '../../models/ai/portfolio_score_v2.dart';
import '../../models/portfolio_item.dart';
import '../portfolio_valuation_service.dart';
import 'market_metadata.dart';
import 'portfolio_score_engine_v2.dart';

class PortfolioMarketSnapshot {
  const PortfolioMarketSnapshot({
    this.prices = const {},
    this.fxToBase = const {},
    this.annualizedVolatility = const {},
    this.maxDrawdown = const {},
    this.liquidityScores = const {},
    this.asOf,
    this.baseCurrency = 'TRY',
  });

  final Map<String, double> prices;
  final Map<String, double> fxToBase;
  final Map<String, double> annualizedVolatility;
  final Map<String, double> maxDrawdown;
  final Map<String, double> liquidityScores;
  final DateTime? asOf;
  final String baseCurrency;
}

class PortfolioScoreServiceV2 {
  const PortfolioScoreServiceV2({this.engine = const PortfolioScoreEngineV2()});

  final PortfolioScoreEngineV2 engine;

  PortfolioScoreResultV2 calculate(
    List<PortfolioItem> items, {
    PortfolioMarketSnapshot snapshot = const PortfolioMarketSnapshot(),
  }) {
    return engine.calculate(buildInput(items, snapshot: snapshot));
  }

  PortfolioScoreResultV2 calculateFromValuation(
    PortfolioValuation valuation, {
    double cashBalance = 0,
  }) {
    final positions = valuation.items
        .map((entry) {
          final item = entry.item;
          final symbol = MarketMetadata.normalizeSymbol(item.symbol);
          final metadata = MarketMetadata.resolve(
            symbol: symbol,
            name: item.name,
            type: item.type,
            currency: item.currency,
          );

          return PortfolioScorePosition(
            symbol: symbol.isEmpty ? item.id : symbol,
            assetClass: metadata.assetType.name,
            sector: _normalized(metadata.sector),
            country: _normalized(metadata.country),
            currency: _currency(item.currency),
            marketValue: entry.currentValueInBaseCurrency,
            costBasis: entry.costInBaseCurrency,
            usesLivePrice: entry.hasLivePrice,
            // PortfolioValuation has already converted every value to base currency.
            usesLiveFx: true,
          );
        })
        .toList(growable: true);

    if (cashBalance.isFinite && cashBalance > 0) {
      positions.add(
        PortfolioScorePosition(
          symbol: 'CASH_TRY',
          assetClass: 'cash',
          sector: 'cash',
          country: 'tr',
          currency: 'TRY',
          marketValue: cashBalance,
          costBasis: cashBalance,
          annualizedVolatility: 0,
          maxDrawdown: 0,
          liquidityScore: 100,
          usesLivePrice: true,
          usesLiveFx: true,
        ),
      );
    }

    return engine.calculate(
      PortfolioScoreInput(
        positions: positions,
        baseCurrency: valuation.baseCurrency,
        asOf: valuation.updatedAt,
      ),
    );
  }

  PortfolioScoreInput buildInput(
    List<PortfolioItem> items, {
    PortfolioMarketSnapshot snapshot = const PortfolioMarketSnapshot(),
  }) {
    final baseCurrency = _currency(snapshot.baseCurrency);
    final positions = items
        .map((item) {
          final symbol = MarketMetadata.normalizeSymbol(item.symbol);
          final metadata = MarketMetadata.resolve(
            symbol: symbol,
            name: item.name,
            type: item.type,
            currency: item.currency,
          );
          final currency = _currency(item.currency);
          final price = snapshot.prices[symbol];
          final hasLivePrice = price != null && price.isFinite && price > 0;
          final unitPrice = hasLivePrice ? price : item.averagePrice;
          final fxRate = currency == baseCurrency
              ? 1.0
              : snapshot.fxToBase[currency];
          final hasLiveFx =
              currency == baseCurrency ||
              (fxRate != null && fxRate.isFinite && fxRate > 0);
          final safeFx = hasLiveFx ? fxRate ?? 1 : 1.0;

          return PortfolioScorePosition(
            symbol: symbol.isEmpty ? item.id : symbol,
            assetClass: metadata.assetType.name,
            sector: _normalized(metadata.sector),
            country: _normalized(metadata.country),
            currency: currency,
            marketValue: item.quantity * unitPrice * safeFx,
            costBasis: item.quantity * item.averagePrice * safeFx,
            annualizedVolatility: snapshot.annualizedVolatility[symbol],
            maxDrawdown: snapshot.maxDrawdown[symbol],
            liquidityScore: snapshot.liquidityScores[symbol],
            usesLivePrice: hasLivePrice,
            usesLiveFx: hasLiveFx,
          );
        })
        .toList(growable: false);

    return PortfolioScoreInput(
      positions: positions,
      baseCurrency: baseCurrency,
      asOf: snapshot.asOf,
    );
  }

  String _currency(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      '' || 'TL' || '₺' => 'TRY',
      r'$' => 'USD',
      '€' => 'EUR',
      '£' => 'GBP',
      _ => normalized,
    };
  }

  String _normalized(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized.startsWith('bilinmeyen') ||
        normalized == 'unknown') {
      return 'unknown';
    }
    return normalized;
  }
}
