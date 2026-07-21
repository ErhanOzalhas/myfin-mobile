import '../portfolio_valuation_service.dart';
import 'portfolio_analyzer.dart';
import 'portfolio_context_builder.dart';

/// Produces the single portfolio fact set used by MyFin AI surfaces.
///
/// Values come from [PortfolioValuationService], so chat and dashboard copy do
/// not drift away from the figures shown in the portfolio screens.
class PortfolioAIContextService {
  const PortfolioAIContextService();

  PortfolioContextInput buildInput(PortfolioValuation valuation) {
    return PortfolioContextInput(
      currency: valuation.baseCurrency,
      totalValue: valuation.totalValue,
      assets: valuation.items
          .map((entry) {
            final item = entry.item;
            final currentPrice = item.quantity <= 0
                ? 0.0
                : entry.currentValueInBaseCurrency / item.quantity;
            return PortfolioAssetInput(
              symbol: item.symbol,
              name: item.name,
              assetType: item.type,
              quantity: item.quantity,
              currentPrice: currentPrice,
              currentValue: entry.currentValueInBaseCurrency,
              averageCost: item.averagePrice,
              unrealizedGainLossPercent: entry.profitPercent,
            );
          })
          .toList(growable: false),
    );
  }

  String buildDetailedFacts(PortfolioValuation valuation) {
    if (valuation.items.isEmpty) {
      return 'Portföyde henüz değerlendirilecek bir varlık yok.';
    }

    final sorted = [...valuation.items]
      ..sort(
        (a, b) => b.currentValueInBaseCurrency.compareTo(
          a.currentValueInBaseCurrency,
        ),
      );
    final buffer = StringBuffer()
      ..writeln('=== GERÇEK PORTFÖY DEĞERLEMESİ ===')
      ..writeln('Baz para: ${valuation.baseCurrency}')
      ..writeln('Toplam maliyet: ${_money(valuation.totalCost)}')
      ..writeln('Güncel toplam değer: ${_money(valuation.totalValue)}')
      ..writeln(
        'Toplam gerçekleşmemiş kâr/zarar: '
        '${_signedMoney(valuation.totalProfit)} '
        '(${_signedPercent(valuation.profitPercent)})',
      )
      ..writeln('Varlık sayısı: ${valuation.assetCount}')
      ..writeln(
        'Fiyat durumu: ${valuation.isStale ? 'önbellekteki son değerler' : 'güncel değerleme'}',
      )
      ..writeln('Kalemler (değere göre büyükten küçüğe):');

    for (final entry in sorted) {
      final item = entry.item;
      final weight = valuation.totalValue <= 0
          ? 0.0
          : entry.currentValueInBaseCurrency / valuation.totalValue * 100;
      final currentUnitPrice = item.quantity <= 0
          ? 0.0
          : entry.currentValueInBaseCurrency / item.quantity;
      buffer.writeln(
        '- ${item.name} (${item.symbol}); kategori=${item.type}; '
        'miktar=${_number(item.quantity)}; ortalama maliyet=${_money(item.averagePrice)}; '
        'güncel birim fiyat=${_money(currentUnitPrice)}; toplam maliyet=${_money(entry.costInBaseCurrency)}; '
        'güncel değer=${_money(entry.currentValueInBaseCurrency)}; '
        'kâr/zarar=${_signedMoney(entry.profitLossInBaseCurrency)} '
        '(${_signedPercent(entry.profitPercent)}); ağırlık=${weight.toStringAsFixed(2)}%; '
        'canlı fiyat=${entry.hasLivePrice ? 'evet' : 'hayır'}',
      );
    }

    buffer
      ..writeln('=== ANALİZ KURALI ===')
      ..writeln(
        'Kullanıcı ürün/kalem bazlı analiz isterse hiçbir kalemi atlama. Her kalem için '
        'performans, portföy ağırlığı ve yoğunlaşma etkisini ayrı değerlendir. Veride olmayan '
        'haber, temel analiz veya gelecek fiyatı uydurma. Canlı fiyatı olmayan kalemlerde bunu açıkça belirt.',
      );
    return buffer.toString().trim();
  }

  PortfolioAIHomeSummary buildHomeSummary(PortfolioValuation valuation) {
    final analysis = PortfolioAnalyzer.analyze(
      valuation.items.map((v) => v.item).toList(),
    );

    if (valuation.items.isEmpty) {
      return const PortfolioAIHomeSummary(
        title: 'AI analizi için portföyünü oluştur',
        summary:
            'Varlık eklediğinde kalem, dağılım ve kâr/zarar özetleri burada görünecek.',
        aiScore: 0,
      );
    }

    return PortfolioAIHomeSummary(
      title: 'AI Skoru: ${analysis.aiScore} • Risk: ${analysis.riskLevel}',
      summary: analysis.summary,
      aiScore: analysis.aiScore,
    );
  }

  String _money(double value) => '${_number(value)} TL';

  String _signedMoney(double value) =>
      '${value > 0 ? '+' : ''}${_money(value)}';

  String _signedPercent(double value) =>
      '${value > 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

  String _number(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final chars = parts.first.split('').reversed.toList();
    final groups = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      groups.add(chars.skip(i).take(3).toList().reversed.join());
    }
    return '${groups.reversed.join('.')},${parts.last}';
  }
}

class PortfolioAIHomeSummary {
  const PortfolioAIHomeSummary({
    required this.title,
    required this.summary,
    required this.aiScore,
  });

  final String title;
  final String summary;
  final int aiScore;
}
