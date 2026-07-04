class MarketQuote {
  final String symbol;
  final double currentPrice;
  final double change;
  final double changePercent;
  final DateTime updatedAt;

  const MarketQuote({
    required this.symbol,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.updatedAt,
  });

  factory MarketQuote.fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      symbol: json['symbol'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'currentPrice': currentPrice,
      'change': change,
      'changePercent': changePercent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}