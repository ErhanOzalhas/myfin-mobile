import '../../models/market_mood.dart';
import '../market/market_service.dart';
import 'market_mood_engine.dart';

class MarketMoodService {
  MarketMoodService._();

  static final MarketMoodService instance = MarketMoodService._();

  static const _specs = <_MoodAssetSpec>[
    _MoodAssetSpec('XU100', 'BIST 100', 'BIST', 'XIST', .25, 2.5, 1, 12),
    _MoodAssetSpec('THYAO', 'THY', 'BIST', 'XIST', .03, 3.0, 1, 20),
    _MoodAssetSpec('ASELS', 'ASELS', 'BIST', 'XIST', .03, 3.0, 1, 20),
    _MoodAssetSpec('GARAN', 'GARAN', 'BIST', 'XIST', .03, 3.0, 1, 20),
    _MoodAssetSpec('TUPRS', 'TÜPRAŞ', 'BIST', 'XIST', .03, 3.0, 1, 20),
    _MoodAssetSpec('BIMAS', 'BİM', 'BIST', 'XIST', .03, 3.0, 1, 20),
    _MoodAssetSpec('SPX', 'S&P 500', 'Global', 'US', .12, 2.0, 1, 10),
    _MoodAssetSpec('NDX', 'Nasdaq 100', 'Global', 'US', .08, 2.5, 1, 10),
    _MoodAssetSpec('BTC', 'Bitcoin', 'Kripto', 'CRYPTO', .10, 5.0, 1, 25),
    _MoodAssetSpec(
      'XAU/USD',
      'Ons Altın',
      'Stres',
      'COMMODITY',
      .10,
      2.0,
      -.65,
      8,
    ),
    _MoodAssetSpec('USD/TRY', 'USD/TRY', 'Stres', 'FX', .10, 1.5, -1, 8),
  ];

  MarketMoodResult? _latest;
  DateTime? _loadedAt;
  Future<MarketMoodResult>? _inFlight;

  MarketMoodResult? get latest => _latest;

  Future<MarketMoodResult> getMood({bool forceRefresh = false}) {
    if (!forceRefresh &&
        _latest != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 2)) {
      return Future.value(_latest);
    }
    if (_inFlight != null) return _inFlight!;

    final future = _load(forceRefresh: forceRefresh).whenComplete(() {
      _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  Future<MarketMoodResult> _load({required bool forceRefresh}) async {
    final results = await Future.wait(
      _specs.map((spec) async {
        try {
          final quote = await MarketService.instance.getQuote(
            spec.symbol,
            exchange: spec.exchange,
            forceRefresh: forceRefresh,
          );
          return MarketMoodObservation(
            key: spec.symbol,
            label: spec.label,
            group: spec.group,
            changePercent: quote.changePercent,
            weight: spec.weight,
            scale: spec.scale,
            orientation: spec.orientation,
            updatedAt: quote.updatedAt,
            maxAbsDailyChange: spec.maxAbsDailyChange,
          );
        } catch (_) {
          return null;
        }
      }),
    );

    final observations = results.whereType<MarketMoodObservation>().toList();
    final expectedWeight = _specs.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final result = const MarketMoodEngine().calculate(
      observations,
      expectedWeight: expectedWeight,
    );
    _latest = result;
    _loadedAt = DateTime.now();
    return result;
  }
}

class _MoodAssetSpec {
  const _MoodAssetSpec(
    this.symbol,
    this.label,
    this.group,
    this.exchange,
    this.weight,
    this.scale,
    this.orientation,
    this.maxAbsDailyChange,
  );

  final String symbol;
  final String label;
  final String group;
  final String exchange;
  final double weight;
  final double scale;
  final double orientation;
  final double maxAbsDailyChange;
}
