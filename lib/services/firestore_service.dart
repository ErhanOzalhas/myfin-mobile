import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'portfolio_profile_service.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  bool get isLoggedIn => _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _db.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _currentUserDoc() {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }

    return _usersCollection.doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _profileSubCollection(String name) {
    return _currentUserDoc()
        .collection('profiles')
        .doc(PortfolioProfileService.instance.activeProfileId.value)
        .collection(name);
  }

  Stream<T> _profileAwareStream<T>(Stream<T> Function() createStream) {
    late final StreamController<T> controller;
    StreamSubscription<T>? subscription;
    var bindingRevision = 0;

    Future<void> bind() async {
      final revision = ++bindingRevision;
      await subscription?.cancel();
      if (controller.isClosed || revision != bindingRevision) return;
      subscription = createStream().listen(
        controller.add,
        onError: controller.addError,
      );
    }

    void profileChanged() {
      unawaited(bind());
    }

    controller = StreamController<T>(
      onListen: () {
        PortfolioProfileService.instance.activeProfileId.addListener(
          profileChanged,
        );
        unawaited(bind());
      },
      onCancel: () async {
        bindingRevision++;
        PortfolioProfileService.instance.activeProfileId.removeListener(
          profileChanged,
        );
        await subscription?.cancel();
        subscription = null;
      },
    );
    return controller.stream;
  }

  CollectionReference<Map<String, dynamic>> get _portfolioItemsCollection {
    return _profileSubCollection('portfolioItems');
  }

  CollectionReference<Map<String, dynamic>> get _transactionsCollection {
    return _profileSubCollection('transactions');
  }

  CollectionReference<Map<String, dynamic>> get _cashMovementsCollection {
    return _profileSubCollection('cashMovements');
  }

  CollectionReference<Map<String, dynamic>> get _portfolioSnapshotsCollection {
    return _profileSubCollection('portfolioSnapshots');
  }

  Future<void> createOrUpdateUserProfile({
    required String email,
    String? displayName,
  }) async {
    await _currentUserDoc().set({
      'email': email,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final snapshot = await _currentUserDoc().get();
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCurrentUserProfile() {
    return _currentUserDoc().snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addAsset({
    required String name,
    required String type,
    required double amount,
    required String currency,
  }) async {
    return _profileSubCollection('assets').add({
      'name': name,
      'type': type,
      'amount': amount,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAssets() {
    return _profileAwareStream(
      () => _profileSubCollection(
        'assets',
      ).orderBy('createdAt', descending: true).snapshots(),
    );
  }

  Future<void> updateAsset({
    required String assetId,
    required Map<String, dynamic> data,
  }) async {
    await _profileSubCollection(
      'assets',
    ).doc(assetId).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteAsset(String assetId) async {
    await _profileSubCollection('assets').doc(assetId).delete();
  }

  Future<DocumentReference<Map<String, dynamic>>> addDebt({
    required String name,
    required double amount,
    required String currency,
    String? note,
  }) async {
    return _profileSubCollection('debts').add({
      'name': name,
      'amount': amount,
      'currency': currency,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDebts() {
    return _profileAwareStream(
      () => _profileSubCollection(
        'debts',
      ).orderBy('createdAt', descending: true).snapshots(),
    );
  }

  Future<void> updateDebt({
    required String debtId,
    required Map<String, dynamic> data,
  }) async {
    await _profileSubCollection(
      'debts',
    ).doc(debtId).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteDebt(String debtId) async {
    await _profileSubCollection('debts').doc(debtId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPortfolioItems() {
    return _profileAwareStream(
      () => _portfolioItemsCollection
          .orderBy('createdAt', descending: true)
          .snapshots(),
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> addPortfolioItem(
    Map<String, dynamic> data,
  ) async {
    return _portfolioItemsCollection.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePortfolioItem(String id, Map<String, dynamic> data) async {
    await _portfolioItemsCollection.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePortfolioItem(String id) async {
    await _portfolioItemsCollection.doc(id).delete();
  }

  Future<DocumentReference<Map<String, dynamic>>> addTransaction(
    Map<String, dynamic> data,
  ) async {
    return _transactionsCollection.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _transactionsCollection.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsCollection.doc(id).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTransactions() {
    return _profileAwareStream(
      () => _transactionsCollection
          .orderBy('transactionDate', descending: true)
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCashMovements() {
    return _profileAwareStream(
      () => _cashMovementsCollection
          .orderBy('movementDate', descending: true)
          .snapshots(),
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> addCashMovement(
    Map<String, dynamic> data,
  ) {
    return _cashMovementsCollection.add({
      ...data,
      'currency': 'TRY',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCashMovement(String id, Map<String, dynamic> data) {
    return _cashMovementsCollection.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCashMovement(String id) {
    return _cashMovementsCollection.doc(id).delete();
  }

  Future<void> upsertTransactionCashMovement(
    String transactionId,
    Map<String, dynamic>? data,
  ) async {
    final reference = _cashMovementsCollection.doc('tx_$transactionId');
    if (data == null) {
      final snapshot = await reference.get();
      if (snapshot.exists) await reference.delete();
      return;
    }
    await reference.set({
      ...data,
      'transactionId': transactionId,
      'currency': 'TRY',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertPortfolioSnapshot(
    String dateKey,
    Map<String, dynamic> data,
  ) async {
    await _portfolioSnapshotsCollection.doc(dateKey).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPortfolioSnapshots({
    required String startDateKey,
    required String endDateKey,
  }) {
    return _portfolioSnapshotsCollection
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endDateKey)
        .orderBy(FieldPath.documentId)
        .get();
  }
}
