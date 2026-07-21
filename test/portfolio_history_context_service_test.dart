import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/models/portfolio_snapshot.dart';
import 'package:myfin_mobile/services/ai/portfolio_history_context_service.dart';
import 'package:myfin_mobile/services/portfolio_valuation_service.dart';

void main() {
  PortfolioValuation buildValuation() {
    const item = PortfolioItem(
      id: '1',
      name: 'Aselsan',
      symbol: 'ASELS',
      type: 'Hisse',
      quantity: 10,
      averagePrice: 100,
      currency: 'TRY',
    );

    return const PortfolioValuation(
      baseCurrency: 'TRY',
      items: [
        PortfolioItemValuation(
          item: item,
          costInBaseCurrency: 1000,
          currentValueInBaseCurrency: 1250,
          profitLossInBaseCurrency: 250,
          profitPercent: 25,
          hasLivePrice: true,
        ),
      ],
      totalCost: 1000,
      totalValue: 1250,
      totalProfit: 250,
      profitPercent: 25,
    );
  }

  test('builds product history context from transactions and snapshots', () {
    final service = const PortfolioHistoryContextService();
    final text = service.buildHistoricalFactsFromData(
      valuation: buildValuation(),
      question: 'ASELS geçmiş performansımı ve işlemlerimi anlat',
      transactions: [
        {
          'symbol': 'ASELS',
          'type': 'Alış',
          'quantity': 10,
          'price': 100,
          'transactionDate': DateTime(2026, 6, 1),
        },
        {
          'symbol': 'ASELS',
          'type': 'Satış',
          'quantity': 2,
          'price': 120,
          'transactionDate': DateTime(2026, 7, 1),
        },
      ],
      snapshots: [
        PortfolioSnapshot(
          dateKey: '2026-06-20',
          capturedAt: DateTime(2026, 6, 20),
          totalValue: 1000,
          totalCost: 900,
          profitLoss: 100,
          assetCount: 1,
          categoryValues: {'Hisse': 1000},
        ),
        PortfolioSnapshot(
          dateKey: '2026-07-20',
          capturedAt: DateTime(2026, 7, 20),
          totalValue: 1250,
          totalCost: 1000,
          profitLoss: 250,
          assetCount: 1,
          categoryValues: {'Hisse': 1250},
        ),
      ],
    );

    expect(text, contains('Odak kalemler: ASELS'));
    expect(text, contains('Toplam ilgili işlem: 2'));
    expect(text, contains('ASELS: alış=1, satış=1'));
    expect(text, contains('30 gün değişim'));
    expect(text, contains('Son snapshot: 20.07.2026'));
  });
}
