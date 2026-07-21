import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/cash_movement.dart';

void main() {
  final date = DateTime(2026, 7, 21);

  test('cash ledger keeps buys and sells internal to the account', () {
    final snapshot = CashBalanceSnapshot.fromMovements([
      CashMovement(
        id: 'deposit',
        type: CashMovementType.deposit,
        amount: 100000,
        movementDate: date,
      ),
      CashMovement(
        id: 'buy',
        type: CashMovementType.buy,
        amount: -30000,
        movementDate: date,
      ),
      CashMovement(
        id: 'sell',
        type: CashMovementType.sell,
        amount: 12500,
        movementDate: date,
      ),
      CashMovement(
        id: 'withdrawal',
        type: CashMovementType.withdrawal,
        amount: -2500,
        movementDate: date,
      ),
    ]);

    expect(snapshot.balance, 80000);
    expect(snapshot.movements, hasLength(4));
  });

  test('movement list is immutable', () {
    final snapshot = CashBalanceSnapshot.fromMovements([
      CashMovement(
        id: 'deposit',
        type: CashMovementType.deposit,
        amount: 1000,
        movementDate: date,
      ),
    ]);

    expect(
      () => snapshot.movements.add(
        CashMovement(
          id: 'other',
          type: CashMovementType.deposit,
          amount: 1,
          movementDate: date,
        ),
      ),
      throwsUnsupportedError,
    );
  });
}
