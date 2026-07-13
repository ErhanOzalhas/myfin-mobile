import '../catalog/asset_universe.dart';
import '../models/asset_category.dart';
import '../models/asset_definition.dart';
import 'asset_info.dart';

class AssetRegistry {
  AssetRegistry._();

  static final Map<String, AssetInfo> _items = {
    'AAPL': const AssetInfo(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      category: AssetCategory.usStock,
      exchange: 'NASDAQ',
      currency: 'USD',
      countryCode: 'US',
      provider: 'TwelveData',
      description:
          'Tüketici elektroniği, yazılım ve dijital hizmetler şirketi.',
      sector: 'Technology',
      industry: 'Consumer Electronics',
      supportStatus: AssetSupportStatus.live,
      riskLevel: AssetRiskLevel.medium,
      keywords: [
        'apple',
        'iphone',
        'ipad',
        'mac',
        'ios',
      ],
      aiTags: [
        'growth',
        'technology',
        'mega-cap',
        'us-equity',
      ],
    ),
    'ASELS': const AssetInfo(
      symbol: 'ASELS',
      name: 'Aselsan Elektronik Sanayi ve Ticaret A.Ş.',
      category: AssetCategory.bist,
      exchange: 'XIST',
      currency: 'TRY',
      countryCode: 'TR',
      provider: 'TwelveData',
      description:
          'Savunma elektroniği ve ileri teknoloji sistemleri şirketi.',
      sector: 'Industrials',
      industry: 'Aerospace & Defense',
      supportStatus: AssetSupportStatus.delayed,
      riskLevel: AssetRiskLevel.high,
      keywords: [
        'aselsan',
        'savunma',
        'bist',
        'teknoloji',
      ],
      aiTags: [
        'turkey',
        'defense',
        'technology',
        'bist-equity',
      ],
    ),
    'BTC': const AssetInfo(
      symbol: 'BTC',
      name: 'Bitcoin',
      category: AssetCategory.crypto,
      exchange: 'CRYPTO',
      currency: 'USD',
      countryCode: 'GLOBAL',
      provider: 'CoinGecko',
      description:
          'Merkezi olmayan, sınırlı arza sahip dijital varlık.',
      sector: 'Digital Assets',
      industry: 'Cryptocurrency',
      supportStatus: AssetSupportStatus.live,
      riskLevel: AssetRiskLevel.veryHigh,
      keywords: [
        'bitcoin',
        'btc',
        'kripto',
        'crypto',
      ],
      aiTags: [
        'crypto',
        'high-volatility',
        'store-of-value',
        '24-7-market',
      ],
    ),
    'XAU/USD': const AssetInfo(
      symbol: 'XAU/USD',
      name: 'Ons Altın',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      countryCode: 'GLOBAL',
      provider: 'TwelveData',
      description:
          'Uluslararası piyasalarda ABD doları cinsinden işlem gören ons altın.',
      sector: 'Commodities',
      industry: 'Precious Metals',
      supportStatus: AssetSupportStatus.live,
      riskLevel: AssetRiskLevel.medium,
      keywords: [
        'ons altın',
        'gold',
        'xauusd',
        'precious metal',
      ],
      aiTags: [
        'safe-haven',
        'commodity',
        'inflation-hedge',
        'precious-metal',
      ],
    ),
    'CEYREK_ALTIN': const AssetInfo(
      symbol: 'CEYREK_ALTIN',
      name: 'Çeyrek Altın',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      countryCode: 'TR',
      provider: 'TurkeyGoldProvider',
      description:
          'Türkiye yerel piyasasında işlem gören fiziki ziynet altını.',
      sector: 'Commodities',
      industry: 'Local Gold',
      supportStatus: AssetSupportStatus.live,
      riskLevel: AssetRiskLevel.medium,
      keywords: [
        'çeyrek',
        'ceyrek',
        'çeyrek altın',
        'ziynet',
      ],
      aiTags: [
        'turkey',
        'physical-gold',
        'local-gold',
        'precious-metal',
      ],
    ),
  };

  static AssetInfo? find(String symbol) {
    final key = symbol.trim().toUpperCase();
    final direct = _items[key];

    if (direct != null) {
      return direct;
    }

    final AssetDefinition? definition = AssetUniverse.find(key);

    if (definition == null) {
      return null;
    }

    return AssetInfo(
      symbol: definition.symbol,
      name: definition.name,
      category: definition.category,
      exchange: definition.exchange,
      currency: definition.currency,
      countryCode:
          definition.exchange == 'XIST' ||
                  definition.exchange == 'TR_GOLD'
              ? 'TR'
              : 'GLOBAL',
      provider: definition.isLocalTurkishGold
          ? 'TurkeyGoldProvider'
          : 'MarketRouter',
      description: null,
      sector: null,
      industry: null,
      supportStatus: definition.isLocalTurkishGold
          ? AssetSupportStatus.live
          : AssetSupportStatus.live,
      riskLevel: AssetRiskLevel.unknown,
      keywords: definition.aliases,
      aiTags: const [],
    );
  }

  static List<AssetInfo> search(
    String query, {
    AssetCategory? category,
    String? countryCode,
    AssetSupportStatus? supportStatus,
  }) {
    final merged = <String, AssetInfo>{
      for (final item in AssetUniverse.all)
        item.symbol: find(item.symbol)!,
      ..._items,
    };

    final results = merged.values.where((item) {
      if (category != null && item.category != category) {
        return false;
      }

      if (countryCode != null &&
          item.countryCode.toUpperCase() !=
              countryCode.toUpperCase()) {
        return false;
      }

      if (supportStatus != null &&
          item.supportStatus != supportStatus) {
        return false;
      }

      return item.searchScore(query) > 0;
    }).toList();

    results.sort(
      (first, second) => second
          .searchScore(query)
          .compareTo(first.searchScore(query)),
    );

    return results;
  }

  static List<AssetInfo> get all {
    final merged = <String, AssetInfo>{
      for (final item in AssetUniverse.all)
        item.symbol: find(item.symbol)!,
      ..._items,
    };

    return merged.values.toList();
  }
}
