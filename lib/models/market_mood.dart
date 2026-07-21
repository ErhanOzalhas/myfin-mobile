enum MarketMoodRegime {
  strongRiskOn,
  riskOn,
  neutral,
  cautious,
  riskOff,
  insufficient,
}

class MarketMoodObservation {
  const MarketMoodObservation({
    required this.key,
    required this.label,
    required this.group,
    required this.changePercent,
    required this.weight,
    required this.scale,
    required this.orientation,
    required this.updatedAt,
    this.maxAbsDailyChange = double.infinity,
  });

  final String key;
  final String label;
  final String group;
  final double changePercent;
  final double weight;
  final double scale;

  /// 1 for risk assets, -1 for stress indicators such as USD/TRY.
  final double orientation;
  final DateTime updatedAt;

  /// Provider kaynaklı ölçek/kapanış eşleşmesi hatalarını ayıklamak için
  /// kabul edilen en yüksek mutlak günlük değişim.
  final double maxAbsDailyChange;
}

class MarketMoodDriver {
  const MarketMoodDriver({
    required this.label,
    required this.changePercent,
    required this.impact,
  });

  final String label;
  final double changePercent;
  final double impact;
}

class MarketMoodResult {
  const MarketMoodResult({
    required this.score,
    required this.confidence,
    required this.coverage,
    required this.breadth,
    required this.regime,
    required this.drivers,
    required this.updatedAt,
    required this.observationCount,
    this.rejectedIndicators = const [],
  });

  final int score;
  final int confidence;
  final double coverage;
  final double breadth;
  final MarketMoodRegime regime;
  final List<MarketMoodDriver> drivers;
  final DateTime? updatedAt;
  final int observationCount;
  final List<String> rejectedIndicators;

  int get rejectedCount => rejectedIndicators.length;

  String get label => switch (regime) {
    MarketMoodRegime.strongRiskOn => 'Güçlü Risk İştahı',
    MarketMoodRegime.riskOn => 'Pozitif',
    MarketMoodRegime.neutral => 'Nötr',
    MarketMoodRegime.cautious => 'Temkinli',
    MarketMoodRegime.riskOff => 'Riskten Kaçış',
    MarketMoodRegime.insufficient => 'Veri Bekleniyor',
  };
}
