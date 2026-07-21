import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/models/ai/portfolio_score_v2.dart';

import 'market_metadata.dart';
import 'ai_trend_result.dart';
import 'portfolio_analysis.dart';
import 'portfolio_score_service_v2.dart';

class PortfolioAnalyzer {
  static PortfolioAnalysis analyze(
    List<PortfolioItem> items, {
    AITrendResult? trend,
    PortfolioScoreResultV2? scoreResult,
  }) {
    if (items.isEmpty) {
      return _emptyAnalysis();
    }

    final score =
        scoreResult ?? const PortfolioScoreServiceV2().calculate(items);
    final metadata = _resolveMetadata(items);
    final assetCount = items.length;
    final assetProfile = _analyzeAssetTypes(metadata);
    final sectorProfile = _analyzeSectors(metadata);
    final diversification = score.breakdown.diversification.round();
    final risk = score.riskScore;
    final growth = score.breakdown.riskAdjustedPerformance.round();
    final stability = score.breakdown.marketRisk.round();
    final strengths = <String>{...score.strengths};
    final warnings = <String>{...score.warnings};

    if ((trend?.aiScoreChange ?? 0) > 0) {
      strengths.add(
        'AI skoru son analize göre +${trend!.aiScoreChange} puan iyileşti.',
      );
    }
    if ((trend?.aiScoreChange ?? 0) < 0) {
      warnings.add(
        'AI skoru son analize göre ${trend!.aiScoreChange!.abs()} puan geriledi.',
      );
    }

    final recommendations = <String>{
      if (score.largestPositionWeight >= .50)
        'En büyük pozisyonun ağırlığını azaltmayı değerlendirin.',
      if (diversification < 55)
        'Portföyü farklı varlık sınıfı, sektör ve para birimlerine yaymayı değerlendirin.',
      if (score.confidence < 70)
        'Daha hassas analiz için güncel fiyat, kur ve fiyat geçmişi verilerini tamamlayın.',
      'Portföy dağılımını ve skor bileşenlerini düzenli olarak takip edin.',
    };

    return PortfolioAnalysis(
      aiScore: score.overallScore,
      risk: risk,
      growth: growth,
      stability: stability,
      diversification: diversification,
      riskLevel: _buildRiskLevel(risk),
      investmentStyle: _buildInvestmentStyle(assetProfile, sectorProfile),
      focus: _buildFocus(assetCount, assetProfile, sectorProfile),
      strengths: strengths.toList(growable: false),
      warnings: warnings.toList(growable: false),
      recommendations: recommendations.toList(growable: false),
      summary: score.confidence < 45
          ? 'Skor sınırlı veriyle hesaplandı; güncel piyasa verileri eklendiğinde hassasiyet artacak.'
          : _buildSummary(
              aiScore: score.overallScore,
              assetCount: assetCount,
              assetProfile: assetProfile,
              sectorProfile: sectorProfile,
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
      summary: 'Analiz için portföy verisi bekleniyor.',
      strengths: [],
      warnings: ['Analiz için portföye en az bir varlık eklenmeli.'],
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

    final defensiveAssetCount = [
      hasGold,
      hasEtf,
      hasFund,
      hasCurrency,
      hasCash,
    ].where((flag) => flag).length;

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
    final dominantRatio = metadata.isEmpty
        ? 0.0
        : dominantCount / metadata.length;

    final unknownCount = sectors['Bilinmeyen'] ?? 0;
    final unknownSectorRatio = metadata.isEmpty
        ? 0.0
        : unknownCount / metadata.length;

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

  static String _buildSummary({
    required int aiScore,
    required int assetCount,
    required _AssetProfile assetProfile,
    required _SectorProfile sectorProfile,
  }) {
    if (aiScore >= 80) {
      return 'Portföyünüz güçlü ve dengeli bölgede. Mevcut dağılım korunabilir.';
    }

    if (sectorProfile.dominantRatio >= 0.60 && assetCount > 1) {
      final weightPercent = (sectorProfile.dominantRatio * 100).round();
      return 'Portföyünüzün %$weightPercent oranı ${sectorProfile.dominantSector} üzerinde yoğunlaştığı için risk seviyesi yükseliyor.';
    }

    if (assetCount < 3 || assetProfile.uniqueAssetClassCount < 2) {
      return 'Portföyünüz sınırlı çeşitliliğe sahip. Dağılım güçlendikçe AI skoru iyileşebilir.';
    }

    return 'Portföyünüz orta risk bölgesinde. Bazı iyileştirmeler puanı artırabilir.';
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
