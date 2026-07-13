enum AssetCategory {
  commodity,
  currency,
  bist,
  usStock,
  euStock,
  asiaStock,
  crypto,
  etf,
  fund,
  marketIndex,
  unknown,
}

extension AssetCategoryX on AssetCategory {
  String get key => switch (this) {
        AssetCategory.commodity => 'commodity',
        AssetCategory.currency => 'currency',
        AssetCategory.bist => 'bist',
        AssetCategory.usStock => 'us_stock',
        AssetCategory.euStock => 'eu_stock',
        AssetCategory.asiaStock => 'asia_stock',
        AssetCategory.crypto => 'crypto',
        AssetCategory.etf => 'etf',
        AssetCategory.fund => 'fund',
        AssetCategory.marketIndex => 'index',
        AssetCategory.unknown => 'unknown',
      };

  String get label => switch (this) {
        AssetCategory.commodity => 'Emtia',
        AssetCategory.currency => 'Döviz',
        AssetCategory.bist => 'BIST',
        AssetCategory.usStock => 'ABD Hissesi',
        AssetCategory.euStock => 'Avrupa Hissesi',
        AssetCategory.asiaStock => 'Asya Hissesi',
        AssetCategory.crypto => 'Kripto',
        AssetCategory.etf => 'ETF',
        AssetCategory.fund => 'Fon',
        AssetCategory.marketIndex => 'Endeks',
        AssetCategory.unknown => 'Diğer',
      };

  static AssetCategory fromKey(String value) {
    final normalized = value.trim().toLowerCase();

    return AssetCategory.values.firstWhere(
      (category) => category.key == normalized,
      orElse: () => AssetCategory.unknown,
    );
  }
}
