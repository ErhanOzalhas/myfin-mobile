import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'models/asset_category.dart';
import 'models/market_quote.dart';
import 'registry/asset_info.dart';

class FavoriteMarketAsset {
  final AssetInfo asset;
  final MarketQuote? lastQuote;

  const FavoriteMarketAsset({required this.asset, this.lastQuote});
}

class MarketFavoritesService {
  MarketFavoritesService._() {
    FirebaseAuth.instance.authStateChanges().listen(_bindUser);
  }

  static final MarketFavoritesService instance = MarketFavoritesService._();

  static const _starterFavorites = <FavoriteMarketAsset>[
    FavoriteMarketAsset(
      asset: AssetInfo(
        symbol: 'AKBNK',
        name: 'Akbank',
        category: AssetCategory.bist,
        exchange: 'XIST',
        currency: 'TRY',
        countryCode: 'TR',
        provider: 'MarketRouter',
        supportStatus: AssetSupportStatus.live,
      ),
    ),
    FavoriteMarketAsset(
      asset: AssetInfo(
        symbol: 'ALARK',
        name: 'Alarko Holding',
        category: AssetCategory.bist,
        exchange: 'XIST',
        currency: 'TRY',
        countryCode: 'TR',
        provider: 'MarketRouter',
        supportStatus: AssetSupportStatus.live,
      ),
    ),
  ];

  final ValueNotifier<List<FavoriteMarketAsset>> favorites = ValueNotifier(
    _starterFavorites,
  );

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _favoritesSubscription;
  String? _boundUserId;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('marketFavorites');
  }

  Future<void> _bindUser(User? user) async {
    if (_boundUserId == user?.uid && _favoritesSubscription != null) return;

    await _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _boundUserId = user?.uid;

    if (user == null) {
      favorites.value = _starterFavorites;
      return;
    }

    await _seedStarterFavoritesIfNeeded(user.uid);

    _favoritesSubscription = _collection(user.uid).snapshots().listen(
      (snapshot) {
        final previousQuotes = <String, MarketQuote?>{
          for (final favorite in favorites.value)
            favorite.asset.symbol.toUpperCase(): favorite.lastQuote,
        };

        final loaded =
            snapshot.docs
                .map((doc) => _fromMap(doc.data()))
                .whereType<AssetInfo>()
                .map(
                  (asset) => FavoriteMarketAsset(
                    asset: asset,
                    lastQuote: previousQuotes[asset.symbol.toUpperCase()],
                  ),
                )
                .toList()
              ..sort((a, b) => a.asset.name.compareTo(b.asset.name));

        favorites.value = List.unmodifiable(loaded);
      },
      onError: (Object error) {
        debugPrint('FAVORITES WATCH ERROR: $error');
      },
    );
  }

  Future<void> _seedStarterFavoritesIfNeeded(String uid) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final profile = await userDoc.get();
      if (profile.data()?['marketFavoritesInitialized'] == true) return;

      final collection = _collection(uid);
      final existing = await collection.limit(1).get();
      final batch = FirebaseFirestore.instance.batch();

      if (existing.docs.isEmpty) {
        for (final favorite in _starterFavorites) {
          batch.set(
            collection.doc(_documentId(favorite.asset)),
            _toMap(favorite.asset),
          );
        }
      }

      batch.set(userDoc, {
        'marketFavoritesInitialized': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (error) {
      debugPrint('FAVORITES INITIALIZE ERROR: $error');
    }
  }

  bool contains(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    return favorites.value.any(
      (favorite) => favorite.asset.symbol.trim().toUpperCase() == normalized,
    );
  }

  Future<void> toggle(AssetInfo asset, {MarketQuote? quote}) async {
    final current = [...favorites.value];
    final normalized = asset.symbol.trim().toUpperCase();
    final index = current.indexWhere(
      (favorite) => favorite.asset.symbol.trim().toUpperCase() == normalized,
    );
    final removing = index >= 0;

    if (removing) {
      current.removeAt(index);
    } else {
      current.add(FavoriteMarketAsset(asset: asset, lastQuote: quote));
    }
    favorites.value = List.unmodifiable(current);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final document = _collection(user.uid).doc(_documentId(asset));
    try {
      if (removing) {
        await document.delete();
      } else {
        await document.set(_toMap(asset));
      }
    } catch (error) {
      debugPrint('FAVORITES SAVE ERROR: $error');
      favorites.value = List.unmodifiable(
        removing
            ? [...current, FavoriteMarketAsset(asset: asset, lastQuote: quote)]
            : current
                  .where(
                    (favorite) =>
                        favorite.asset.symbol.trim().toUpperCase() !=
                        normalized,
                  )
                  .toList(),
      );
    }
  }

  String _documentId(AssetInfo asset) {
    return '${asset.symbol}_${asset.exchange}'.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9_-]'),
      '_',
    );
  }

  Map<String, dynamic> _toMap(AssetInfo asset) {
    return {
      'symbol': asset.symbol,
      'name': asset.name,
      'category': asset.category.key,
      'exchange': asset.exchange,
      'currency': asset.currency,
      'countryCode': asset.countryCode,
      'provider': asset.provider,
      'providerAssetId': asset.providerAssetId,
      'supportStatus': asset.supportStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AssetInfo? _fromMap(Map<String, dynamic> data) {
    final symbol = (data['symbol'] ?? '').toString().trim();
    if (symbol.isEmpty) return null;

    final supportStatusName = (data['supportStatus'] ?? '').toString();
    final supportStatus = AssetSupportStatus.values.firstWhere(
      (status) => status.name == supportStatusName,
      orElse: () => AssetSupportStatus.catalogOnly,
    );

    return AssetInfo(
      symbol: symbol,
      name: (data['name'] ?? symbol).toString(),
      category: AssetCategoryX.fromKey((data['category'] ?? '').toString()),
      exchange: (data['exchange'] ?? '').toString(),
      currency: (data['currency'] ?? 'USD').toString(),
      countryCode: (data['countryCode'] ?? 'GLOBAL').toString(),
      provider: (data['provider'] ?? 'MarketRouter').toString(),
      providerAssetId: data['providerAssetId']?.toString(),
      supportStatus: supportStatus,
    );
  }
}
