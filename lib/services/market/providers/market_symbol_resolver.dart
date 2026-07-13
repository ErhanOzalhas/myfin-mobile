import '../catalog/asset_universe.dart';
import 'provider_symbol_mapping.dart';

class ResolvedMarketSymbol {
  final String requestedSymbol;
  final String providerSymbol;
  final String? exchange;
  final bool isLocalTurkishGold;

  const ResolvedMarketSymbol({
    required this.requestedSymbol,
    required this.providerSymbol,
    this.exchange,
    this.isLocalTurkishGold = false,
  });
}

class MarketSymbolResolver {
  MarketSymbolResolver._();

  static ResolvedMarketSymbol resolve(
    String symbol, {
    String? exchange,
  }) {
    final requested = symbol.trim().toUpperCase();
    final definition = AssetUniverse.find(requested);

    if (definition != null) {
      return ResolvedMarketSymbol(
        requestedSymbol: requested,
        providerSymbol: definition.symbol,
        exchange: ProviderSymbolMapping.normalizeExchange(
          exchange ?? definition.exchange,
        ),
        isLocalTurkishGold: definition.isLocalTurkishGold,
      );
    }

    final normalized = _normalizeGeneric(requested);

    return ResolvedMarketSymbol(
      requestedSymbol: requested,
      providerSymbol: normalized,
      exchange: ProviderSymbolMapping.normalizeExchange(exchange),
    );
  }

  static String _normalizeGeneric(String symbol) {
    final compact = symbol
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .toUpperCase();

    const aliases = {
      'USDTRY': 'USD/TRY',
      'EURTRY': 'EUR/TRY',
      'GBPTRY': 'GBP/TRY',
      'CHFTRY': 'CHF/TRY',
      'EURUSD': 'EUR/USD',
      'GBPUSD': 'GBP/USD',
      'USDJPY': 'USD/JPY',
      'XAUUSD': 'XAU/USD',
      'XAGUSD': 'XAG/USD',
      'XPTUSD': 'XPT/USD',
      'XPDUSD': 'XPD/USD',
    };

    return aliases[compact] ?? symbol.trim().toUpperCase();
  }
}
