import 'asset_category.dart';

enum MarketStatus {
  open,
  closed,
  preMarket,
  afterHours,
  alwaysOpen,
  unknown,
}

class MarketQuote {
  final String symbol;
  final String name;
  final AssetCategory category;
  final String exchange;
  final String currency;
  final double price;
  final double change;
  final double changePercent;
  final DateTime updatedAt;
  final MarketStatus marketStatus;

  const MarketQuote({
    required this.symbol,
    required this.name,
    required this.category,
    required this.exchange,
    required this.currency,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.updatedAt,
    required this.marketStatus,
  });

  bool get isPositive => change >= 0;
  bool get isNegative => change < 0;

  MarketQuote copyWith({
    String? symbol,
    String? name,
    AssetCategory? category,
    String? exchange,
    String? currency,
    double? price,
    double? change,
    double? changePercent,
    DateTime? updatedAt,
    MarketStatus? marketStatus,
  }) {
    return MarketQuote(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      category: category ?? this.category,
      exchange: exchange ?? this.exchange,
      currency: currency ?? this.currency,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      updatedAt: updatedAt ?? this.updatedAt,
      marketStatus: marketStatus ?? this.marketStatus,
    );
  }

  Map<String, Object?> toMap() => {
        'symbol': symbol,
        'name': name,
        'category': category.key,
        'exchange': exchange,
        'currency': currency,
        'price': price,
        'change': change,
        'changePercent': changePercent,
        'updatedAt': updatedAt.toIso8601String(),
        'marketStatus': marketStatus.name,
      };

  factory MarketQuote.fromMap(Map<String, Object?> map) {
    double toDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MarketQuote(
      symbol: (map['symbol'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      category: AssetCategoryX.fromKey(
        (map['category'] ?? '').toString(),
      ),
      exchange: (map['exchange'] ?? '').toString(),
      currency: (map['currency'] ?? '').toString(),
      price: toDouble(map['price']),
      change: toDouble(map['change']),
      changePercent: toDouble(map['changePercent']),
      updatedAt: DateTime.tryParse(
            (map['updatedAt'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      marketStatus: MarketStatus.values.firstWhere(
        (status) =>
            status.name == (map['marketStatus'] ?? '').toString(),
        orElse: () => MarketStatus.unknown,
      ),
    );
  }
}
