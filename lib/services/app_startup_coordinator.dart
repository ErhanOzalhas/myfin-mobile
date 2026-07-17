import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/portfolio_item.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/portfolio_repository.dart';
import 'market/market_favorites_service.dart';
import 'market/market_service.dart';
import 'user_cloud_service.dart';

class AppStartupCoordinator {
  AppStartupCoordinator._();

  static final AppStartupCoordinator instance = AppStartupCoordinator._();

  Future<void>? _criticalFuture;
  String? _preparedUserId;
  bool _secondaryStarted = false;

  Future<void> prepareCriticalData() async {
    final user = await _resolveUser();
    if (user == null) return;

    if (_preparedUserId == user.uid && _criticalFuture != null) {
      return _waitWithoutBlockingTooLong(_criticalFuture!);
    }

    _preparedUserId = user.uid;
    _secondaryStarted = false;
    final future = _prepareForUser(user);
    _criticalFuture = future;
    return _waitWithoutBlockingTooLong(future);
  }

  Future<void> _waitWithoutBlockingTooLong(Future<void> future) {
    return future.timeout(
      const Duration(milliseconds: 2400),
      onTimeout: () {
        debugPrint('STARTUP PRELOAD arka planda devam ediyor.');
      },
    );
  }

  Future<User?> _resolveUser() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current;

    try {
      return await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(milliseconds: 900),
      );
    } catch (_) {
      return FirebaseAuth.instance.currentUser;
    }
  }

  Future<void> _prepareForUser(User user) async {
    final profileFuture = _ignoreFailure(
      UserCloudService.createUserProfileIfNeeded(user),
      label: 'kullanıcı profili',
    );

    final portfolioFuture = _loadPortfolio();
    final transactionsFuture = _ignoreFailure(
      PortfolioRepository.instance.watchTransactions().first.timeout(
        const Duration(seconds: 2),
      ),
      label: 'işlem geçmişi',
    );

    final items = await portfolioFuture;

    // Ana sayfa ve Portföy sekmesindeki kartlar ilk görünür finansal içerik.
    // Favori fiyatlarını aynı anda başlatmak bağlantı havuzunu doldurup bu
    // kartları geciktiriyordu; önce portföy değerini hazırlıyoruz.
    await _ignoreFailure(
      DashboardRepository.instance.calculate(items),
      label: 'portföy özeti',
    );

    await Future.wait<void>([profileFuture, transactionsFuture]);
  }

  Future<List<PortfolioItem>> _loadPortfolio() async {
    try {
      return await PortfolioRepository.instance.watchPortfolio().first.timeout(
        const Duration(seconds: 2),
      );
    } catch (error) {
      debugPrint('STARTUP PRELOAD (portföy) atlandı: $error');
      return const [];
    }
  }

  void preloadSecondary() {
    if (_secondaryStarted) return;
    _secondaryStarted = true;

    unawaited(_preloadSecondaryInBackground());
  }

  Future<void> _preloadSecondaryInBackground() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _warmFavoriteQuotes(limit: 6);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _ignoreFailure(
      PortfolioRepository.instance.watchTransactions().first.timeout(
        const Duration(seconds: 2),
      ),
      label: 'ikincil işlem verileri',
    );
  }

  Future<void> _warmFavoriteQuotes({required int limit}) async {
    final favorites = MarketFavoritesService.instance.favorites.value
        .take(limit)
        .toList(growable: false);

    for (final favorite in favorites) {
      await _ignoreFailure(
        MarketService.instance.getQuote(
          favorite.asset.symbol,
          exchange: favorite.asset.exchange,
        ),
        label: '${favorite.asset.symbol} fiyatı',
      );
    }
  }

  Future<void> _ignoreFailure(
    Future<dynamic> operation, {
    required String label,
  }) async {
    try {
      await operation;
    } catch (error) {
      debugPrint('STARTUP PRELOAD ($label) atlandı: $error');
    }
  }
}
