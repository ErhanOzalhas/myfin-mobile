import 'package:myfin_mobile/models/portfolio_item.dart';

class PortfolioIntelligenceResult {
  final String riskProfile;
  final String investmentStyle;
  final String focus;
  final String diversification;
  final String summary;
  final List<String> strengths;
  final List<String> warnings;

  const PortfolioIntelligenceResult({
    required this.riskProfile,
    required this.investmentStyle,
    required this.focus,
    required this.diversification,
    required this.summary,
    required this.strengths,
    required this.warnings,
  });
}

class PortfolioIntelligenceService {
  const PortfolioIntelligenceService();

  PortfolioIntelligenceResult analyze(List<PortfolioItem> items) {
    if (items.isEmpty) {
      return const PortfolioIntelligenceResult(
        riskProfile: 'Veri bekleniyor',
        investmentStyle: 'Belirsiz',
        focus: 'Portföy boş',
        diversification: 'Yok',
        summary:
            'Portföyünüzde henüz varlık bulunmadığı için anlamlı bir analiz üretilemedi.',
        strengths: [],
        warnings: [
          'Analiz için portföye en az bir varlık eklenmeli.',
        ],
      );
    }

    final assetCount = items.length;

    final diversification = assetCount == 1
        ? 'Düşük'
        : assetCount < 5
            ? 'Orta'
            : 'İyi';

    final riskProfile = assetCount == 1
        ? 'Yüksek'
        : assetCount < 4
            ? 'Orta'
            : 'Dengeli';

    final focus = assetCount == 1
        ? 'Tek varlık yoğunluğu'
        : assetCount < 5
            ? 'Sınırlı dağılım'
            : 'Çoklu varlık dağılımı';

    final investmentStyle = _detectInvestmentStyle(items);

    final warnings = <String>[];
    final strengths = <String>[];

    if (assetCount == 1) {
      warnings.add('Portföy tek bir varlık üzerinde yoğunlaşmış durumda.');
    } else {
      strengths.add('Portföy birden fazla varlığa yayılmış.');
    }

    if (diversification == 'Düşük') {
      warnings.add('Çeşitlendirme seviyesi düşük görünüyor.');
    }

    if (investmentStyle == 'Büyüme odaklı') {
      strengths.add('Portföy büyüme potansiyeli taşıyan varlıklara odaklanıyor.');
    }

    return PortfolioIntelligenceResult(
      riskProfile: riskProfile,
      investmentStyle: investmentStyle,
      focus: focus,
      diversification: diversification,
      summary:
          'Portföyünüz $focus yapısında görünüyor. Risk profili $riskProfile, çeşitlendirme seviyesi ise $diversification olarak değerlendirildi.',
      strengths: strengths,
      warnings: warnings,
    );
  }

  String _detectInvestmentStyle(List<PortfolioItem> items) {
    final joined = items
        .map((item) => '${item.symbol} ${item.name} ${item.type}'.toLowerCase())
        .join(' ');

    if (joined.contains('altın') ||
        joined.contains('gold') ||
        joined.contains('xau')) {
      return 'Korumacı';
    }

    if (joined.contains('fon') || joined.contains('fund') || joined.contains('etf')) {
      return 'Dengeli';
    }

    if (joined.contains('temettü') || joined.contains('dividend')) {
      return 'Gelir odaklı';
    }

    return 'Büyüme odaklı';
  }
}