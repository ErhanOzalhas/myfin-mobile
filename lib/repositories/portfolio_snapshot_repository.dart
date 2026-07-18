import '../models/portfolio_snapshot.dart';
import '../services/firestore_service.dart';

class PortfolioSnapshotRepository {
  PortfolioSnapshotRepository._();

  static final PortfolioSnapshotRepository instance =
      PortfolioSnapshotRepository._();

  final FirestoreService _firestore = FirestoreService.instance;

  Future<void> upsert(PortfolioSnapshot snapshot) {
    return _firestore.upsertPortfolioSnapshot(
      snapshot.dateKey,
      snapshot.toFirestore(),
    );
  }

  Future<List<PortfolioSnapshot>> getRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final result = await _firestore.getPortfolioSnapshots(
      startDateKey: dateKey(start),
      endDateKey: dateKey(end),
    );
    return result.docs.map(PortfolioSnapshot.fromFirestore).toList();
  }

  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
