import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_profile.dart';
import 'profile_lock_service.dart';

class PortfolioProfileService {
  PortfolioProfileService._();

  static final PortfolioProfileService instance = PortfolioProfileService._();

  static const defaultProfileId = 'personal';
  static const _activeProfileStorageKey = 'myfin_active_portfolio_profile_v1';
  static const _profileCollections = <String>[
    'portfolioItems',
    'transactions',
    'cashMovements',
    'portfolioSnapshots',
    'assets',
    'debts',
    'marketFavorites',
  ];

  final ValueNotifier<String> activeProfileId = ValueNotifier(defaultProfileId);
  final ValueNotifier<bool> isReady = ValueNotifier(false);
  String? _initializedUserId;
  Future<void>? _initializing;

  FirebaseFirestore get _database => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _profiles(String uid) =>
      _database.collection('users').doc(uid).collection('profiles');

  DocumentReference<Map<String, dynamic>> profileDocument(
    String uid,
    String profileId,
  ) => _profiles(uid).doc(profileId);

  Future<void> initialize() {
    final uid = _user?.uid;
    if (uid == null) {
      activeProfileId.value = defaultProfileId;
      isReady.value = false;
      _initializedUserId = null;
      return Future.value();
    }
    if (_initializedUserId == uid && isReady.value) return Future.value();
    return _initializing ??= _initializeFor(uid).whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initializeFor(String uid) async {
    isReady.value = false;
    await _ensureDefaultProfileAndMigrate(uid);

    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString('$_activeProfileStorageKey::$uid');
    var selected = stored?.trim().isNotEmpty == true
        ? stored!
        : defaultProfileId;
    final selectedDocument = await _profiles(uid).doc(selected).get();
    if (!selectedDocument.exists) {
      selected = defaultProfileId;
    }

    _initializedUserId = uid;
    activeProfileId.value = selected;
    isReady.value = true;
  }

  Stream<List<PortfolioProfile>> watchProfiles() {
    final uid = _user?.uid;
    if (uid == null) return Stream.value(const []);
    return _profiles(uid).snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map(PortfolioProfile.fromFirestore)
          .toList(growable: false);
      profiles.sort((first, second) {
        if (first.isDefault != second.isDefault) {
          return first.isDefault ? -1 : 1;
        }
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      });
      return profiles;
    });
  }

  Future<void> selectProfile(String profileId) async {
    final uid = _user?.uid;
    if (uid == null || profileId == activeProfileId.value) return;

    // Seçim, watchProfiles ile gelen mevcut bir profil üzerinden yapılıyor.
    // Burada Firestore'u tekrar beklemek zayıf bağlantıda tiki eski profilde
    // bırakıyordu. Önce yerel durumu anında değiştir, ardından kalıcılaştır.
    activeProfileId.value = profileId;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_activeProfileStorageKey::$uid', profileId);
  }

  Future<String> createProfile({
    required String name,
    int colorValue = 0xFF7C3AED,
    String iconKey = 'person',
  }) async {
    final uid = _user?.uid;
    final normalizedName = name.trim();
    if (uid == null) throw StateError('Kullanıcı oturumu bulunamadı.');
    if (normalizedName.isEmpty) throw ArgumentError('Profil adı boş olamaz.');
    final document = _profiles(uid).doc();
    await document.set({
      'name': normalizedName,
      'colorValue': colorValue,
      'iconKey': iconKey,
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> updateProfile(
    String profileId, {
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    final uid = _user?.uid;
    if (uid == null) throw StateError('Kullanıcı oturumu bulunamadı.');
    await _profiles(uid).doc(profileId).update({
      'name': name.trim(),
      'colorValue': colorValue,
      'iconKey': iconKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProfile(String profileId) async {
    final uid = _user?.uid;
    if (uid == null) throw StateError('Kullanıcı oturumu bulunamadı.');
    if (profileId == defaultProfileId) {
      throw StateError('Kişisel profil silinemez.');
    }
    if (activeProfileId.value == profileId) {
      await selectProfile(defaultProfileId);
    }
    final profile = _profiles(uid).doc(profileId);
    for (final collectionName in _profileCollections) {
      await _deleteCollection(profile.collection(collectionName));
    }
    await ProfileLockService.instance.removeLock(profileId);
    await profile.delete();
  }

  Future<void> _ensureDefaultProfileAndMigrate(String uid) async {
    final user = _database.collection('users').doc(uid);
    final profile = _profiles(uid).doc(defaultProfileId);
    final snapshot = await profile.get();
    if (snapshot.data()?['migrationCompleted'] == true) return;

    await profile.set({
      'name': 'Kişisel',
      'colorValue': 0xFF0284C7,
      'iconKey': 'person',
      'isDefault': true,
      'createdAt':
          snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final collectionName in _profileCollections) {
      await _copyCollection(
        user.collection(collectionName),
        profile.collection(collectionName),
      );
    }

    await profile.set({
      'migrationCompleted': true,
      'migratedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _copyCollection(
    CollectionReference<Map<String, dynamic>> source,
    CollectionReference<Map<String, dynamic>> destination,
  ) async {
    final sourceSnapshot = await source.get();
    if (sourceSnapshot.docs.isEmpty) return;
    final destinationSnapshot = await destination.limit(1).get();
    if (destinationSnapshot.docs.isNotEmpty) return;

    for (var offset = 0; offset < sourceSnapshot.docs.length; offset += 400) {
      final proposedEnd = offset + 400;
      final end = proposedEnd < sourceSnapshot.docs.length
          ? proposedEnd
          : sourceSnapshot.docs.length;
      final batch = _database.batch();
      for (final document in sourceSnapshot.docs.sublist(offset, end)) {
        batch.set(destination.doc(document.id), document.data());
      }
      await batch.commit();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _database.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}
