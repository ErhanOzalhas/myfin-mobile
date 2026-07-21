import 'package:cloud_firestore/cloud_firestore.dart';

enum CashMovementType { deposit, withdrawal, buy, sell, adjustment }

class CashMovement {
  const CashMovement({
    required this.id,
    required this.type,
    required this.amount,
    required this.movementDate,
    this.note = '',
    this.transactionId,
  });

  final String id;
  final CashMovementType type;

  /// Signed TRY amount. Positive values increase cash.
  final double amount;
  final DateTime movementDate;
  final String note;
  final String? transactionId;

  factory CashMovement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawDate = data['movementDate'];
    return CashMovement(
      id: document.id,
      type: CashMovementType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => CashMovementType.adjustment,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      movementDate: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      note: (data['note'] ?? '').toString(),
      transactionId: data['transactionId']?.toString(),
    );
  }
}

class CashBalanceSnapshot {
  const CashBalanceSnapshot({required this.balance, required this.movements});

  final double balance;
  final List<CashMovement> movements;

  static const empty = CashBalanceSnapshot(balance: 0, movements: []);

  factory CashBalanceSnapshot.fromMovements(List<CashMovement> movements) {
    return CashBalanceSnapshot(
      balance: movements.fold<double>(
        0,
        (total, movement) => total + movement.amount,
      ),
      movements: List.unmodifiable(movements),
    );
  }
}
