import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../registry/asset_info.dart';

class CoinGeckoCoinIndex {
  CoinGeckoCoinIndex._();

  static final CoinGeckoCoinIndex instance =
      CoinGeckoCoinIndex._();

  final http.Client _client = http.Client();
  final List<_CoinRecord> _coins = [];
  final Map<String, String> _preferredIdBySymbol = {};

  Future<void>? _loadingFuture;

  bool get isLoaded => _coins.isNotEmpty;

  Future<List<AssetInfo>> search(
    String query, {
    int limit = 12,
  }) async {
    final normalized = query.trim();

    if (normalized.length < 2) {
      return const [];
    }

    await _ensureLoaded();

    final results = <AssetInfo>[];

    for (final coin in _coins) {
      final score = coin.score(normalized);

      if (score <= 0) continue;

      results.add(
        AssetInfo(
          symbol: coin.symbol.toUpperCase(),
          name: coin.name,
          category: AssetCategory.crypto,
          exchange: 'CRYPTO',
          currency: 'USD',
          countryCode: 'GLOBAL',
          provider: 'CoinGecko',
          providerAssetId: coin.id,
          supportStatus: AssetSupportStatus.live,
          riskLevel: AssetRiskLevel.veryHigh,
          keywords: [
            coin.id,
            coin.symbol,
            coin.name,
            'crypto',
            'kripto',
          ],
          aiTags: const [
            'crypto',
            '24-7-market',
            'high-volatility',
          ],
        ),
      );

      if (results.length >= limit * 4) {
        break;
      }
    }

    results.sort(
      (first, second) => _score(second, normalized)
          .compareTo(_score(first, normalized)),
    );

    return results.take(limit).toList();
  }

  Future<String?> resolveId(String symbol) async {
    final normalized = symbol.trim().toUpperCase();

    final preferred = _preferredIdBySymbol[normalized];
    if (preferred != null) {
      return preferred;
    }

    await _ensureLoaded();

    final exactMatches = _coins
        .where(
          (coin) => coin.symbol.toUpperCase() == normalized,
        )
        .toList();

    if (exactMatches.isEmpty) {
      return null;
    }

    // CoinGecko listesinde aynı ticker birden fazla coin için bulunabilir.
    // En yaygın coinler için preferred kayıt, diğerlerinde ilk aktif kayıt
    // kullanılır. Kullanıcı aramadan seçim yaptığında rememberPreferred()
    // doğru ID'yi sabitler.
    return exactMatches.first.id;
  }

  void rememberPreferred({
    required String symbol,
    required String coinId,
  }) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    final normalizedId = coinId.trim();

    if (normalizedSymbol.isEmpty || normalizedId.isEmpty) {
      return;
    }

    _preferredIdBySymbol[normalizedSymbol] = normalizedId;
  }

  Future<void> _ensureLoaded() {
    if (_coins.isNotEmpty) {
      return Future.value();
    }

    return _loadingFuture ??= _load();
  }

  Future<void> _load() async {
    final uri = Uri.parse(
      'https://api.coingecko.com/api/v3/coins/list'
      '?include_platform=false',
    );

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    final demoKey =
        (dotenv.env['COINGECKO_API_KEY'] ?? '').trim();
    if (demoKey.isNotEmpty) {
      headers['x-cg-demo-api-key'] = demoKey;
    }

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'COINGECKO LIST HTTP ${response.statusCode}',
        );
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        return;
      }

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString().trim();
        final symbol =
            (map['symbol'] ?? '').toString().trim();
        final name = (map['name'] ?? '').toString().trim();

        if (id.isEmpty || symbol.isEmpty || name.isEmpty) {
          continue;
        }

        _coins.add(
          _CoinRecord(
            id: id,
            symbol: symbol,
            name: name,
          ),
        );
      }

      debugPrint(
        'COINGECKO CATALOG LOADED: ${_coins.length}',
      );
    } catch (error) {
      debugPrint('COINGECKO CATALOG ERROR: $error');
    } finally {
      _loadingFuture = null;
    }
  }

  int _score(AssetInfo asset, String query) {
    return asset.searchScore(query);
  }
}

class _CoinRecord {
  final String id;
  final String symbol;
  final String name;

  const _CoinRecord({
    required this.id,
    required this.symbol,
    required this.name,
  });

  int score(String query) {
    final q = query.trim().toUpperCase();
    final s = symbol.toUpperCase();
    final n = name.toUpperCase();
    final i = id.toUpperCase();

    if (s == q) return 100;
    if (n == q) return 95;
    if (s.startsWith(q)) return 90;
    if (n.startsWith(q)) return 80;
    if (s.contains(q)) return 70;
    if (n.contains(q)) return 60;
    if (i.contains(q)) return 50;
    return 0;
  }
}
