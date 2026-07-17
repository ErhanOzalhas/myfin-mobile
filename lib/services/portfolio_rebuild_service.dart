import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/portfolio_item.dart';
import '../repositories/portfolio_repository.dart';

class PortfolioRebuildService {
  const PortfolioRebuildService();

  Future<void> rebuildFromTransactions() async {
    final repository = PortfolioRepository.instance;

    final transactionSnapshot = await repository.watchTransactions().first;
    final transactions = transactionSnapshot.docs.toList();

    transactions.sort((a, b) {
      final aDate = _dateFrom(a.data()['transactionDate']);
      final bDate = _dateFrom(b.data()['transactionDate']);
      return aDate.compareTo(bDate);
    });

    final existingItems = await repository.watchPortfolio().first;
    for (final item in existingItems) {
      await repository.deletePortfolioItem(item.id);
    }

    final positions = <String, _PositionAccumulator>{};

    for (final doc in transactions) {
      final data = doc.data();
      debugPrint(
        'REBUILD TX => symbol=${data['symbol']} | assetName=${data['assetName']} | assetType=${data['assetType']} | type=${data['type']}',
      );
      final symbol = (data['symbol'] ?? '').toString().trim().toUpperCase();
      if (symbol.isEmpty) continue;

      final transactionType = (data['type'] ?? 'Alış').toString();
      final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
      final price = (data['price'] as num?)?.toDouble() ?? 0;

      if (quantity <= 0 || price <= 0) continue;

      final position = positions.putIfAbsent(
        symbol,
        () => _PositionAccumulator(
          symbol: symbol,
          name: _resolveAssetName(data, symbol),
          assetType: _resolveAssetType(data, symbol),
          currency: (data['currency'] ?? 'TRY').toString(),
        ),
      );

      final originalBuy = _originalBuyBeforeTypeChange(data);
      if (transactionType == 'Satış' && originalBuy != null) {
        position.buy(originalBuy.$1, originalBuy.$2);
      }

      if (transactionType == 'Satış') {
        position.sell(quantity);
      } else {
        position.buy(quantity, price);
      }
    }

    for (final position in positions.values) {
      if (position.quantity <= 0) continue;

      await repository.addPortfolioItem(
        PortfolioItem(
          id: '',
          name: position.name,
          symbol: position.symbol,
          type: position.assetType,
          quantity: position.quantity,
          averagePrice: position.averagePrice,
          currency: position.currency,
        ),
      );
    }
  }

  (double, double)? _originalBuyBeforeTypeChange(Map<String, dynamic> data) {
    final history = data['changeHistory'];
    if (history is! List || history.isEmpty) return null;
    final firstChange = history.first;
    if (firstChange is! Map) return null;
    final before = firstChange['before'];
    if (before is! Map || (before['type'] ?? '').toString() != 'Alış') {
      return null;
    }
    final currentType = (data['type'] ?? '').toString();
    if (currentType != 'Satış') return null;
    final quantity = (before['quantity'] as num?)?.toDouble() ?? 0;
    final price = (before['price'] as num?)?.toDouble() ?? 0;
    if (quantity <= 0 || price <= 0) return null;
    return (quantity, price);
  }

  DateTime _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _resolveAssetName(Map<String, dynamic> data, String symbol) {
    final assetName = (data['assetName'] ?? '').toString().trim();
    if (assetName.isNotEmpty) return assetName;

    switch (symbol) {
      case 'USD':
        return 'Amerikan Doları';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'İngiliz Sterlini';
      case 'CHF':
        return 'İsviçre Frangı';
      case 'XAU':
      case 'ALTIN':
      case 'GAU':
        return 'Gram Altın';
      case 'BTC':
        return 'Bitcoin';
      case 'ETH':
        return 'Ethereum';
      case 'SOL':
        return 'Solana';
      default:
        return symbol;
    }
  }

  String _resolveAssetType(Map<String, dynamic> data, String symbol) {
    final assetType = (data['assetType'] ?? '').toString().trim();
    if (assetType.isNotEmpty) return assetType;

    final assetName = (data['assetName'] ?? '').toString().toUpperCase();
    final normalized = symbol.toUpperCase();

    if (normalized == 'USD' ||
        normalized == 'EUR' ||
        normalized == 'GBP' ||
        normalized == 'CHF' ||
        assetName.contains('DOLAR') ||
        assetName.contains('EURO') ||
        assetName.contains('STERLIN') ||
        assetName.contains('FRANG')) {
      return 'Döviz';
    }

    if (normalized == 'XAU' ||
        normalized == 'ALTIN' ||
        normalized == 'GAU' ||
        normalized == 'XAUUSD' ||
        assetName.contains('ALTIN')) {
      return 'Altın';
    }

    if (normalized == 'BTC' ||
        normalized == 'ETH' ||
        normalized == 'SOL' ||
        assetName.contains('BITCOIN') ||
        assetName.contains('ETHEREUM') ||
        assetName.contains('SOLANA')) {
      return 'Kripto';
    }

    return 'Hisse';
  }
}

class _PositionAccumulator {
  final String symbol;
  final String name;
  final String assetType;
  final String currency;

  double quantity = 0;
  double totalCost = 0;

  _PositionAccumulator({
    required this.symbol,
    required this.name,
    required this.assetType,
    required this.currency,
  });

  double get averagePrice {
    if (quantity <= 0) return 0;
    return totalCost / quantity;
  }

  void buy(double addedQuantity, double unitPrice) {
    quantity += addedQuantity;
    totalCost += addedQuantity * unitPrice;
  }

  void sell(double soldQuantity) {
    if (quantity <= 0) return;

    final removableQuantity = soldQuantity > quantity ? quantity : soldQuantity;
    final currentAverage = averagePrice;

    quantity -= removableQuantity;
    totalCost -= removableQuantity * currentAverage;

    if (quantity <= 0) {
      quantity = 0;
      totalCost = 0;
    }
  }
}
