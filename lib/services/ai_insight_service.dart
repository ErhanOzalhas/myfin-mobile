import '../models/ai_score_breakdown.dart';

class AIInsightResult {
  const AIInsightResult({
    required this.summary,
    required this.strengths,
    required this.warnings,
    required this.recommendations,
  });

  final String summary;
  final List<String> strengths;
  final List<String> warnings;
  final List<String> recommendations;
}

class AIInsightService {
  const AIInsightService();

  AIInsightResult build(AIScoreBreakdown breakdown) {
    final strengths = <String>[];
    final warnings = <String>[];
    final recommendations = <String>[];

    if (breakdown.diversification >= 70) {
      strengths.add('Çeşitlendirme güçlü.');
    } else {
      warnings.add('Çeşitlendirme düşük.');
      recommendations.add('Farklı varlık türleri eklemek riski azaltabilir.');
    }

    if (breakdown.risk >= 70) {
      strengths.add('Yoğunlaşma riski dengeli.');
    } else {
      warnings.add('Tek varlık veya tek tür yoğunluğu yüksek.');
      recommendations.add('En büyük pozisyonun portföy ağırlığını azaltmayı düşün.');
    }

    if (breakdown.profitability >= 70) {
      strengths.add('Kârlılık güçlü.');
    } else if (breakdown.profitability < 50) {
      warnings.add('Kârlılık baskı altında.');
      recommendations.add('Zarar yazan pozisyonları yeniden değerlendirmek faydalı olabilir.');
    }

    if (breakdown.cashRatio < 50) {
      warnings.add('Nakit oranı düşük.');
      recommendations.add('Fırsatlar için makul bir nakit tamponu ayırmak portföy esnekliğini artırabilir.');
    } else if (breakdown.cashRatio >= 80) {
      strengths.add('Nakit dengesi sağlıklı.');
    }

    if (breakdown.stability >= 70) {
      strengths.add('Stabilite iyi seviyede.');
    } else {
      warnings.add('Portföy oynaklığı yüksek olabilir.');
    }

    if (breakdown.growth >= 75) {
      strengths.add('Büyüme potansiyeli güçlü.');
    }

    final summary = _summaryFor(
      breakdown: breakdown,
      warnings: warnings,
      strengths: strengths,
    );

    return AIInsightResult(
      summary: summary,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  String _summaryFor({
    required AIScoreBreakdown breakdown,
    required List<String> warnings,
    required List<String> strengths,
  }) {
    if (breakdown.overallScore >= 80 && warnings.isEmpty) {
      return 'Portföy güçlü ve dengeli görünüyor. Mevcut dağılım korunabilir.';
    }

    if (breakdown.overallScore >= 60) {
      return 'Portföy genel olarak dengeli. Bazı alanlarda iyileştirme yapılabilir.';
    }

    if (strengths.isEmpty) {
      return 'Portföy yüksek risk içeriyor. Daha dengeli dağılım önerilir.';
    }

    return 'Portföyde güçlü noktalar var ancak risk azaltıcı düzenlemeler faydalı olabilir.';
  }
}