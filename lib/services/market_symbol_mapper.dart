class MarketSymbolMapper {
  MarketSymbolMapper._();

  static String map(String symbol, String type) {
    final cleanSymbol = symbol.trim().toUpperCase();
    final cleanType = type.trim().toLowerCase();

    switch (cleanType) {
      case 'hisse':
        if (cleanSymbol.endsWith('.IS')) return cleanSymbol;
        return '$cleanSymbol.IS';

      case 'abd':
      case 'amerika':
      case 'us':
        return cleanSymbol;

      case 'fon':
        return cleanSymbol;

      case 'kripto':
        if (cleanSymbol.endsWith('-USD')) return cleanSymbol;
        return '$cleanSymbol-USD';

      case 'doviz':
      case 'döviz':
        if (cleanSymbol.endsWith('=X')) return cleanSymbol;
        return '$cleanSymbol=X';

      case 'altin':
      case 'altın':
        return 'GC=F';

      default:
        return cleanSymbol;
    }
  }
}