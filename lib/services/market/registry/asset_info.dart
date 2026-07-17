import '../models/asset_category.dart';

enum AssetSupportStatus { live, delayed, catalogOnly, planned }

enum AssetRiskLevel { low, medium, high, veryHigh, unknown }

class AssetInfo {
  final String symbol;
  final String name;
  final AssetCategory category;
  final String exchange;
  final String currency;
  final String countryCode;
  final String provider;

  /// Provider-specific stable ID.
  /// CoinGecko için örnek: `ethereum`.
  final String? providerAssetId;

  final String? logoAsset;
  final String? description;
  final String? sector;
  final String? industry;
  final String? isin;

  final AssetSupportStatus supportStatus;
  final AssetRiskLevel riskLevel;

  final List<String> keywords;
  final List<String> aiTags;

  const AssetInfo({
    required this.symbol,
    required this.name,
    required this.category,
    required this.exchange,
    required this.currency,
    required this.countryCode,
    required this.provider,
    this.providerAssetId,
    this.logoAsset,
    this.description,
    this.sector,
    this.industry,
    this.isin,
    this.supportStatus = AssetSupportStatus.catalogOnly,
    this.riskLevel = AssetRiskLevel.unknown,
    this.keywords = const [],
    this.aiTags = const [],
  });

  bool get hasLiveData =>
      supportStatus == AssetSupportStatus.live ||
      supportStatus == AssetSupportStatus.delayed;

  bool get isTurkishAsset => countryCode.toUpperCase() == 'TR';

  bool get isGlobalAsset => countryCode.toUpperCase() == 'GLOBAL';

  int searchScore(String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return 0;
    }

    final normalizedSymbol = _normalize(symbol);
    final normalizedName = _normalize(name);

    if (normalizedSymbol == normalizedQuery) {
      return 100;
    }

    if (normalizedName == normalizedQuery) {
      return 95;
    }

    if (normalizedSymbol.startsWith(normalizedQuery)) {
      return 90;
    }

    if (normalizedName.startsWith(normalizedQuery)) {
      return 80;
    }

    if (normalizedSymbol.contains(normalizedQuery)) {
      return 70;
    }

    if (normalizedName.contains(normalizedQuery)) {
      return 60;
    }

    if (keywords.any(
      (keyword) => _normalize(keyword).contains(normalizedQuery),
    )) {
      return 50;
    }

    if (aiTags.any((tag) => _normalize(tag).contains(normalizedQuery))) {
      return 40;
    }

    return 0;
  }

  AssetInfo copyWith({
    String? symbol,
    String? name,
    AssetCategory? category,
    String? exchange,
    String? currency,
    String? countryCode,
    String? provider,
    String? providerAssetId,
    String? logoAsset,
    String? description,
    String? sector,
    String? industry,
    String? isin,
    AssetSupportStatus? supportStatus,
    AssetRiskLevel? riskLevel,
    List<String>? keywords,
    List<String>? aiTags,
  }) {
    return AssetInfo(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      category: category ?? this.category,
      exchange: exchange ?? this.exchange,
      currency: currency ?? this.currency,
      countryCode: countryCode ?? this.countryCode,
      provider: provider ?? this.provider,
      providerAssetId: providerAssetId ?? this.providerAssetId,
      logoAsset: logoAsset ?? this.logoAsset,
      description: description ?? this.description,
      sector: sector ?? this.sector,
      industry: industry ?? this.industry,
      isin: isin ?? this.isin,
      supportStatus: supportStatus ?? this.supportStatus,
      riskLevel: riskLevel ?? this.riskLevel,
      keywords: keywords ?? this.keywords,
      aiTags: aiTags ?? this.aiTags,
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .toUpperCase()
        .replaceAll('İ', 'I');
  }
}
