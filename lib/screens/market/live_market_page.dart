import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../services/market/market_service.dart';
import '../../services/market/market_favorites_service.dart';
import '../../services/market/models/asset_category.dart';
import '../../services/market/models/market_quote.dart';
import '../../services/market/registry/asset_info.dart';
import '../../services/market/search/unified_asset_search_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../utils/no_animation_route.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/common/thin_divider.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../transactions/transaction_entry_page.dart';

class LiveMarketPage extends StatefulWidget {
  const LiveMarketPage({super.key});

  @override
  State<LiveMarketPage> createState() => _LiveMarketPageState();
}

class _LiveMarketPageState extends State<LiveMarketPage> {
  static const int _categoryItemLimit = 25;

  static const _assetsByCategory = <String, List<_MarketAssetDefinition>>{
    'BIST': [
      _MarketAssetDefinition('AKBNK', 'Akbank', 'BIST', 'XIST'),
      _MarketAssetDefinition('ALARK', 'Alarko Holding', 'BIST', 'XIST'),
      _MarketAssetDefinition('ASELS', 'Aselsan', 'BIST', 'XIST'),
      _MarketAssetDefinition('BIMAS', 'BİM Birleşik Mağazalar', 'BIST', 'XIST'),
      _MarketAssetDefinition('EKGYO', 'Emlak Konut GYO', 'BIST', 'XIST'),
      _MarketAssetDefinition('ENJSA', 'Enerjisa Enerji', 'BIST', 'XIST'),
      _MarketAssetDefinition('EREGL', 'Ereğli Demir Çelik', 'BIST', 'XIST'),
      _MarketAssetDefinition('FROTO', 'Ford Otosan', 'BIST', 'XIST'),
      _MarketAssetDefinition('GARAN', 'Garanti BBVA', 'BIST', 'XIST'),
      _MarketAssetDefinition('GUBRF', 'Gübre Fabrikaları', 'BIST', 'XIST'),
      _MarketAssetDefinition('HEKTS', 'Hektaş', 'BIST', 'XIST'),
      _MarketAssetDefinition('ISCTR', 'Türkiye İş Bankası C', 'BIST', 'XIST'),
      _MarketAssetDefinition('KCHOL', 'Koç Holding', 'BIST', 'XIST'),
      _MarketAssetDefinition('KOZAL', 'Koza Altın', 'BIST', 'XIST'),
      _MarketAssetDefinition('KRDMD', 'Kardemir D', 'BIST', 'XIST'),
      _MarketAssetDefinition('MGROS', 'Migros', 'BIST', 'XIST'),
      _MarketAssetDefinition('PETKM', 'Petkim', 'BIST', 'XIST'),
      _MarketAssetDefinition('PGSUS', 'Pegasus', 'BIST', 'XIST'),
      _MarketAssetDefinition('SAHOL', 'Sabancı Holding', 'BIST', 'XIST'),
      _MarketAssetDefinition('SASA', 'Sasa Polyester', 'BIST', 'XIST'),
      _MarketAssetDefinition('SISE', 'Şişecam', 'BIST', 'XIST'),
      _MarketAssetDefinition('TCELL', 'Turkcell', 'BIST', 'XIST'),
      _MarketAssetDefinition('THYAO', 'Türk Hava Yolları', 'BIST', 'XIST'),
      _MarketAssetDefinition('TOASO', 'Tofaş', 'BIST', 'XIST'),
      _MarketAssetDefinition('TUPRS', 'Tüpraş', 'BIST', 'XIST'),
    ],
    'ABD': [
      _MarketAssetDefinition('AAPL', 'Apple', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('MSFT', 'Microsoft', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('NVDA', 'NVIDIA', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('AMZN', 'Amazon', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('GOOGL', 'Alphabet', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('META', 'Meta Platforms', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('TSLA', 'Tesla', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('AVGO', 'Broadcom', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('NFLX', 'Netflix', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('AMD', 'AMD', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('INTC', 'Intel', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('ADBE', 'Adobe', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('QCOM', 'Qualcomm', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('COST', 'Costco', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('PEP', 'PepsiCo', 'ABD', 'NASDAQ'),
      _MarketAssetDefinition('JPM', 'JPMorgan Chase', 'ABD', 'NYSE'),
      _MarketAssetDefinition('V', 'Visa', 'ABD', 'NYSE'),
      _MarketAssetDefinition('MA', 'Mastercard', 'ABD', 'NYSE'),
      _MarketAssetDefinition('WMT', 'Walmart', 'ABD', 'NYSE'),
      _MarketAssetDefinition('KO', 'Coca-Cola', 'ABD', 'NYSE'),
      _MarketAssetDefinition('DIS', 'Walt Disney', 'ABD', 'NYSE'),
      _MarketAssetDefinition('CRM', 'Salesforce', 'ABD', 'NYSE'),
      _MarketAssetDefinition('BA', 'Boeing', 'ABD', 'NYSE'),
      _MarketAssetDefinition('NKE', 'Nike', 'ABD', 'NYSE'),
      _MarketAssetDefinition('RKLB', 'Rocket Lab', 'ABD', 'NASDAQ'),
    ],
    'Döviz': [
      _MarketAssetDefinition(
        'USD/TRY',
        'ABD Doları / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition('EUR/TRY', 'Euro / Türk Lirası', 'Döviz', 'FX'),
      _MarketAssetDefinition('GBP/TRY', 'Sterlin / Türk Lirası', 'Döviz', 'FX'),
      _MarketAssetDefinition(
        'CHF/TRY',
        'İsviçre Frangı / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'CAD/TRY',
        'Kanada Doları / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'AUD/TRY',
        'Avustralya Doları / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'JPY/TRY',
        'Japon Yeni / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'CNY/TRY',
        'Çin Yuanı / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'SAR/TRY',
        'Suudi Riyali / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'AED/TRY',
        'BAE Dirhemi / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'KWD/TRY',
        'Kuveyt Dinarı / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'NOK/TRY',
        'Norveç Kronu / Türk Lirası',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition('EUR/USD', 'Euro / ABD Doları', 'Döviz', 'FX'),
      _MarketAssetDefinition('GBP/USD', 'Sterlin / ABD Doları', 'Döviz', 'FX'),
      _MarketAssetDefinition(
        'USD/JPY',
        'ABD Doları / Japon Yeni',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'USD/CHF',
        'ABD Doları / İsviçre Frangı',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'USD/CAD',
        'ABD Doları / Kanada Doları',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'AUD/USD',
        'Avustralya Doları / ABD Doları',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition(
        'NZD/USD',
        'Yeni Zelanda Doları / ABD Doları',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition('EUR/GBP', 'Euro / Sterlin', 'Döviz', 'FX'),
      _MarketAssetDefinition('EUR/JPY', 'Euro / Japon Yeni', 'Döviz', 'FX'),
      _MarketAssetDefinition('GBP/JPY', 'Sterlin / Japon Yeni', 'Döviz', 'FX'),
      _MarketAssetDefinition(
        'AUD/JPY',
        'Avustralya Doları / Japon Yeni',
        'Döviz',
        'FX',
      ),
      _MarketAssetDefinition('EUR/CHF', 'Euro / İsviçre Frangı', 'Döviz', 'FX'),
      _MarketAssetDefinition(
        'GBP/CHF',
        'Sterlin / İsviçre Frangı',
        'Döviz',
        'FX',
      ),
    ],
    'Altın': [
      _MarketAssetDefinition('GRAM_ALTIN', 'Gram Altın', 'Altın', 'TR_GOLD'),
      _MarketAssetDefinition(
        'CEYREK_ALTIN',
        'Çeyrek Altın',
        'Altın',
        'TR_GOLD',
      ),
      _MarketAssetDefinition('YARIM_ALTIN', 'Yarım Altın', 'Altın', 'TR_GOLD'),
      _MarketAssetDefinition('TAM_ALTIN', 'Tam Altın', 'Altın', 'TR_GOLD'),
      _MarketAssetDefinition(
        'CUMHURIYET_ALTINI',
        'Cumhuriyet Altını',
        'Altın',
        'TR_GOLD',
      ),
      _MarketAssetDefinition('ATA_ALTINI', 'Ata Altını', 'Altın', 'TR_GOLD'),
      _MarketAssetDefinition(
        'RESAT_ALTINI',
        'Reşat Altını',
        'Altın',
        'TR_GOLD',
      ),
      _MarketAssetDefinition(
        'GREMSE_ALTINI',
        'Gremse Altını',
        'Altın',
        'TR_GOLD',
      ),
      _MarketAssetDefinition('BESLI_ALTIN', 'Beşli Altın', 'Altın', 'TR_GOLD'),
      _MarketAssetDefinition(
        'ZIYNET_ALTINI',
        'Ziynet Altını',
        'Altın',
        'TR_GOLD',
      ),
      _MarketAssetDefinition(
        'BILEZIK_22',
        '22 Ayar Bilezik',
        'Altın',
        'TR_GOLD',
      ),
      _MarketAssetDefinition('XAU/USD', 'Ons Altın', 'Altın', 'COMMODITY'),
      _MarketAssetDefinition('GLD', 'SPDR Gold Shares', 'Altın', 'ARCX'),
      _MarketAssetDefinition('IAU', 'iShares Gold Trust', 'Altın', 'ARCX'),
      _MarketAssetDefinition(
        'SGOL',
        'abrdn Physical Gold Shares',
        'Altın',
        'ARCX',
      ),
      _MarketAssetDefinition(
        'BAR',
        'GraniteShares Gold Trust',
        'Altın',
        'ARCX',
      ),
      _MarketAssetDefinition(
        'AAAU',
        'Goldman Sachs Physical Gold ETF',
        'Altın',
        'BATS',
      ),
      _MarketAssetDefinition('OUNZ', 'VanEck Merk Gold Trust', 'Altın', 'BATS'),
      _MarketAssetDefinition(
        'PHYS',
        'Sprott Physical Gold Trust',
        'Altın',
        'NYSE',
      ),
      _MarketAssetDefinition(
        'IAUM',
        'iShares Gold Trust Micro',
        'Altın',
        'BATS',
      ),
      _MarketAssetDefinition('UGL', 'ProShares Ultra Gold', 'Altın', 'ARCX'),
      _MarketAssetDefinition('GDX', 'VanEck Gold Miners ETF', 'Altın', 'ARCX'),
      _MarketAssetDefinition(
        'GDXJ',
        'VanEck Junior Gold Miners ETF',
        'Altın',
        'ARCX',
      ),
      _MarketAssetDefinition(
        'NUGT',
        'Direxion Gold Miners Bull 2X',
        'Altın',
        'ARCX',
      ),
      _MarketAssetDefinition(
        'DUST',
        'Direxion Gold Miners Bear 2X',
        'Altın',
        'ARCX',
      ),
    ],
    'Metal': [
      _MarketAssetDefinition('GRAM_GUMUS', 'Gram Gümüş', 'Metal', 'COMMODITY'),
      _MarketAssetDefinition('XAG/USD', 'Ons Gümüş', 'Metal', 'COMMODITY'),
      _MarketAssetDefinition('XPT/USD', 'Ons Platin', 'Metal', 'COMMODITY'),
      _MarketAssetDefinition('XPD/USD', 'Ons Paladyum', 'Metal', 'COMMODITY'),
      _MarketAssetDefinition('SLV', 'iShares Silver Trust', 'Metal', 'ARCX'),
      _MarketAssetDefinition('SIVR', 'abrdn Physical Silver', 'Metal', 'ARCX'),
      _MarketAssetDefinition('PSLV', 'Sprott Physical Silver', 'Metal', 'NYSE'),
      _MarketAssetDefinition(
        'PPLT',
        'abrdn Physical Platinum',
        'Metal',
        'ARCX',
      ),
      _MarketAssetDefinition('PLTM', 'GraniteShares Platinum', 'Metal', 'ARCX'),
      _MarketAssetDefinition(
        'PALL',
        'abrdn Physical Palladium',
        'Metal',
        'ARCX',
      ),
      _MarketAssetDefinition('CPER', 'United States Copper', 'Metal', 'ARCX'),
      _MarketAssetDefinition('COPX', 'Global X Copper Miners', 'Metal', 'ARCX'),
      _MarketAssetDefinition('DBB', 'Invesco Base Metals', 'Metal', 'ARCX'),
      _MarketAssetDefinition('JJC', 'Copper ETN', 'Metal', 'ARCX'),
      _MarketAssetDefinition('PICK', 'Global Metals & Mining', 'Metal', 'BATS'),
      _MarketAssetDefinition('REMX', 'Rare Earth Metals ETF', 'Metal', 'BATS'),
      _MarketAssetDefinition('LIT', 'Lithium & Battery Tech', 'Metal', 'ARCX'),
      _MarketAssetDefinition('URA', 'Global X Uranium', 'Metal', 'ARCX'),
      _MarketAssetDefinition('GLTR', 'Precious Metals Basket', 'Metal', 'ARCX'),
      _MarketAssetDefinition('GDX', 'Gold Miners ETF', 'Metal', 'ARCX'),
      _MarketAssetDefinition('GDXJ', 'Junior Gold Miners ETF', 'Metal', 'ARCX'),
      _MarketAssetDefinition('SIL', 'Global X Silver Miners', 'Metal', 'ARCX'),
      _MarketAssetDefinition('SILJ', 'Junior Silver Miners', 'Metal', 'ARCX'),
      _MarketAssetDefinition('COPJ', 'Junior Copper Miners', 'Metal', 'NASDAQ'),
      _MarketAssetDefinition('XME', 'Metals & Mining ETF', 'Metal', 'ARCX'),
      _MarketAssetDefinition('XLB', 'Materials Select Sector', 'Metal', 'ARCX'),
    ],
    'Emtia': [
      _MarketAssetDefinition('BRENT/USD', 'Brent Petrol', 'Emtia', 'COMMODITY'),
      _MarketAssetDefinition('WHEAT/USD', 'Buğday', 'Emtia', 'COMMODITY'),
    ],
    'Kripto': [
      _MarketAssetDefinition('BTC', 'Bitcoin', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('ETH', 'Ethereum', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('BNB', 'Binance Coin', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('SOL', 'Solana', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('XRP', 'XRP', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('ADA', 'Cardano', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('DOGE', 'Dogecoin', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('AVAX', 'Avalanche', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('DOT', 'Polkadot', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('LINK', 'Chainlink', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('MATIC', 'Polygon', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('LTC', 'Litecoin', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('TRX', 'TRON', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('UNI', 'Uniswap', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('ATOM', 'Cosmos', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('SHIB', 'Shiba Inu', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('BCH', 'Bitcoin Cash', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('NEAR', 'NEAR Protocol', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('ICP', 'Internet Computer', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('APT', 'Aptos', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('FIL', 'Filecoin', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('ETC', 'Ethereum Classic', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('XLM', 'Stellar', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('HBAR', 'Hedera', 'Kripto', 'CRYPTO'),
      _MarketAssetDefinition('TON', 'Toncoin', 'Kripto', 'CRYPTO'),
    ],
  };

  static const _categories = <String>[
    'Favoriler',
    'BIST',
    'ABD',
    'Döviz',
    'Altın',
    'Metal',
    'Emtia',
    'Kripto',
    'Tümü',
  ];

  static final Map<String, List<_MarketAssetResult>> _categoryResultsCache = {};
  static final Map<String, Future<List<_MarketAssetResult>>> _categoryRequests =
      {};
  static final Set<String> _loadedCategories = {};
  static final Map<String, DateTime> _categoryUpdatedAt = {};
  static const Duration _backgroundRefreshInterval = Duration(seconds: 30);

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _assetSearch = UnifiedAssetSearchService();

  late Future<List<_MarketAssetResult>> _marketFuture;
  Timer? _searchDebounce;
  List<_MarketAssetResult> _searchResults = const [];
  bool _isSearching = false;
  int _searchRequestId = 0;
  String _category = 'Favoriler';
  String _searchText = '';
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    MarketFavoritesService.instance.favorites.addListener(
      _handleFavoritesChanged,
    );
    _lastUpdatedAt = _categoryUpdatedAt[_category];
    _marketFuture = _loadMarket();
  }

  @override
  void dispose() {
    MarketFavoritesService.instance.favorites.removeListener(
      _handleFavoritesChanged,
    );
    _searchDebounce?.cancel();
    _assetSearch.close();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_MarketAssetResult>> _loadMarket({bool forceRefresh = false}) {
    return _marketForCategory(_category, forceRefresh: forceRefresh);
  }

  Future<List<_MarketAssetResult>> _marketForCategory(
    String category, {
    bool forceRefresh = false,
  }) {
    final cached = _categoryResultsCache[category];
    final running = _categoryRequests[category];
    if (!forceRefresh &&
        cached != null &&
        _loadedCategories.contains(category)) {
      final updatedAt = _categoryUpdatedAt[category];
      final shouldRefresh =
          updatedAt == null ||
          DateTime.now().difference(updatedAt) > _backgroundRefreshInterval;

      if (shouldRefresh && running == null) {
        unawaited(_startCategoryRequest(category, forceRefresh: true));
      }
      return Future.value(cached);
    }

    if (running != null) return running;

    if (cached == null) {
      _categoryResultsCache[category] = List.unmodifiable(
        _definitionsForCategory(category)
            .map((definition) => _MarketAssetResult(definition: definition))
            .toList(growable: false),
      );
    }

    return _startCategoryRequest(category, forceRefresh: forceRefresh);
  }

  Future<List<_MarketAssetResult>> _startCategoryRequest(
    String category, {
    required bool forceRefresh,
  }) {
    final running = _categoryRequests[category];
    if (running != null) return running;

    final request = _fetchCategory(category, forceRefresh: forceRefresh)
        .then((results) {
          _categoryResultsCache[category] = List.unmodifiable(results);
          _loadedCategories.add(category);
          _categoryUpdatedAt[category] = DateTime.now();
          if (mounted && _category == category) {
            setState(() => _lastUpdatedAt = _categoryUpdatedAt[category]);
          }
          return results;
        })
        .whenComplete(() => _categoryRequests.remove(category));

    _categoryRequests[category] = request;
    return request;
  }

  Future<List<_MarketAssetResult>> _fetchCategory(
    String category, {
    required bool forceRefresh,
  }) async {
    final definitions = _definitionsForCategory(category);
    final cryptoDefinitions = definitions
        .where((asset) => asset.exchange.toUpperCase() == 'CRYPTO')
        .toList(growable: false);
    final cryptoQuotes = <String, MarketQuote>{};
    Object? cryptoError;
    if (cryptoDefinitions.isNotEmpty) {
      try {
        final quotes = await MarketService.instance.getQuotes(
          cryptoDefinitions
              .map((asset) => asset.symbol)
              .toList(growable: false),
          exchange: 'CRYPTO',
          forceRefresh: forceRefresh,
        );
        for (final quote in quotes) {
          cryptoQuotes[quote.symbol.toUpperCase()] = quote;
        }
      } catch (error) {
        cryptoError = error;
      }
    }

    final results = await Future.wait(
      definitions.map((asset) async {
        if (asset.exchange.toUpperCase() == 'CRYPTO') {
          final quote = cryptoQuotes[asset.symbol.toUpperCase()];
          return _MarketAssetResult(
            definition: asset,
            quote: quote,
            error: quote == null
                ? cryptoError ?? 'Kripto fiyatı bulunamadı.'
                : null,
          );
        }
        try {
          final quote = await MarketService.instance.getQuote(
            asset.symbol,
            exchange: asset.exchange,
            forceRefresh: forceRefresh,
          );
          return _MarketAssetResult(definition: asset, quote: quote);
        } catch (error) {
          return _MarketAssetResult(definition: asset, error: error);
        }
      }),
    );

    if (mounted && _category == category) {
      setState(() => _lastUpdatedAt = DateTime.now());
    }
    return results;
  }

  List<_MarketAssetDefinition> _definitionsForCategory(String category) {
    if (category == 'Favoriler') {
      return MarketFavoritesService.instance.favorites.value
          .map(
            (favorite) => _MarketAssetDefinition.fromAssetInfo(favorite.asset),
          )
          .toList(growable: false);
    }

    if (category == 'Tümü') {
      const sourceCategories = [
        'BIST',
        'ABD',
        'Döviz',
        'Altın',
        'Metal',
        'Kripto',
      ];
      final combined = <_MarketAssetDefinition>[];
      for (var index = 0; combined.length < _categoryItemLimit; index++) {
        var addedAny = false;
        for (final source in sourceCategories) {
          final definitions = _assetsByCategory[source]!;
          if (index < definitions.length) {
            combined.add(definitions[index]);
            addedAny = true;
            if (combined.length == _categoryItemLimit) break;
          }
        }
        if (!addedAny) break;
      }
      return List.unmodifiable(combined);
    }

    return (_assetsByCategory[category] ?? const <_MarketAssetDefinition>[])
        .take(_categoryItemLimit)
        .toList(growable: false);
  }

  void _handleFavoritesChanged() {
    _categoryResultsCache.remove('Favoriler');
    _categoryRequests.remove('Favoriler');
    _loadedCategories.remove('Favoriler');
    _categoryUpdatedAt.remove('Favoriler');
    if (!mounted || _category != 'Favoriler') return;

    setState(() {
      _marketFuture = _marketForCategory('Favoriler');
    });
  }

  Future<void> _refresh() async {
    late final Future<List<_MarketAssetResult>> refreshFuture;
    setState(() {
      refreshFuture = _loadMarket(forceRefresh: true);
      _marketFuture = refreshFuture;
    });
    await refreshFuture;
  }

  void _retry() {
    setState(() {
      _marketFuture = _loadMarket(forceRefresh: true);
    });
  }

  void _selectCategory(String category) {
    if (_category == category) return;

    setState(() {
      _category = category;
      _lastUpdatedAt = _categoryUpdatedAt[category];
      _marketFuture = _marketForCategory(category);
    });
  }

  String _updatedTime() {
    final date = _lastUpdatedAt;
    if (date == null) return 'Veriler güncelleniyor';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return 'Son güncelleme $hour:$minute:$second';
  }

  List<_MarketAssetResult> _visibleResults(List<_MarketAssetResult> results) {
    final query = _searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      return _searchResults;
    }

    final source = _category == 'Favoriler'
        ? MarketFavoritesService.instance.favorites.value.map((favorite) {
            for (final result in results) {
              if (result.definition.symbol == favorite.asset.symbol) {
                return result;
              }
            }
            return _MarketAssetResult(
              definition: _MarketAssetDefinition.fromAssetInfo(favorite.asset),
              quote: favorite.lastQuote,
            );
          }).toList()
        : results;

    return source.where((result) {
      final definition = result.definition;
      final categoryMatches =
          _category == 'Favoriler' ||
          _category == 'Tümü' ||
          definition.category == _category;
      final searchMatches =
          query.isEmpty ||
          definition.symbol.toLowerCase().contains(query) ||
          definition.name.toLowerCase().contains(query);
      return categoryMatches && searchMatches;
    }).toList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    setState(() {
      _searchText = value;
      _searchResults = const [];
    });

    if (query.length < 2) {
      _searchRequestId++;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 220),
      () => _searchAssets(query),
    );
  }

  Future<void> _searchAssets(String query) async {
    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);

    try {
      final assets = await _assetSearch.search(query, limit: 18);
      if (!mounted || requestId != _searchRequestId) return;

      final pendingResults = assets
          .map(
            (asset) => _MarketAssetResult(
              definition: _MarketAssetDefinition.fromAssetInfo(asset),
            ),
          )
          .toList(growable: false);

      setState(() {
        _searchResults = pendingResults;
      });

      final pricedResults = await Future.wait(
        assets.map((asset) async {
          final definition = _MarketAssetDefinition.fromAssetInfo(asset);
          try {
            final quote = await MarketService.instance.getQuote(
              asset.symbol,
              exchange: asset.exchange,
              forceRefresh: true,
            );
            return _MarketAssetResult(definition: definition, quote: quote);
          } catch (error) {
            return _MarketAssetResult(definition: definition, error: error);
          }
        }),
      );

      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = pricedResults;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    _searchController.clear();
    setState(() {
      _searchText = '';
      _searchResults = const [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Canlı Piyasa'),
        actions: [
          IconButton(
            tooltip: 'Piyasayı yenile',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<_MarketAssetResult>>(
          future: _marketFuture,
          builder: (context, snapshot) {
            final cachedCategoryResults = _categoryResultsCache[_category];
            final results =
                cachedCategoryResults ??
                snapshot.data ??
                const <_MarketAssetResult>[];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final successfulCount = results
                .where((result) => result.quote != null)
                .length;
            final visibleResults = _visibleResults(results);
            final searchActive = _searchText.trim().isNotEmpty;

            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
              children: [
                _MarketStatusHero(
                  updatedLabel: _updatedTime(),
                  isLoading: isLoading,
                  hasLiveData: successfulCount > 0,
                ),
                const SizedBox(height: 14),
                const _InformationLine(),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Varlık ara...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 28),
                    suffixIcon: _searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Aramayı temizle',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFDCE5EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFDCE5EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFF0284C7),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 14),
                if (!searchActive) ...[
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category == _category;
                        return ChoiceChip(
                          avatar: category == 'Favoriler'
                              ? Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFFF59E0B),
                                )
                              : null,
                          label: Text(category),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: const Color(0xFF0F73C5),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => _selectCategory(category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  searchActive ? 'Arama Sonuçları' : _category,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading && results.isEmpty)
                  const SurfaceCard(
                    child: SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (snapshot.hasError && results.isEmpty)
                  _MarketErrorCard(onRetry: _retry)
                else if (searchActive && _searchText.trim().length < 2)
                  const SurfaceCard(
                    child: Text(
                      'Aramak için en az 2 harf yazın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (visibleResults.isEmpty && _isSearching)
                  const SurfaceCard(
                    child: SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (visibleResults.isEmpty)
                  const SurfaceCard(
                    child: Text(
                      'Bu bölümde gösterilecek varlık bulunamadı.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < visibleResults.length;
                          index++
                        ) ...[
                          _LiveMarketRow(
                            result: visibleResults[index],
                            favorite: MarketFavoritesService.instance.contains(
                              visibleResults[index].definition.symbol,
                            ),
                            onFavorite: () {
                              final result = visibleResults[index];
                              setState(() {
                                MarketFavoritesService.instance.toggle(
                                  result.definition.assetInfo,
                                  quote: result.quote,
                                );
                              });
                            },
                            onAddTransaction: () {
                              final result = visibleResults[index];
                              final quote = result.quote;
                              Navigator.of(context).push(
                                noAnimationRoute(
                                  builder: (_) => TransactionEntryPage(
                                    showBottomNav: false,
                                    initialAsset: result.definition.assetInfo
                                        .copyWith(currency: quote?.currency),
                                    initialPrice: quote?.price,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (index != visibleResults.length - 1)
                            const ThinDivider(),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 0,
        allowSelectedDestinationNavigation: true,
      ),
    );
  }
}

class _MarketStatusHero extends StatelessWidget {
  final String updatedLabel;
  final bool isLoading;
  final bool hasLiveData;

  const _MarketStatusHero({
    required this.updatedLabel,
    required this.isLoading,
    required this.hasLiveData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F75BD), Color(0xFF12366F)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F75BD).withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Piyasalar hareket halinde',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isLoading
                            ? const Color(0xFFFBBF24)
                            : hasLiveData
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFF87171),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        updatedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationLine extends StatelessWidget {
  const _InformationLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bu ekran bilgilendirme amaçlıdır. Daha fazla yatırım aracı bulmak ve işlem eklemek için İşlem ekranındaki aramayı kullanabilirsiniz.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      ],
    );
  }
}

class _LiveMarketRow extends StatelessWidget {
  final _MarketAssetResult result;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onAddTransaction;

  const _LiveMarketRow({
    required this.result,
    required this.favorite,
    required this.onFavorite,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final definition = result.definition;
    final quote = result.quote;
    final isPriceLoading = quote == null && result.error == null;
    final isPositive = (quote?.changePercent ?? 0) >= 0;
    final color = isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: favorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
            onPressed: onFavorite,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            icon: Icon(
              favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: favorite
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFCBD5E1),
              size: 25,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        definition.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        definition.category,
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isPriceLoading
                      ? 'Fiyat alınıyor...'
                      : quote == null
                      ? 'Veri alınamadı'
                      : 'Güncel',
                  style: TextStyle(
                    color: isPriceLoading
                        ? const Color(0xFF0284C7)
                        : quote == null
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 112, maxWidth: 145),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPriceLoading
                      ? '…'
                      : quote == null
                      ? '—'
                      : formatCurrency(quote.price, quote.currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                if (quote != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      formatPercent(quote.changePercent),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onAddTransaction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'İşlem Ekle',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _MarketErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF94A3B8),
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'Piyasa verileri alınamadı.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _MarketAssetDefinition {
  final String symbol;
  final String name;
  final String category;
  final String exchange;
  final AssetInfo? _assetInfo;

  const _MarketAssetDefinition(
    this.symbol,
    this.name,
    this.category,
    this.exchange, [
    this._assetInfo,
  ]);

  factory _MarketAssetDefinition.fromAssetInfo(AssetInfo asset) {
    return _MarketAssetDefinition(
      asset.symbol,
      asset.name,
      _categoryLabel(asset.category),
      asset.exchange,
      asset,
    );
  }

  AssetInfo get assetInfo {
    final existing = _assetInfo;
    if (existing != null) return existing;

    final assetCategory = switch (category) {
      'BIST' => AssetCategory.bist,
      'ABD' => AssetCategory.usStock,
      'Döviz' => AssetCategory.currency,
      'Altın' => AssetCategory.commodity,
      'Metal' => AssetCategory.commodity,
      'Emtia' => AssetCategory.commodity,
      'Kripto' => AssetCategory.crypto,
      _ => AssetCategory.unknown,
    };

    return AssetInfo(
      symbol: symbol,
      name: name,
      category: assetCategory,
      exchange: exchange,
      currency:
          assetCategory == AssetCategory.usStock ||
              assetCategory == AssetCategory.crypto ||
              category == 'Metal'
          ? 'USD'
          : 'TRY',
      countryCode: assetCategory == AssetCategory.bist ? 'TR' : 'GLOBAL',
      provider: 'MarketRouter',
      supportStatus: AssetSupportStatus.live,
    );
  }

  static String _categoryLabel(AssetCategory category) {
    return switch (category) {
      AssetCategory.bist => 'BIST',
      AssetCategory.usStock => 'ABD',
      AssetCategory.currency => 'Döviz',
      AssetCategory.commodity => 'Altın',
      AssetCategory.crypto => 'Kripto',
      AssetCategory.etf => 'ETF',
      AssetCategory.fund => 'Fon',
      AssetCategory.marketIndex => 'Endeks',
      _ => category.label,
    };
  }
}

class _MarketAssetResult {
  final _MarketAssetDefinition definition;
  final MarketQuote? quote;
  final Object? error;

  const _MarketAssetResult({required this.definition, this.quote, this.error});
}
