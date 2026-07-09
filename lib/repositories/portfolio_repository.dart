import '../models/portfolio_item.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
Future<void> addTransaction(Map<String, dynamic> data) async {
  await _firestore.addTransaction(data);
}

Future<void> updateTransaction(
  String id,
  Map<String, dynamic> data,
) async {
  await _firestore.updateTransaction(id, data);
}

Future<void> deleteTransaction(String id) async {
  await _firestore.deleteTransaction(id);
}

Stream<QuerySnapshot<Map<String, dynamic>>> watchTransactions() {
  return _firestore.watchTransactions();
}
}