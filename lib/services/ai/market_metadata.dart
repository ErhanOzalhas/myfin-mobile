enum AssetType {
  stock,
  etf,
  fund,
  gold,
  currency,
  crypto,
  commodity,
  cash,
  unknown,
}

class AssetMetadata {
  final String symbol;
  final String displayName;
  final AssetType assetType;
  final String sector;
  final String country;
  final String currency;

  const AssetMetadata({
    required this.symbol,
    required this.displayName,
    required this.assetType,
    required this.sector,
    required this.country,
    required this.currency,
  });
}

class MarketMetadata {
  const MarketMetadata._();

  static const Map<String, AssetMetadata> assets = {
    'ASELS': AssetMetadata(symbol: 'ASELS', displayName: 'Aselsan', assetType: AssetType.stock, sector: 'Savunma', country: 'TR', currency: 'TRY'),
    'KONTR': AssetMetadata(symbol: 'KONTR', displayName: 'Kontrolmatik', assetType: AssetType.stock, sector: 'Teknoloji', country: 'TR', currency: 'TRY'),
    'MIATK': AssetMetadata(symbol: 'MIATK', displayName: 'Mia Teknoloji', assetType: AssetType.stock, sector: 'Teknoloji', country: 'TR', currency: 'TRY'),

    'THYAO': AssetMetadata(symbol: 'THYAO', displayName: 'Türk Hava Yolları', assetType: AssetType.stock, sector: 'Havacılık', country: 'TR', currency: 'TRY'),
    'PGSUS': AssetMetadata(symbol: 'PGSUS', displayName: 'Pegasus', assetType: AssetType.stock, sector: 'Havacılık', country: 'TR', currency: 'TRY'),
    'TAVHL': AssetMetadata(symbol: 'TAVHL', displayName: 'TAV Havalimanları', assetType: AssetType.stock, sector: 'Havacılık', country: 'TR', currency: 'TRY'),

    'GARAN': AssetMetadata(symbol: 'GARAN', displayName: 'Garanti BBVA', assetType: AssetType.stock, sector: 'Bankacılık', country: 'TR', currency: 'TRY'),
    'AKBNK': AssetMetadata(symbol: 'AKBNK', displayName: 'Akbank', assetType: AssetType.stock, sector: 'Bankacılık', country: 'TR', currency: 'TRY'),
    'ISCTR': AssetMetadata(symbol: 'ISCTR', displayName: 'İş Bankası', assetType: AssetType.stock, sector: 'Bankacılık', country: 'TR', currency: 'TRY'),
    'YKBNK': AssetMetadata(symbol: 'YKBNK', displayName: 'Yapı Kredi', assetType: AssetType.stock, sector: 'Bankacılık', country: 'TR', currency: 'TRY'),
    'HALKB': AssetMetadata(symbol: 'HALKB', displayName: 'Halkbank', assetType: AssetType.stock, sector: 'Bankacılık', country: 'TR', currency: 'TRY'),
    'VAKBN': AssetMetadata(symbol: 'VAKBN', displayName: 'Vakıfbank', assetType: AssetType.stock, sector: 'Bankacılık', country: 'TR', currency: 'TRY'),

    'TUPRS': AssetMetadata(symbol: 'TUPRS', displayName: 'Tüpraş', assetType: AssetType.stock, sector: 'Enerji', country: 'TR', currency: 'TRY'),
    'FROTO': AssetMetadata(symbol: 'FROTO', displayName: 'Ford Otosan', assetType: AssetType.stock, sector: 'Otomotiv', country: 'TR', currency: 'TRY'),
    'TOASO': AssetMetadata(symbol: 'TOASO', displayName: 'Tofaş', assetType: AssetType.stock, sector: 'Otomotiv', country: 'TR', currency: 'TRY'),
    'EREGL': AssetMetadata(symbol: 'EREGL', displayName: 'Ereğli Demir Çelik', assetType: AssetType.stock, sector: 'Demir-Çelik', country: 'TR', currency: 'TRY'),
    'KRDMD': AssetMetadata(symbol: 'KRDMD', displayName: 'Kardemir D', assetType: AssetType.stock, sector: 'Demir-Çelik', country: 'TR', currency: 'TRY'),
    'SISE': AssetMetadata(symbol: 'SISE', displayName: 'Şişecam', assetType: AssetType.stock, sector: 'Sanayi', country: 'TR', currency: 'TRY'),

    'KCHOL': AssetMetadata(symbol: 'KCHOL', displayName: 'Koç Holding', assetType: AssetType.stock, sector: 'Holding', country: 'TR', currency: 'TRY'),
    'SAHOL': AssetMetadata(symbol: 'SAHOL', displayName: 'Sabancı Holding', assetType: AssetType.stock, sector: 'Holding', country: 'TR', currency: 'TRY'),
    'BIMAS': AssetMetadata(symbol: 'BIMAS', displayName: 'BİM', assetType: AssetType.stock, sector: 'Perakende', country: 'TR', currency: 'TRY'),
    'MGROS': AssetMetadata(symbol: 'MGROS', displayName: 'Migros', assetType: AssetType.stock, sector: 'Perakende', country: 'TR', currency: 'TRY'),
    'ULKER': AssetMetadata(symbol: 'ULKER', displayName: 'Ülker', assetType: AssetType.stock, sector: 'Gıda', country: 'TR', currency: 'TRY'),

    'TCELL': AssetMetadata(symbol: 'TCELL', displayName: 'Turkcell', assetType: AssetType.stock, sector: 'Telekom', country: 'TR', currency: 'TRY'),
    'TTKOM': AssetMetadata(symbol: 'TTKOM', displayName: 'Türk Telekom', assetType: AssetType.stock, sector: 'Telekom', country: 'TR', currency: 'TRY'),
    'MPARK': AssetMetadata(symbol: 'MPARK', displayName: 'Medical Park', assetType: AssetType.stock, sector: 'Sağlık', country: 'TR', currency: 'TRY'),

    'AAPL': AssetMetadata(symbol: 'AAPL', displayName: 'Apple', assetType: AssetType.stock, sector: 'Teknoloji', country: 'US', currency: 'USD'),
    'MSFT': AssetMetadata(symbol: 'MSFT', displayName: 'Microsoft', assetType: AssetType.stock, sector: 'Teknoloji', country: 'US', currency: 'USD'),
    'NVDA': AssetMetadata(symbol: 'NVDA', displayName: 'Nvidia', assetType: AssetType.stock, sector: 'Teknoloji', country: 'US', currency: 'USD'),
    'GOOGL': AssetMetadata(symbol: 'GOOGL', displayName: 'Alphabet', assetType: AssetType.stock, sector: 'Teknoloji', country: 'US', currency: 'USD'),
    'META': AssetMetadata(symbol: 'META', displayName: 'Meta', assetType: AssetType.stock, sector: 'Teknoloji', country: 'US', currency: 'USD'),
    'TSLA': AssetMetadata(symbol: 'TSLA', displayName: 'Tesla', assetType: AssetType.stock, sector: 'Otomotiv', country: 'US', currency: 'USD'),
    'AMZN': AssetMetadata(symbol: 'AMZN', displayName: 'Amazon', assetType: AssetType.stock, sector: 'Tüketim', country: 'US', currency: 'USD'),
    'JPM': AssetMetadata(symbol: 'JPM', displayName: 'JPMorgan Chase', assetType: AssetType.stock, sector: 'Finans', country: 'US', currency: 'USD'),
    'BAC': AssetMetadata(symbol: 'BAC', displayName: 'Bank of America', assetType: AssetType.stock, sector: 'Finans', country: 'US', currency: 'USD'),
    'KO': AssetMetadata(symbol: 'KO', displayName: 'Coca-Cola', assetType: AssetType.stock, sector: 'Tüketim', country: 'US', currency: 'USD'),
    'PG': AssetMetadata(symbol: 'PG', displayName: 'Procter & Gamble', assetType: AssetType.stock, sector: 'Tüketim', country: 'US', currency: 'USD'),
    'JNJ': AssetMetadata(symbol: 'JNJ', displayName: 'Johnson & Johnson', assetType: AssetType.stock, sector: 'Sağlık', country: 'US', currency: 'USD'),

    'SPY': AssetMetadata(symbol: 'SPY', displayName: 'SPDR S&P 500 ETF', assetType: AssetType.etf, sector: 'Geniş Piyasa', country: 'US', currency: 'USD'),
    'VOO': AssetMetadata(symbol: 'VOO', displayName: 'Vanguard S&P 500 ETF', assetType: AssetType.etf, sector: 'Geniş Piyasa', country: 'US', currency: 'USD'),
    'QQQ': AssetMetadata(symbol: 'QQQ', displayName: 'Nasdaq 100 ETF', assetType: AssetType.etf, sector: 'Teknoloji', country: 'US', currency: 'USD'),
    'GLD': AssetMetadata(symbol: 'GLD', displayName: 'Gold ETF', assetType: AssetType.etf, sector: 'Altın', country: 'US', currency: 'USD'),

    'GOLD': AssetMetadata(symbol: 'GOLD', displayName: 'Altın', assetType: AssetType.gold, sector: 'Altın', country: 'GLOBAL', currency: 'USD'),
    'XAU': AssetMetadata(symbol: 'XAU', displayName: 'Ons Altın', assetType: AssetType.gold, sector: 'Altın', country: 'GLOBAL', currency: 'USD'),
    'GRAM ALTIN': AssetMetadata(symbol: 'GRAM ALTIN', displayName: 'Gram Altın', assetType: AssetType.gold, sector: 'Altın', country: 'TR', currency: 'TRY'),
    'ALTIN': AssetMetadata(symbol: 'ALTIN', displayName: 'Altın', assetType: AssetType.gold, sector: 'Altın', country: 'TR', currency: 'TRY'),

    'USD': AssetMetadata(symbol: 'USD', displayName: 'Amerikan Doları', assetType: AssetType.currency, sector: 'Döviz', country: 'US', currency: 'USD'),
    'EUR': AssetMetadata(symbol: 'EUR', displayName: 'Euro', assetType: AssetType.currency, sector: 'Döviz', country: 'EU', currency: 'EUR'),
    'GBP': AssetMetadata(symbol: 'GBP', displayName: 'Sterlin', assetType: AssetType.currency, sector: 'Döviz', country: 'UK', currency: 'GBP'),

    'BTC': AssetMetadata(symbol: 'BTC', displayName: 'Bitcoin', assetType: AssetType.crypto, sector: 'Kripto', country: 'GLOBAL', currency: 'USD'),
    'ETH': AssetMetadata(symbol: 'ETH', displayName: 'Ethereum', assetType: AssetType.crypto, sector: 'Kripto', country: 'GLOBAL', currency: 'USD'),
  };

  static AssetMetadata resolve({
    required String symbol,
    String? name,
    String? type,
    String? currency,
  }) {
    final normalizedSymbol = normalizeSymbol(symbol);
    final direct = assets[normalizedSymbol];

    if (direct != null) {
      return direct;
    }

    final normalizedName = normalizeSymbol(name ?? '');
    final byName = assets[normalizedName];

    if (byName != null) {
      return byName;
    }

    final detectedAssetType = detectAssetType(
      symbol: normalizedSymbol,
      name: name ?? '',
      type: type ?? '',
    );

    return AssetMetadata(
      symbol: normalizedSymbol.isEmpty ? 'UNKNOWN' : normalizedSymbol,
      displayName: (name == null || name.trim().isEmpty)
          ? normalizedSymbol
          : name.trim(),
      assetType: detectedAssetType,
      sector: defaultSectorFor(detectedAssetType),
      country: 'UNKNOWN',
      currency: (currency == null || currency.trim().isEmpty)
          ? defaultCurrencyFor(detectedAssetType)
          : currency.trim().toUpperCase(),
    );
  }

  static String normalizeSymbol(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('.IS', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static AssetType detectAssetType({
    required String symbol,
    required String name,
    required String type,
  }) {
    final joined = '$symbol $name $type'.toLowerCase();

    if (joined.contains('altın') || joined.contains('gold') || joined.contains('xau')) {
      return AssetType.gold;
    }

    if (joined.contains('btc') || joined.contains('bitcoin') || joined.contains('eth') || joined.contains('ethereum') || joined.contains('crypto') || joined.contains('kripto')) {
      return AssetType.crypto;
    }

    if (joined.contains('usd') || joined.contains('eur') || joined.contains('gbp') || joined.contains('döviz') || joined.contains('currency')) {
      return AssetType.currency;
    }

    if (joined.contains('etf')) {
      return AssetType.etf;
    }

    if (joined.contains('fon') || joined.contains('fund')) {
      return AssetType.fund;
    }

    if (joined.contains('nakit') || joined.contains('cash')) {
      return AssetType.cash;
    }

    if (joined.trim().isEmpty) {
      return AssetType.unknown;
    }

    return AssetType.stock;
  }

  static String defaultSectorFor(AssetType assetType) {
    switch (assetType) {
      case AssetType.stock:
        return 'Bilinmeyen Sektör';
      case AssetType.etf:
      case AssetType.fund:
        return 'Fon / ETF';
      case AssetType.gold:
        return 'Altın';
      case AssetType.currency:
        return 'Döviz';
      case AssetType.crypto:
        return 'Kripto';
      case AssetType.commodity:
        return 'Emtia';
      case AssetType.cash:
        return 'Nakit';
      case AssetType.unknown:
        return 'Bilinmeyen';
    }
  }

  static String defaultCurrencyFor(AssetType assetType) {
    switch (assetType) {
      case AssetType.currency:
      case AssetType.crypto:
      case AssetType.etf:
      case AssetType.commodity:
        return 'USD';
      case AssetType.gold:
      case AssetType.stock:
      case AssetType.fund:
      case AssetType.cash:
      case AssetType.unknown:
        return 'TRY';
    }
  }

  static String assetTypeLabel(AssetType assetType) {
    switch (assetType) {
      case AssetType.stock:
        return 'Hisse';
      case AssetType.etf:
        return 'ETF';
      case AssetType.fund:
        return 'Fon';
      case AssetType.gold:
        return 'Altın';
      case AssetType.currency:
        return 'Döviz';
      case AssetType.crypto:
        return 'Kripto';
      case AssetType.commodity:
        return 'Emtia';
      case AssetType.cash:
        return 'Nakit';
      case AssetType.unknown:
        return 'Bilinmeyen';
    }
  }
}
