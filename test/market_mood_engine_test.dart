import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/market_mood.dart';
import 'package:myfin_mobile/services/intelligence/market_mood_engine.dart';

void main() {
  const engine = MarketMoodEngine();
  final now = DateTime(2026, 7, 21, 12);

  test('positive risk assets and easing stress produce risk-on regime', () {
    final result = engine.calculate(
      [
        _observation('BIST 100', 2.0, .35, 2.5, 1, now),
        _observation('S&P 500', 1.2, .20, 2.0, 1, now),
        _observation('Nasdaq', 1.8, .15, 2.5, 1, now),
        _observation('Bitcoin', 3.0, .10, 5.0, 1, now),
        _observation('USD/TRY', -.5, .10, 1.5, -1, now),
        _observation('Altın', -.4, .10, 2.0, -.65, now),
      ],
      expectedWeight: 1,
      now: now,
    );

    expect(result.score, greaterThanOrEqualTo(58));
    expect(
      result.regime,
      anyOf(MarketMoodRegime.riskOn, MarketMoodRegime.strongRiskOn),
    );
    expect(result.breadth, 1);
    expect(result.confidence, greaterThanOrEqualTo(90));
  });

  test('falling risk assets and rising FX stress produce risk-off result', () {
    final result = engine.calculate(
      [
        _observation('BIST 100', -2.5, .35, 2.5, 1, now),
        _observation('S&P 500', -1.8, .20, 2.0, 1, now),
        _observation('Nasdaq', -2.3, .15, 2.5, 1, now),
        _observation('Bitcoin', -5, .10, 5.0, 1, now),
        _observation('USD/TRY', 1.5, .10, 1.5, -1, now),
        _observation('Altın', 2, .10, 2.0, -.65, now),
      ],
      expectedWeight: 1,
      now: now,
    );

    expect(result.score, lessThan(30));
    expect(result.regime, MarketMoodRegime.riskOff);
    expect(result.breadth, 0);
  });

  test('low indicator coverage is reported as insufficient', () {
    final result = engine.calculate(
      [_observation('Bitcoin', 2, .10, 5, 1, now)],
      expectedWeight: 1,
      now: now,
    );

    expect(result.regime, MarketMoodRegime.insufficient);
    expect(result.score, 50);
    expect(result.coverage, closeTo(.10, .001));
  });

  test('rejects implausible daily changes and lowers coverage', () {
    final result = engine.calculate(
      [
        _observation('BIST 100', -1.5, .50, 2.5, 1, now),
        MarketMoodObservation(
          key: 'NDX',
          label: 'Nasdaq 100',
          group: 'test',
          changePercent: -41.12,
          weight: .25,
          scale: 2.5,
          orientation: 1,
          updatedAt: now,
          maxAbsDailyChange: 10,
        ),
        MarketMoodObservation(
          key: 'XAU',
          label: 'Ons Altın',
          group: 'test',
          changePercent: 60.61,
          weight: .25,
          scale: 2,
          orientation: -.65,
          updatedAt: now,
          maxAbsDailyChange: 8,
        ),
      ],
      expectedWeight: 1,
      now: now,
    );

    expect(result.observationCount, 1);
    expect(result.coverage, .5);
    expect(result.rejectedIndicators, ['Nasdaq 100', 'Ons Altın']);
    expect(result.drivers.single.label, 'BIST 100');
  });
}

MarketMoodObservation _observation(
  String label,
  double change,
  double weight,
  double scale,
  double orientation,
  DateTime updatedAt,
) {
  return MarketMoodObservation(
    key: label,
    label: label,
    group: 'test',
    changePercent: change,
    weight: weight,
    scale: scale,
    orientation: orientation,
    updatedAt: updatedAt,
  );
}
