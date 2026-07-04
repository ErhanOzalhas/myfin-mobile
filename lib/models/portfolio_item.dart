import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioItem {
  final String id;
  final String name;
  final String symbol;
  final String type;
  final double quantity;
  final double averagePrice;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PortfolioItem({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.averagePrice,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  });

  double get totalCost => quantity * averagePrice;

  factory PortfolioItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PortfolioItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      symbol: data['symbol'] as String? ?? '',
      type: data['type'] as String? ?? '',
      quantity: _toDouble(data['quantity']),
      averagePrice: _toDouble(data['averagePrice']),
      currency: data['currency'] as String? ?? 'TRY',
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'symbol': symbol,
      'type': type,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  PortfolioItem copyWith({
    String? id,
    String? name,
    String? symbol,
    String? type,
    double? quantity,
    double? averagePrice,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


