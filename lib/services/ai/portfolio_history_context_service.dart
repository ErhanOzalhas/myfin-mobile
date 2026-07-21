import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/portfolio_snapshot.dart';
import '../../repositories/portfolio_repository.dart';
import '../../repositories/portfolio_snapshot_repository.dart';
import '../portfolio_valuation_service.dart';

/// Builds historical portfolio facts so MyFin AI can answer questions about
/// past transactions, portfolio direction, and product-level history.
class PortfolioHistoryContextService {
  const PortfolioHistoryContextService({
    PortfolioRepository? portfolioRepository,
    PortfolioSnapshotRepository? snapshotRepository,
  }) : _portfolioRepository = portfolioRepository,
       _snapshotRepository = snapshotRepository;

  final PortfolioRepository? _portfolioRepository;
  final PortfolioSnapshotRepository? _snapshotRepository;

  Future<String> buildHistoricalFacts({
    required PortfolioValuation valuation,
    required String question,
  }) async {
    if (valuation.items.isEmpty) {
      return 'Portföy geçmişi için kullanılabilir varlık bulunmuyor.';
    }

    try {
      final transactions = await _loadTransactions();
      final snapshots = await _loadSnapshots();
      return buildHistoricalFactsFromData(
        valuation: valuation,
        question: question,
        transactions: transactions,
        snapshots: snapshots,
      );
    } catch (_) {
      return 'Portföy geçmişi şu anda yüklenemedi; yanıtı mevcut portföy görünümüne göre ver.';
    }
  }

  String buildHistoricalFactsFromData({
    required PortfolioValuation valuation,
    required String question,
    required List<Map<String, dynamic>> transactions,
    required List<PortfolioSnapshot> snapshots,
  }) {
    final trackedSymbols = _trackedSymbols(valuation, question);
    final relevantTransactions = transactions.where((transaction) {
      final symbol = (transaction['symbol'] ?? '').toString().trim().toUpperCase();
      return trackedSymbols.contains(symbol);
    }).toList()
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

    final buffer = StringBuffer()
      ..writeln('=== PORTFÖY GEÇMİŞ BAĞLAMI ===')
      ..writeln(
        'Bu bölüm kullanıcının kendi portföy geçmişinden üretildi. Kullanıcı '
        'ürün geçmişi, önceki işlemler, zaman içindeki değişim ve portföy evrimi ile ilgili soru sorarsa bu veriyi kullan.',
      )
      ..writeln('Odak kalemler: ${trackedSymbols.join(', ')}');

    if (relevantTransactions.isEmpty) {
      buffer.writeln(
        'İlgili ürünler için işlem geçmişi bulunamadı. Yalnızca mevcut portföy dağılımı üzerinden yorum yap.',
      );
    } else {
      final transactionSummary = summarizeTransactions(
        transactions: relevantTransactions,
        trackedSymbols: trackedSymbols,
      );
      buffer
        ..writeln('İşlem özeti:')
        ..writeln(transactionSummary);
    }

    final snapshotSummary = summarizeSnapshots(snapshots);
    buffer
      ..writeln('Portföy zaman serisi özeti:')
      ..writeln(snapshotSummary)
      ..writeln('=== YANIT KURALI ===')
      ..writeln(
        'Geçmiş veri eksikse bunu açıkça söyle. Tarih, işlem tipi ve yön değişimini '
        'mümkünse somut şekilde belirt. Kullanıcının kendi geçmişi ile piyasa haberini karıştırma.',
      );

    return buffer.toString().trim();
  }

  String summarizeTransactions({
    required List<Map<String, dynamic>> transactions,
    required Set<String> trackedSymbols,
  }) {
    if (transactions.isEmpty) {
      return 'İşlem geçmişi yok.';
    }

    final statsBySymbol = <String, _TransactionStats>{};
    for (final symbol in trackedSymbols) {
      statsBySymbol[symbol] = _TransactionStats(symbol: symbol);
    }

    for (final tx in transactions) {
      final symbol = (tx['symbol'] ?? '').toString().trim().toUpperCase();
      if (symbol.isEmpty) continue;
      final stats = statsBySymbol.putIfAbsent(
        symbol,
        () => _TransactionStats(symbol: symbol),
      );
      stats.register(tx);
    }

    final lines = <String>[
      'Toplam ilgili işlem: ${transactions.length}',
      'İlk işlem: ${_formatDate(_dateOf(transactions.last))}',
      'Son işlem: ${_formatDate(_dateOf(transactions.first))}',
    ];

    for (final symbol in trackedSymbols) {
      final stats = statsBySymbol[symbol];
      if (stats == null || stats.count == 0) continue;
      lines.add(stats.summaryLine);
    }

    lines.add('Son işlemler:');
    for (final tx in transactions.take(8)) {
      final type = (tx['type'] ?? 'İşlem').toString();
      final symbol = (tx['symbol'] ?? '-').toString().toUpperCase();
      final quantity = _toDouble(tx['quantity']);
      final price = _toDouble(tx['price']);
      lines.add(
        '- ${_formatDate(_dateOf(tx))}: $symbol için $type, miktar=${_number(quantity)}, fiyat=${_money(price)}',
      );
    }

    return lines.join('\n');
  }

  String summarizeSnapshots(List<PortfolioSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return 'Kayıtlı portföy snapshot geçmişi yok.';
    }

    final ordered = [...snapshots]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final latest = ordered.last;
    final earliest = ordered.first;
    final sevenDay = _closestSnapshotBefore(ordered, latest.capturedAt.subtract(const Duration(days: 7)));
    final thirtyDay = _closestSnapshotBefore(ordered, latest.capturedAt.subtract(const Duration(days: 30)));
    final ninetyDay = _closestSnapshotBefore(ordered, latest.capturedAt.subtract(const Duration(days: 90)));

    final lines = <String>[
      'Toplam snapshot: ${ordered.length}',
      'İlk snapshot: ${_formatDate(earliest.capturedAt)} toplam değer=${_money(earliest.totalValue)}',
      'Son snapshot: ${_formatDate(latest.capturedAt)} toplam değer=${_money(latest.totalValue)}, toplam maliyet=${_money(latest.totalCost)}, kâr/zarar=${_signedMoney(latest.profitLoss)}',
    ];

    if (sevenDay != null && sevenDay != latest) {
      lines.add(_snapshotDeltaLine('7 gün', sevenDay, latest));
    }
    if (thirtyDay != null && thirtyDay != latest) {
      lines.add(_snapshotDeltaLine('30 gün', thirtyDay, latest));
    }
    if (ninetyDay != null && ninetyDay != latest) {
      lines.add(_snapshotDeltaLine('90 gün', ninetyDay, latest));
    }

    return lines.join('\n');
  }

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    final snapshot = await (_portfolioRepository ?? PortfolioRepository.instance)
        .watchTransactions()
        .first
        .timeout(const Duration(seconds: 3));
    return snapshot.docs.map((doc) => doc.data()).toList(growable: false);
  }

  Future<List<PortfolioSnapshot>> _loadSnapshots() {
    final now = DateTime.now();
    return (_snapshotRepository ?? PortfolioSnapshotRepository.instance).getRange(
      start: now.subtract(const Duration(days: 90)),
      end: now,
    );
  }

  Set<String> _trackedSymbols(PortfolioValuation valuation, String question) {
    final lowerQuestion = question.toLowerCase();
    final matches = <String>{};

    for (final entry in valuation.items) {
      final symbol = entry.item.symbol.trim().toUpperCase();
      final name = entry.item.name.trim().toLowerCase();
      if (symbol.isEmpty) continue;
      if (lowerQuestion.contains(symbol.toLowerCase()) ||
          (name.isNotEmpty && lowerQuestion.contains(name))) {
        matches.add(symbol);
      }
    }

    if (matches.isNotEmpty) {
      return matches;
    }

    final sorted = [...valuation.items]
      ..sort(
        (a, b) => b.currentValueInBaseCurrency.compareTo(
          a.currentValueInBaseCurrency,
        ),
      );
    return sorted.take(3).map((entry) => entry.item.symbol.trim().toUpperCase()).toSet();
  }

  PortfolioSnapshot? _closestSnapshotBefore(
    List<PortfolioSnapshot> snapshots,
    DateTime target,
  ) {
    PortfolioSnapshot? result;
    for (final snapshot in snapshots) {
      if (snapshot.capturedAt.isAfter(target)) break;
      result = snapshot;
    }
    return result;
  }

  String _snapshotDeltaLine(
    String label,
    PortfolioSnapshot previous,
    PortfolioSnapshot latest,
  ) {
    final valueDelta = latest.totalValue - previous.totalValue;
    final percent = previous.totalValue <= 0
        ? 0.0
        : (valueDelta / previous.totalValue) * 100;
    return '$label değişim: ${_signedMoney(valueDelta)} (${_signedPercent(percent)})';
  }

  DateTime _dateOf(Map<String, dynamic> data) {
    final raw = data['transactionDate'] ?? data['createdAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  static String _money(double value) => '${_number(value)} TL';

  static String _signedMoney(double value) =>
      '${value > 0 ? '+' : ''}${_money(value)}';

  static String _signedPercent(double value) =>
      '${value > 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

  static String _number(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final chars = parts.first.split('').reversed.toList();
    final groups = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      groups.add(chars.skip(i).take(3).toList().reversed.join());
    }
    return '${groups.reversed.join('.')},${parts.last}';
  }
}

class _TransactionStats {
  _TransactionStats({required this.symbol});

  final String symbol;
  int buyCount = 0;
  int sellCount = 0;
  int count = 0;
  double boughtQuantity = 0;
  double soldQuantity = 0;
  double buyNotional = 0;
  double sellNotional = 0;

  void register(Map<String, dynamic> transaction) {
    count += 1;
    final type = (transaction['type'] ?? '').toString().trim().toLowerCase();
    final quantity = PortfolioHistoryContextService._toDouble(transaction['quantity']);
    final price = PortfolioHistoryContextService._toDouble(transaction['price']);
    final notional = quantity * price;

    if (type == 'satış' || type == 'satis') {
      sellCount += 1;
      soldQuantity += quantity;
      sellNotional += notional;
      return;
    }

    buyCount += 1;
    boughtQuantity += quantity;
    buyNotional += notional;
  }

  String get summaryLine {
    final netQuantity = boughtQuantity - soldQuantity;
    return '- $symbol: alış=$buyCount, satış=$sellCount, '
        'alınan miktar=${PortfolioHistoryContextService._number(boughtQuantity)}, '
        'satılan miktar=${PortfolioHistoryContextService._number(soldQuantity)}, '
        'net miktar=${PortfolioHistoryContextService._number(netQuantity)}, '
        'alış hacmi=${PortfolioHistoryContextService._money(buyNotional)}, '
        'satış hacmi=${PortfolioHistoryContextService._money(sellNotional)}';
  }
}
