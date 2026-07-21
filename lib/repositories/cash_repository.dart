import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cash_movement.dart';
import '../services/firestore_service.dart';

class CashRepository {
  CashRepository._();

  static final CashRepository instance = CashRepository._();
  final FirestoreService _firestore = FirestoreService.instance;
  CashBalanceSnapshot _latest = CashBalanceSnapshot.empty;

  CashBalanceSnapshot get latest => _latest;

  Stream<CashBalanceSnapshot> watchBalance() {
    return _firestore.watchCashMovements().map((snapshot) {
      final movements = snapshot.docs
          .map(CashMovement.fromFirestore)
          .toList(growable: false);
      _latest = CashBalanceSnapshot.fromMovements(movements);
      return _latest;
    });
  }

  Future<CashBalanceSnapshot> getBalance() => watchBalance().first;

  Future<void> addManualMovement({
    required CashMovementType type,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Nakit tutarı sıfırdan büyük olmalıdır.');
    }
    final signedAmount = type == CashMovementType.withdrawal ? -amount : amount;
    if (signedAmount < 0) {
      final current = await getBalance();
      if (current.balance + signedAmount < -0.005) {
        throw StateError('Nakit bakiyesi yetersiz.');
      }
    }
    await _firestore.addCashMovement({
      'type': type.name,
      'amount': signedAmount,
      'movementDate': Timestamp.fromDate(date),
      'note': note.trim(),
      'source': 'manual',
    });
  }

  Future<void> updateManualMovement({
    required CashMovement movement,
    required double amount,
    String note = '',
  }) async {
    if (movement.transactionId != null) {
      throw StateError('İşleme bağlı nakit hareketi buradan düzenlenemez.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Nakit tutarı sıfırdan büyük olmalıdır.');
    }
    final signedAmount = movement.type == CashMovementType.withdrawal
        ? -amount
        : amount;
    final current = await getBalance();
    if (current.balance - movement.amount + signedAmount < -0.005) {
      throw StateError('Bu değişiklik nakit bakiyesini negatife düşürür.');
    }
    await _firestore.updateCashMovement(movement.id, {
      'amount': signedAmount,
      'note': note.trim(),
    });
  }

  Future<void> deleteManualMovement(CashMovement movement) async {
    if (movement.transactionId != null) {
      throw StateError('İşleme bağlı nakit hareketi buradan silinemez.');
    }
    final current = await getBalance();
    if (current.balance - movement.amount < -0.005) {
      throw StateError('Bu hareket silinirse nakit bakiyesi negatife düşer.');
    }
    await _firestore.deleteCashMovement(movement.id);
  }

  Future<void> syncTransactionMovement({
    required String transactionId,
    required String transactionType,
    required bool usesCash,
    required double amountTry,
    required DateTime date,
    required String symbol,
  }) async {
    if (!usesCash) {
      await _firestore.upsertTransactionCashMovement(transactionId, null);
      return;
    }
    if (transactionType == 'Alış') {
      final current = await getBalance();
      final existing = current.movements
          .where((item) => item.transactionId == transactionId)
          .fold<double>(0, (total, item) => total + item.amount);
      if (current.balance - existing - amountTry < -0.005) {
        throw StateError('TL nakit bakiyesi bu alış için yetersiz.');
      }
    }
    final isBuy = transactionType == 'Alış';
    await _firestore.upsertTransactionCashMovement(transactionId, {
      'type': isBuy ? CashMovementType.buy.name : CashMovementType.sell.name,
      'amount': isBuy ? -amountTry : amountTry,
      'movementDate': Timestamp.fromDate(date),
      'note': '$symbol ${isBuy ? 'alışı' : 'satışı'}',
      'source': 'transaction',
    });
  }
}
