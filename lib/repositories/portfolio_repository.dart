import '../models/portfolio_item.dart';
import '../services/firestore_service.dart';

class PortfolioRepository {
  PortfolioRepository._();

  static final PortfolioRepository instance = PortfolioRepository._();

  final FirestoreService _firestore = FirestoreService.instance;

  Stream<List<PortfolioItem>> watchPortfolio() {
    return _firestore
        .watchPortfolioItems()
        .map(
          (snapshot) => snapshot.docs
              .map(PortfolioItem.fromFirestore)
              .toList(),
        );
  }

  Future<void> addPortfolioItem(PortfolioItem item) async {
    await _firestore.addPortfolioItem(item.toFirestore());
  }

  Future<void> updatePortfolioItem(PortfolioItem item) async {
    await _firestore.updatePortfolioItem(
      item.id,
      item.toFirestore(),
    );
  }

  Future<void> deletePortfolioItem(String id) async {
    await _firestore.deletePortfolioItem(id);
  }
}