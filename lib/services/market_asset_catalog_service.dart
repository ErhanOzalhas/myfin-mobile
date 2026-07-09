class MarketAsset {
  final String symbol;
  final String name;
  final String type;
  final String currency;
  final String market;

  const MarketAsset({
    required this.symbol,
    required this.name,
    required this.type,
    required this.currency,
    required this.market,
  });
}

class MarketAssetCatalogService {
  const MarketAssetCatalogService();

  static const List<MarketAsset> _assets = [
    MarketAsset(symbol: 'ASELS', name: 'Aselsan', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'ISCTR', name: 'İş Bankası C', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'THYAO', name: 'Türk Hava Yolları', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'KCHOL', name: 'Koç Holding', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'GARAN', name: 'Garanti BBVA', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'AKBNK', name: 'Akbank', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'YKBNK', name: 'Yapı Kredi Bankası', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'TUPRS', name: 'Tüpraş', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'SISE', name: 'Şişecam', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'EREGL', name: 'Ereğli Demir Çelik', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'FROTO', name: 'Ford Otosan', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'TOASO', name: 'Tofaş', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'BIMAS', name: 'BİM Mağazalar', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'MGROS', name: 'Migros', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'TCELL', name: 'Turkcell', type: 'Hisse', currency: 'TRY', market: 'BIST'),
    MarketAsset(symbol: 'AAPL', name: 'Apple Inc.', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'MSFT', name: 'Microsoft', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'NVDA', name: 'Nvidia', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'TSLA', name: 'Tesla', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'AMZN', name: 'Amazon', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'GOOGL', name: 'Alphabet Class A', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'META', name: 'Meta Platforms', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'SPCX', name: 'SPCX', type: 'Hisse', currency: 'USD', market: 'US'),
    MarketAsset(symbol: 'RKLB', name: 'Rocket Lab', type: 'Hisse', currency: 'USD', market: 'NASDAQ'),
    MarketAsset(symbol: 'USD', name: 'Amerikan Doları', type: 'Döviz', currency: 'TRY', market: 'FX'),
    MarketAsset(symbol: 'EUR', name: 'Euro', type: 'Döviz', currency: 'TRY', market: 'FX'),
    MarketAsset(symbol: 'GBP', name: 'İngiliz Sterlini', type: 'Döviz', currency: 'TRY', market: 'FX'),
    MarketAsset(symbol: 'CHF', name: 'İsviçre Frangı', type: 'Döviz', currency: 'TRY', market: 'FX'),
    MarketAsset(symbol: 'XAU', name: 'Gram Altın', type: 'Altın', currency: 'TRY', market: 'Emtia'),
    MarketAsset(symbol: 'ALTIN', name: 'Gram Altın', type: 'Altın', currency: 'TRY', market: 'Emtia'),
    MarketAsset(symbol: 'XAUUSD', name: 'Ons Altın', type: 'Altın', currency: 'USD', market: 'Emtia'),
    MarketAsset(symbol: 'BTC', name: 'Bitcoin', type: 'Kripto', currency: 'USD', market: 'Crypto'),
    MarketAsset(symbol: 'ETH', name: 'Ethereum', type: 'Kripto', currency: 'USD', market: 'Crypto'),
    MarketAsset(symbol: 'SOL', name: 'Solana', type: 'Kripto', currency: 'USD', market: 'Crypto'),
  ];

  Future<List<MarketAsset>> search({
  required String query,
  int limit = 8,
}) async {
  final normalizedQuery = query.trim().toUpperCase();

  if (normalizedQuery.length < 2) return const [];

  return _assets.where((asset) {
    return asset.symbol.contains(normalizedQuery) ||
        asset.name.toUpperCase().contains(normalizedQuery) ||
        asset.market.toUpperCase().contains(normalizedQuery);
  }).take(limit).toList();
}}