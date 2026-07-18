import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.dateKey,
    required this.capturedAt,
    required this.totalValue,
    required this.totalCost,
    required this.profitLoss,
    required this.assetCount,
    required this.categoryValues,
  });

  final String dateKey;
  final DateTime capturedAt;
  final double totalValue;
  final double totalCost;
  final double profitLoss;
  final int assetCount;
  final Map<String, double> categoryValues;

  factory PortfolioSnapshot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawCategories = data['categoryValues'];
    final categories = <String, double>{};
    if (rawCategories is Map) {
      for (final entry in rawCategories.entries) {
        categories[entry.key.toString()] = _asDouble(entry.value);
      }
    }

    final rawCapturedAt = data['capturedAt'];
    return PortfolioSnapshot(
      dateKey: document.id,
      capturedAt: rawCapturedAt is Timestamp
          ? rawCapturedAt.toDate()
          : DateTime.tryParse(document.id) ?? DateTime.now(),
      totalValue: _asDouble(data['totalValue']),
      totalCost: _asDouble(data['totalCost']),
      profitLoss: _asDouble(data['profitLoss']),
      assetCount: (data['assetCount'] as num?)?.toInt() ?? 0,
      categoryValues: categories,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dateKey': dateKey,
      'timezone': 'Europe/Istanbul',
      'capturedAt': Timestamp.fromDate(capturedAt),
      'totalValue': totalValue,
      'totalCost': totalCost,
      'profitLoss': profitLoss,
      'assetCount': assetCount,
      'categoryValues': categoryValues,
    };
  }

  static double _asDouble(dynamic value) {
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }
}
