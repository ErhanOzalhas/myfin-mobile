import '../registry/asset_info.dart';
import '../registry/asset_registry.dart';
import 'coingecko_coin_index.dart';
import 'twelve_data_asset_search_service.dart';

class UnifiedAssetSearchService {
  UnifiedAssetSearchService({
    TwelveDataAssetSearchService? twelveData,
  }) : _twelveData =
            twelveData ?? TwelveDataAssetSearchService();

  final TwelveDataAssetSearchService _twelveData;

  Future<List<AssetInfo>> search(
    String query, {
    int limit = 15,
  }) async {
    final normalized = query.trim();

    if (normalized.length < 2) {
      return const [];
    }

    final local = AssetRegistry.search(normalized);

    final remoteResults = await Future.wait([
      _twelveData.search(
        normalized,
        limit: limit,
      ),
      CoinGeckoCoinIndex.instance.search(
        normalized,
        limit: limit,
      ),
    ]);

    final merged = <String, AssetInfo>{};

    for (final asset in [
      ...local,
      ...remoteResults.expand((items) => items),
    ]) {
      final providerId =
          asset.providerAssetId?.toUpperCase() ?? '';
      final key =
          '${asset.provider.toUpperCase()}::'
          '$providerId::'
          '${asset.symbol.toUpperCase()}::'
          '${asset.exchange.toUpperCase()}';

      merged.putIfAbsent(key, () => asset);
    }

    final results = merged.values.toList()
      ..sort(
        (first, second) {
          int priority(AssetInfo a) {
            final q = normalized.toUpperCase();
            final sym = a.symbol.toUpperCase();
            final name = a.name.toUpperCase();

            if (sym == q) return 5000;
            if (sym.startsWith(q)) return 4000;
            if (name.startsWith(q)) return 3000;
            if (name.contains(q)) return 2000;
            return a.searchScore(normalized);
          }

          final scoreComparison =
              priority(second).compareTo(priority(first));

          if (scoreComparison != 0) {
            return scoreComparison;
          }

          // Yerel katalog kayıtları eşit puanda önce gösterilir.
          final firstLocal =
              first.provider == 'MarketRouter' ||
              first.provider == 'TurkeyGoldProvider';
          final secondLocal =
              second.provider == 'MarketRouter' ||
              second.provider == 'TurkeyGoldProvider';

          if (firstLocal == secondLocal) return 0;
          return firstLocal ? -1 : 1;
        },
      );

    return results.take(limit).toList();
  }

  void close() {
    _twelveData.close();
  }
}
