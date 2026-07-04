import 'package:myfin_mobile/models/portfolio_item.dart';

import 'market_metadata.dart';
import 'ai_trend_result.dart';
import 'portfolio_analysis.dart';

class PortfolioAnalyzer {
  static PortfolioAnalysis analyze(
    List<PortfolioItem> items, {
    AITrendResult? trend,
  }) {
    if (items.isEmpty) {
      return _emptyAnalysis();
    }

    final metadata = _resolveMetadata(items);
    final assetCount = items.length;
    final assetProfile = _analyzeAssetTypes(metadata);
    final sectorProfile = _analyzeSectors(metadata);

    final diversification = _calculateDiversification(
      assetCount: assetCount,
      assetProfile: assetProfile,
      sectorProfile: sectorProfile,
    );

    final risk = _calculateRisk(
      assetCount: assetCount,
      assetProfile: assetProfile,
      sectorProfile: sectorProfile,
    );

    final growth = _calculateGrowth(
      assetProfile: assetProfile,
      sectorProfile: sectorProfile,
    );

    final stability = _calculateStability(
      assetCount: assetCount,
      assetProfile: assetProfile,
      sectorProfile: sectorProfile,
    );

    final aiScore = _calculateAIScore(
      diversification: diversification,
      risk: risk,
      growth: growth,
      stability: stability,
      assetTypeScore: assetProfile.score,
      sectorScore: sectorProfile.score,
    );

    return PortfolioAnalysis(
      aiScore: aiScore,
      risk: risk,
      growth: growth,
      stability: stability,
      diversification: diversification,
      riskLevel: _buildRiskLevel(risk),
      investmentStyle: _buildInvestmentStyle(assetProfile, sectorProfile),
      focus: _buildFocus(assetCount, assetProfile, sectorProfile),
      strengths: _buildStrengths(
        assetCount: assetCount,
        assetProfile: assetProfile,
        sectorProfile: sectorProfile,
        trend: trend,
      ),
      warnings: _buildWarnings(
        assetCount: assetCount,
        diversification: diversification,
        risk: risk,
        assetProfile: assetProfile,
        sectorProfile: sectorProfile,
        trend: trend,
      ),
      recommendations: _buildRecommendations(
        assetCount: assetCount,
        diversification: diversification,
        risk: risk,
        assetProfile: assetProfile,
        sectorProfile: sectorProfile,
        trend: trend,
      ),
    );
  }

  static PortfolioAnalysis _emptyAnalysis() {
    return const PortfolioAnalysis(
      aiScore: 0,
      risk: 0,
      growth: 0,
      stability: 0,
      diversification: 0,
      riskLevel: 'Veri yok',
      investmentStyle: 'Belirsiz',
      focus: 'Portföy boş',
      strengths: [],
      warnings: [
        'Analiz için portföye en az bir varlık eklenmeli.',
      ],
      recommendations: [
        'Portföye ilk varlığınızı ekleyerek AI analizini başlatabilirsiniz.',
      ],
    );
  }

  static List<AssetMetadata> _resolveMetadata(List<PortfolioItem> items) {
    return items
        .map(
          (item) => MarketMetadata.resolve(
            symbol: item.symbol,
            name: item.name,
            type: item.type,
          ),
        )
        .toList();
  }

  static _AssetProfile _analyzeAssetTypes(List<AssetMetadata> metadata) {
    final assetTypes = metadata.map((item) => item.assetType).toSet();

    final hasStock = assetTypes.contains(AssetType.stock);
    final hasEtf = assetTypes.contains(AssetType.etf);
    final hasFund = assetTypes.contains(AssetType.fund);
    final hasGold = assetTypes.contains(AssetType.gold);
    final hasCurrency = assetTypes.contains(AssetType.currency);
    final hasCrypto = assetTypes.contains(AssetType.crypto);
    final hasCash = assetTypes.contains(AssetType.cash);

    final defensiveAssetCount = [hasGold, hasEtf, hasFund, hasCurrency, hasCash]
        .where((flag) => flag)
        .length;

    final score = _calculateAssetTypeScore(
      uniqueAssetClassCount: assetTypes.length,
      hasStock: hasStock,
      hasEtf: hasEtf,
      hasFund: hasFund,
      hasGold: hasGold,
      hasCurrency: hasCurrency,
      hasCrypto: hasCrypto,
      hasCash: hasCash,
    );

    return _AssetProfile(
      hasStock: hasStock,
      hasEtf: hasEtf,
      hasFund: hasFund,
      hasGold: hasGold,
      hasCurrency: hasCurrency,
      hasCrypto: hasCrypto,
      hasCash: hasCash,
      defensiveAssetCount: defensiveAssetCount,
      uniqueAssetClassCount: assetTypes.length,
      score: score,
    );
  }

  static _SectorProfile _analyzeSectors(List<AssetMetadata> metadata) {
    final sectors = <String, int>{};

    for (final item in metadata) {
      final sector = item.sector.trim().isEmpty ? 'Bilinmeyen' : item.sector;
      sectors[sector] = (sectors[sector] ?? 0) + 1;
    }

    final uniqueSectorCount = sectors.length;
    final dominantEntry = _dominantEntry(sectors);
    final dominantSector = dominantEntry?.key ?? 'Bilinmeyen';
    final dominantCount = dominantEntry?.value ?? 0;
    final dominantRatio = metadata.isEmpty ? 0.0 : dominantCount / metadata.length;

    final unknownCount = sectors['Bilinmeyen'] ?? 0;
    final unknownSectorRatio = metadata.isEmpty ? 0.0 : unknownCount / metadata.length;

    final score = _calculateSectorScore(
      uniqueSectorCount: uniqueSectorCount,
      itemCount: metadata.length,
      dominantRatio: dominantRatio,
      unknownSectorRatio: unknownSectorRatio,
    );

    return _SectorProfile(
      sectors: sectors,
      uniqueSectorCount: uniqueSectorCount,
      dominantSector: dominantSector,
      dominantRatio: dominantRatio,
      unknownSectorRatio: unknownSectorRatio,
      score: score,
    );
  }

  static MapEntry<String, int>? _dominantEntry(Map<String, int> source) {
    if (source.isEmpty) return null;

    MapEntry<String, int>? best;
    for (final entry in source.entries) {
      if (best == null || entry.value > best.value) {
        best = entry;
      }
    }
    return best;
  }

  static int _calculateAssetTypeScore({
    required int uniqueAssetClassCount,
    required bool hasStock,
    required bool hasEtf,
    required bool hasFund,
    required bool hasGold,
    required bool hasCurrency,
    required bool hasCrypto,
    required bool hasCash,
  }) {
    var score = 32 + ((uniqueAssetClassCount - 1) * 14);

    if (hasEtf) score += 8;
    if (hasFund) score += 8;
    if (hasGold) score += 9;
    if (hasCurrency) score += 5;
    if (hasCash) score += 4;
    if (hasCrypto) score -= 6;
    if (hasStock && uniqueAssetClassCount == 1) score -= 8;

    return _clampScore(score);
  }

  static int _calculateSectorScore({
    required int uniqueSectorCount,
    required int itemCount,
    required double dominantRatio,
    required double unknownSectorRatio,
  }) {
    var score = itemCount == 1
        ? 28
        : uniqueSectorCount == 1
            ? 38
            : uniqueSectorCount == 2
                ? 58
                : uniqueSectorCount < 5
                    ? 76
                    : 90;

    if (dominantRatio >= 0.75) score -= 16;
    if (dominantRatio >= 0.90) score -= 12;
    if (unknownSectorRatio > 0.40) score -= 10;

    return _clampScore(score);
  }

  static int _calculateDiversification({
    required int assetCount,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
  }) {
    var score = assetCount == 1
        ? 22
        : assetCount < 4
            ? 46
            : assetCount < 7
                ? 70
                : 84;

    score += (assetProfile.uniqueAssetClassCount - 1) * 5;
    score += (sectorProfile.uniqueSectorCount - 1) * 4;

    if (sectorProfile.dominantRatio >= 0.75) score -= 8;
    if (assetProfile.hasEtf || assetProfile.hasFund) score += 5;
    if (assetProfile.hasGold) score += 4;

    return _clampScore(score);
  }

  static int _calculateRisk({
    required int assetCount,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
  }) {
    var score = assetCount == 1
        ? 88
        : assetCount < 4
            ? 68
            : assetCount < 7
                ? 52
                : 38;

    if (sectorProfile.dominantRatio >= 0.75) score += 10;
    if (sectorProfile.uniqueSectorCount >= 4) score -= 6;
    if (assetProfile.hasGold) score -= 8;
    if (assetProfile.hasEtf) score -= 7;
    if (assetProfile.hasFund) score -= 6;
    if (assetProfile.hasCurrency) score -= 3;
    if (assetProfile.hasCrypto) score += 12;

    return _clampScore(score);
  }

  static int _calculateGrowth({
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
  }) {
    var score = 78;

    if (sectorProfile.sectors.containsKey('Teknoloji')) score += 8;
    if (sectorProfile.sectors.containsKey('Savunma')) score += 6;
    if (sectorProfile.sectors.containsKey('Havacılık')) score += 4;
    if (assetProfile.hasCrypto) score += 8;
    if (assetProfile.hasGold) score -= 8;
    if (assetProfile.hasEtf || assetProfile.hasFund) score -= 3;

    return _clampScore(score);
  }

  static int _calculateStability({
    required int assetCount,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
  }) {
    var score = assetCount == 1
        ? 42
        : assetCount < 4
            ? 62
            : 76;

    score += assetProfile.defensiveAssetCount * 6;
    if (sectorProfile.uniqueSectorCount >= 3) score += 5;
    if (sectorProfile.dominantRatio >= 0.75) score -= 8;
    if (assetProfile.hasCrypto) score -= 10;

    return _clampScore(score);
  }

  static int _calculateAIScore({
    required int diversification,
    required int risk,
    required int growth,
    required int stability,
    required int assetTypeScore,
    required int sectorScore,
  }) {
    final score = (diversification * 0.26) +
        ((100 - risk) * 0.23) +
        (stability * 0.17) +
        (growth * 0.12) +
        (assetTypeScore * 0.10) +
        (sectorScore * 0.12);

    return _clampScore(score);
  }

  static String _buildRiskLevel(int risk) {
    if (risk >= 75) return 'Yüksek';
    if (risk >= 55) return 'Orta';
    return 'Dengeli';
  }

  static String _buildInvestmentStyle(
    _AssetProfile assetProfile,
    _SectorProfile sectorProfile,
  ) {
    if (assetProfile.hasCrypto) return 'Agresif büyüme';
    if (assetProfile.hasGold && assetProfile.uniqueAssetClassCount <= 2) {
      return 'Korumacı';
    }
    if (assetProfile.hasEtf || assetProfile.hasFund) return 'Dengeli';
    if (sectorProfile.sectors.containsKey('Bankacılık') &&
        sectorProfile.sectors.containsKey('Enerji')) {
      return 'Değer odaklı';
    }
    if (sectorProfile.sectors.containsKey('Teknoloji') ||
        sectorProfile.sectors.containsKey('Savunma')) {
      return 'Büyüme odaklı';
    }
    return 'Büyüme odaklı';
  }

  static String _buildFocus(
    int assetCount,
    _AssetProfile assetProfile,
    _SectorProfile sectorProfile,
  ) {
    if (assetCount == 1) return 'Tek varlık yoğunluğu';
    if (sectorProfile.dominantRatio >= 0.75) {
      return '${sectorProfile.dominantSector} ağırlığı';
    }
    if (assetProfile.uniqueAssetClassCount >= 3) return 'Çoklu varlık sınıfı';
    if (sectorProfile.uniqueSectorCount >= 4) return 'Sektör çeşitliliği';
    if (assetCount < 4) return 'Sınırlı dağılım';
    return 'Çoklu varlık dağılımı';
  }

  static List<String> _buildStrengths({
    required int assetCount,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
    AITrendResult? trend,
  }) {
    return [
      if (assetCount > 1) 'Portföy birden fazla varlığa yayılmış.',
      if (assetProfile.uniqueAssetClassCount >= 3)
        'Portföy farklı varlık sınıflarına yayılmış.',
      if (sectorProfile.uniqueSectorCount >= 3)
        'Portföy birden fazla sektöre dağılıyor.',
      if (sectorProfile.score >= 75) 'Sektör çeşitliliği iyi seviyede.',
      if (assetProfile.hasGold) 'Altın varlığı portföye korumacı denge katıyor.',
      if (assetProfile.hasEtf || assetProfile.hasFund)
        'Fon veya ETF varlığı dağılımı destekliyor.',
      if (assetProfile.hasCurrency) 'Döviz varlığı kur çeşitliliği sağlıyor.',
      if (!assetProfile.hasGold &&
          !assetProfile.hasEtf &&
          !assetProfile.hasFund &&
          !assetProfile.hasCurrency)
        'Portföy büyüme potansiyeli taşıyor.',
      if ((trend?.aiScoreChange ?? 0) > 0)
        'AI skoru son analize göre +${trend!.aiScoreChange} puan iyileşti.',
      if ((trend?.riskChange ?? 0) < 0)
        'Risk son analize göre ${trend!.riskChange!.abs()} puan azaldı.',
      if ((trend?.diversificationChange ?? 0) > 0)
        'Çeşitlendirme son analize göre +${trend!.diversificationChange} puan arttı.',
    ];
  }

  static List<String> _buildWarnings({
    required int assetCount,
    required int diversification,
    required int risk,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
    AITrendResult? trend,
  }) {
    return [
      if (assetCount == 1) 'Portföy tek varlığa yoğunlaşmış.',
      if (assetProfile.uniqueAssetClassCount == 1)
        'Portföy tek varlık sınıfından oluşuyor.',
      if (sectorProfile.uniqueSectorCount == 1)
        'Portföy tek sektöre yoğunlaşmış görünüyor.',
      if (sectorProfile.dominantRatio >= 0.75 && assetCount > 1)
        'Portföyde ${sectorProfile.dominantSector} sektörü ağırlığı yüksek.',
      if (sectorProfile.unknownSectorRatio > 0.40)
        'Bazı varlıkların sektörü tanımlanamadığı için analiz sınırlı olabilir.',
      if (diversification < 50) 'Çeşitlendirme seviyesi düşük.',
      if (risk > 75) 'Risk seviyesi yüksek görünüyor.',
      if (assetProfile.hasCrypto)
        'Kripto varlıklar portföy volatilitesini artırabilir.',
      if (!assetProfile.hasGold && !assetProfile.hasEtf && assetCount < 4)
        'Savunmacı varlık oranı düşük görünüyor.',
      if ((trend?.aiScoreChange ?? 0) < 0)
        'AI skoru son analize göre ${trend!.aiScoreChange!.abs()} puan geriledi.',
      if ((trend?.riskChange ?? 0) > 0)
        'Risk son analize göre +${trend!.riskChange} puan yükseldi.',
      if ((trend?.diversificationChange ?? 0) < 0)
        'Çeşitlendirme son analize göre ${trend!.diversificationChange!.abs()} puan geriledi.',
    ];
  }

  static List<String> _buildRecommendations({
    required int assetCount,
    required int diversification,
    required int risk,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
    AITrendResult? trend,
  }) {
    return [
      if (assetCount == 1)
        'Farklı sektörlerden yeni varlık eklemeyi değerlendirin.',
      if (sectorProfile.uniqueSectorCount == 1)
        'Sektör riskini azaltmak için farklı sektörlerden varlıkları inceleyin.',
      if (sectorProfile.dominantRatio >= 0.75 && assetCount > 1)
        '${sectorProfile.dominantSector} ağırlığını dengelemek için alternatif sektörleri değerlendirin.',
      if (assetProfile.uniqueAssetClassCount == 1)
        'Hisse dışında fon, altın veya döviz gibi farklı varlık sınıflarını inceleyin.',
      if (diversification < 50) 'Riski azaltmak için portföyü çeşitlendirin.',
      if (!assetProfile.hasGold)
        'Korumacı denge için altın veya benzeri varlıkları inceleyebilirsiniz.',
      if (!assetProfile.hasEtf && !assetProfile.hasFund)
        'Daha dengeli dağılım için fon veya ETF alternatiflerini değerlendirin.',
      if (risk > 75)
        'Yüksek risk nedeniyle pozisyon ağırlıklarını düzenli kontrol edin.',
      if ((trend?.riskChange ?? 0) > 0)
        'Risk trendi yükseldiği için son eklenen pozisyonların etkisini gözden geçirin.',
      if ((trend?.aiScoreChange ?? 0) < 0)
        'AI skorundaki düşüşün hangi varlık veya sektör kaynaklı olduğunu kontrol edin.',
      'Portföy dağılımını düzenli olarak takip edin.',
    ];
  }

  static int _clampScore(num value) {
    return value.round().clamp(0, 100).toInt();
  }
}

class _AssetProfile {
  final bool hasStock;
  final bool hasEtf;
  final bool hasFund;
  final bool hasGold;
  final bool hasCurrency;
  final bool hasCrypto;
  final bool hasCash;
  final int defensiveAssetCount;
  final int uniqueAssetClassCount;
  final int score;

  const _AssetProfile({
    required this.hasStock,
    required this.hasEtf,
    required this.hasFund,
    required this.hasGold,
    required this.hasCurrency,
    required this.hasCrypto,
    required this.hasCash,
    required this.defensiveAssetCount,
    required this.uniqueAssetClassCount,
    required this.score,
  });
}

class _SectorProfile {
  final Map<String, int> sectors;
  final int uniqueSectorCount;
  final String dominantSector;
  final double dominantRatio;
  final double unknownSectorRatio;
  final int score;

  const _SectorProfile({
    required this.sectors,
    required this.uniqueSectorCount,
    required this.dominantSector,
    required this.dominantRatio,
    required this.unknownSectorRatio,
    required this.score,
  });
}
