import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/price_alert.dart';

void main() {
  PriceAlert alert(PriceAlertDirection direction) => PriceAlert(
    id: '1',
    symbol: 'ASELS',
    name: 'Aselsan',
    exchange: 'BIST',
    currency: 'TRY',
    targetPrice: 100,
    direction: direction,
    repeat: PriceAlertRepeat.once,
    enabled: true,
    createdAt: DateTime(2026, 7, 18),
  );

  test('above alert triggers at or above target', () {
    final value = alert(PriceAlertDirection.above);
    expect(value.isTriggeredBy(99.99), isFalse);
    expect(value.isTriggeredBy(100), isTrue);
    expect(value.isTriggeredBy(101), isTrue);
  });

  test('below alert triggers at or below target', () {
    final value = alert(PriceAlertDirection.below);
    expect(value.isTriggeredBy(101), isFalse);
    expect(value.isTriggeredBy(100), isTrue);
    expect(value.isTriggeredBy(99.99), isTrue);
  });

  test('serializes and restores alert settings', () {
    final original = alert(
      PriceAlertDirection.below,
    ).copyWith(lastObservedPrice: 105);
    final restored = PriceAlert.fromJson(original.toJson());
    expect(restored.symbol, original.symbol);
    expect(restored.direction, PriceAlertDirection.below);
    expect(restored.lastObservedPrice, 105);
  });
}
