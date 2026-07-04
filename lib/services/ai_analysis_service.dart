import '../models/ai_portfolio_score.dart';
import '../models/portfolio_item.dart';
import 'ai_score_service.dart';

class AIAnalysisResult {
  const AIAnalysisResult({
    required this.score,
    required this.strengths,
    required this.warnings,
    required this.recommendations,
    required this.confidence,
    required this.resultSummary,
  });

  final AIPortfolioScore score;
  final List<String> strengths;
  final List<String> warnings;
  final List<String> recommendations;
  final int confidence;
  final String resultSummary;
}

class AIAnalysisService {
  const AIAnalysisService();

  AIAnalysisResult analyze(List<PortfolioItem> items) {
    final score = const AIScoreService().calculate(items);

    if (items.isEmpty) {
      return AIAnalysisResult(
        score: score,
        strengths: const [],
        warnings: const ['Portföyde henüz analiz edilecek varlık bulunmuyor.'],
        recommendations: const ['AI analizi için ilk varlığınızı ekleyin.'],
        confidence: 0,
        resultSummary: 'Analiz için portföy verisi bekleniyor.',
      );
    }

    final strengths = <String>{};
    final warnings = <String>{};
    final recommendations = <String>{};

    final totalCost = _totalCost(items);
    final dominant = _dominantAsset(items, totalCost);
    final assetCount = _uniqueAssetCount(items);
    final typeCount = _uniqueTypeCount(items);
    final primaryType = _primaryType(items, totalCost);

    _analyzeDiversification(
      score: score,
      assetCount: assetCount,
      typeCount: typeCount,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );

    _analyzeDominantAsset(
      dominant: dominant,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );

    _analyzePrimaryType(
      primaryType: primaryType,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );

    _analyzeStabilityAndGrowth(
      score: score,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );

    _analyzeOverallScore(
      score: score,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );

    final confidence = _confidenceFor(
      items: items,
      assetCount: assetCount,
      typeCount: typeCount,
      totalCost: totalCost,
    );

    return AIAnalysisResult(
      score: score,
      strengths: _limit(strengths, 3),
      warnings: _limit(warnings, 3),
      recommendations: _limit(recommendations, 3),
      confidence: confidence,
      resultSummary: _resultSummary(
        score: score,
        dominant: dominant,
        assetCount: assetCount,
        typeCount: typeCount,
      ),
    );
  }

  void _analyzeDiversification({
    required AIPortfolioScore score,
    required int assetCount,
    required int typeCount,
    required Set<String> strengths,
    required Set<String> warnings,
    required Set<String> recommendations,
  }) {
    if (score.diversification >= 75) {
      strengths.add('$assetCount farklı varlık ile çeşitlendirme güçlü.');
    } else if (score.diversification >= 50) {
      warnings.add('Çeşitlendirme orta seviyede; birkaç ek varlık dengeyi güçlendirebilir.');
      recommendations.add('Portföye farklı sektör veya varlık türlerinden ekleme yapmak riski azaltabilir.');
    } else {
      warnings.add('Portföy az sayıda varlıkta yoğunlaşmış.');
      recommendations.add('En az 3-5 farklı varlık veya tür ile dağılımı güçlendirmeyi düşün.');
    }

    if (typeCount >= 3) {
      strengths.add('$typeCount farklı varlık türü ile dağılım dengesi destekleniyor.');
    } else if (typeCount < 2) {
      warnings.add('Portföy tek varlık türüne bağlı görünüyor.');
      recommendations.add('Hisse, fon, altın veya döviz gibi farklı türlerle denge kurulabilir.');
    }
  }

  void _analyzeDominantAsset({
    required _DominantAsset? dominant,
    required Set<String> strengths,
    required Set<String> warnings,
    required Set<String> recommendations,
  }) {
    if (dominant == null) return;

    final weightPercent = (dominant.weight * 100).round();

    if (dominant.weight >= .70) {
      warnings.add('Portföyünüzün %$weightPercent oranı ${dominant.symbol} varlığında yoğunlaşmış.');
      recommendations.add('${dominant.symbol} ağırlığını azaltmak AI skorunu belirgin şekilde iyileştirebilir.');
    } else if (dominant.weight >= .50) {
      warnings.add('${dominant.symbol} portföyde yüksek ağırlığa sahip (%$weightPercent).');
      recommendations.add('Yeni alımlarda farklı varlıklara yönelmek yoğunlaşma riskini azaltabilir.');
    } else if (dominant.weight <= .35) {
      strengths.add('En büyük pozisyon portföyün makul bir bölümünü oluşturuyor.');
    }
  }

  void _analyzePrimaryType({
    required _PrimaryType? primaryType,
    required Set<String> strengths,
    required Set<String> warnings,
    required Set<String> recommendations,
  }) {
    if (primaryType == null) return;

    final weightPercent = (primaryType.weight * 100).round();
    final label = _typeLabel(primaryType.type);

    if (primaryType.weight >= .75) {
      warnings.add('Portföyün %$weightPercent oranı $label türünde yoğunlaşmış.');
      recommendations.add('$label dışındaki varlık türleri portföy riskini dengeleyebilir.');
    } else if (primaryType.weight <= .55) {
      strengths.add('Varlık türleri arasında dağılım daha dengeli görünüyor.');
    }
  }

  void _analyzeStabilityAndGrowth({
    required AIPortfolioScore score,
    required Set<String> strengths,
    required Set<String> warnings,
    required Set<String> recommendations,
  }) {
    if (score.stability >= 75) {
      strengths.add('Portföy istikrarı iyi seviyede.');
    } else if (score.stability < 55) {
      warnings.add('Portföy oynaklığı yüksek olabilir.');
      recommendations.add('Daha stabil varlıklar eklemek toplam riski azaltabilir.');
    }

    if (score.momentum >= 75) {
      strengths.add('Büyüme potansiyeli güçlü.');
    } else if (score.momentum < 50) {
      recommendations.add('Büyüme potansiyeli için hisse veya fon dengesi gözden geçirilebilir.');
    }
  }

  void _analyzeOverallScore({
    required AIPortfolioScore score,
    required Set<String> strengths,
    required Set<String> warnings,
    required Set<String> recommendations,
  }) {
    if (score.overallScore >= 80) {
      strengths.add('Genel AI skoru güçlü bölgede.');
    } else if (score.overallScore < 60) {
      warnings.add('Genel AI skoru riskli bölgede.');
      recommendations.add('Öncelik çeşitlendirme ve pozisyon ağırlıklarını dengelemek olmalı.');
    }
  }

  double _totalCost(List<PortfolioItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.totalCost);
  }

  int _uniqueAssetCount(List<PortfolioItem> items) {
    return items.map((e) => e.symbol.toUpperCase().trim()).toSet().length;
  }

  int _uniqueTypeCount(List<PortfolioItem> items) {
    return items.map((e) => e.type.toLowerCase().trim()).toSet().length;
  }

  _DominantAsset? _dominantAsset(
    List<PortfolioItem> items,
    double totalCost,
  ) {
    if (items.isEmpty || totalCost <= 0) return null;

    PortfolioItem? dominant;
    double dominantValue = 0;

    for (final item in items) {
      if (item.totalCost > dominantValue) {
        dominant = item;
        dominantValue = item.totalCost;
      }
    }

    if (dominant == null) return null;

    return _DominantAsset(
      symbol: dominant.symbol.toUpperCase(),
      weight: dominantValue / totalCost,
    );
  }

  _PrimaryType? _primaryType(
    List<PortfolioItem> items,
    double totalCost,
  ) {
    if (items.isEmpty || totalCost <= 0) return null;

    final byType = <String, double>{};

    for (final item in items) {
      final type = item.type.toLowerCase().trim();
      byType[type] = (byType[type] ?? 0) + item.totalCost;
    }

    if (byType.isEmpty) return null;

    final sorted = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.first;

    return _PrimaryType(
      type: top.key,
      weight: top.value / totalCost,
    );
  }

  int _confidenceFor({
    required List<PortfolioItem> items,
    required int assetCount,
    required int typeCount,
    required double totalCost,
  }) {
    int confidence = 55;

    if (items.isNotEmpty) confidence += 10;
    if (totalCost > 0) confidence += 8;
    if (assetCount >= 2) confidence += 8;
    if (assetCount >= 4) confidence += 8;
    if (typeCount >= 2) confidence += 8;
    if (typeCount >= 3) confidence += 6;

    return confidence.clamp(0, 95);
  }

  String _resultSummary({
    required AIPortfolioScore score,
    required _DominantAsset? dominant,
    required int assetCount,
    required int typeCount,
  }) {
    if (score.overallScore >= 80) {
      return 'Portföyünüz güçlü ve dengeli bölgede. Mevcut dağılım korunabilir.';
    }

    if (dominant != null && dominant.weight >= .60) {
      final weightPercent = (dominant.weight * 100).round();
      return 'Portföyünüzün %$weightPercent oranı ${dominant.symbol} üzerinde yoğunlaştığı için risk seviyesi yükseliyor.';
    }

    if (assetCount < 3 || typeCount < 2) {
      return 'Portföyünüz sınırlı çeşitliliğe sahip. Dağılım güçlendikçe AI skoru iyileşebilir.';
    }

    if (score.overallScore >= 60) {
      return 'Portföyünüz orta risk bölgesinde. Bazı iyileştirmeler puanı artırabilir.';
    }

    return 'Portföyünüz orta-yüksek risk bölgesinde. Dağılımın güçlendirilmesi önerilir.';
  }

  String _typeLabel(String type) {
    final normalized = type.toLowerCase().trim();

    if (normalized.contains('hisse') || normalized.contains('stock')) {
      return 'hisse';
    }
    if (normalized.contains('fon') || normalized.contains('etf')) {
      return 'fon';
    }
    if (normalized.contains('altın') ||
        normalized.contains('altin') ||
        normalized.contains('gold')) {
      return 'altın';
    }
    if (normalized.contains('kripto') || normalized.contains('crypto')) {
      return 'kripto';
    }
    if (normalized.contains('nakit') ||
        normalized.contains('cash') ||
        normalized.contains('döviz') ||
        normalized.contains('doviz')) {
      return 'nakit/döviz';
    }

    return normalized.isEmpty ? 'varlık' : normalized;
  }

  List<String> _limit(Set<String> items, int max) {
    return items.take(max).toList(growable: false);
  }
}

class _DominantAsset {
  const _DominantAsset({
    required this.symbol,
    required this.weight,
  });

  final String symbol;
  final double weight;
}

class _PrimaryType {
  const _PrimaryType({
    required this.type,
    required this.weight,
  });

  final String type;
  final double weight;
}