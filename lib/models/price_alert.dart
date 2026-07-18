enum PriceAlertDirection { above, below }

enum PriceAlertRepeat { once, repeating }

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.currency,
    required this.targetPrice,
    required this.direction,
    required this.repeat,
    required this.enabled,
    required this.createdAt,
    this.lastObservedPrice,
    this.lastTriggeredAt,
  });

  final String id;
  final String symbol;
  final String name;
  final String exchange;
  final String currency;
  final double targetPrice;
  final PriceAlertDirection direction;
  final PriceAlertRepeat repeat;
  final bool enabled;
  final DateTime createdAt;
  final double? lastObservedPrice;
  final DateTime? lastTriggeredAt;

  bool isTriggeredBy(double price) {
    return direction == PriceAlertDirection.above
        ? price >= targetPrice
        : price <= targetPrice;
  }

  PriceAlert copyWith({
    bool? enabled,
    double? lastObservedPrice,
    DateTime? lastTriggeredAt,
    bool clearLastTriggeredAt = false,
  }) {
    return PriceAlert(
      id: id,
      symbol: symbol,
      name: name,
      exchange: exchange,
      currency: currency,
      targetPrice: targetPrice,
      direction: direction,
      repeat: repeat,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      lastObservedPrice: lastObservedPrice ?? this.lastObservedPrice,
      lastTriggeredAt: clearLastTriggeredAt
          ? null
          : lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'exchange': exchange,
    'currency': currency,
    'targetPrice': targetPrice,
    'direction': direction.name,
    'repeat': repeat.name,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'lastObservedPrice': lastObservedPrice,
    'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: (json['id'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      exchange: (json['exchange'] ?? '').toString(),
      currency: (json['currency'] ?? 'TRY').toString(),
      targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0,
      direction: PriceAlertDirection.values.firstWhere(
        (value) => value.name == json['direction'],
        orElse: () => PriceAlertDirection.above,
      ),
      repeat: PriceAlertRepeat.values.firstWhere(
        (value) => value.name == json['repeat'],
        orElse: () => PriceAlertRepeat.once,
      ),
      enabled: json['enabled'] as bool? ?? true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      lastObservedPrice: (json['lastObservedPrice'] as num?)?.toDouble(),
      lastTriggeredAt: DateTime.tryParse(
        (json['lastTriggeredAt'] ?? '').toString(),
      ),
    );
  }
}
