class ProviderSymbolCandidate {
  final String symbol;
  final String? exchange;

  const ProviderSymbolCandidate({
    required this.symbol,
    this.exchange,
  });

  String get debugLabel =>
      exchange == null || exchange!.isEmpty
          ? symbol
          : '$symbol @ $exchange';
}

class ProviderSymbolMapping {
  ProviderSymbolMapping._();

  static List<ProviderSymbolCandidate> twelveDataCandidates({
    required String symbol,
    String? exchange,
  }) {
    final normalizedSymbol = _normalizeSymbol(symbol);
    final normalizedExchange = normalizeExchange(exchange);

    if (normalizedSymbol.isEmpty) {
      return const [];
    }

    if (_looksLikePair(normalizedSymbol)) {
      return [
        ProviderSymbolCandidate(symbol: normalizedSymbol),
      ];
    }

    final candidates = <ProviderSymbolCandidate>[];

    void add(String candidateSymbol, String? candidateExchange) {
      final candidate = ProviderSymbolCandidate(
        symbol: candidateSymbol,
        exchange: candidateExchange,
      );

      final alreadyExists = candidates.any(
        (item) =>
            item.symbol == candidate.symbol &&
            item.exchange == candidate.exchange,
      );

      if (!alreadyExists) {
        candidates.add(candidate);
      }
    }

    if (normalizedExchange == 'XIST') {
      add(normalizedSymbol, 'XIST');
      add(normalizedSymbol, 'BIST');
      add('$normalizedSymbol:XIST', null);
      add('$normalizedSymbol:BIST', null);
      add(normalizedSymbol, null);
      return candidates;
    }

    if (normalizedExchange != null) {
      add(normalizedSymbol, normalizedExchange);
      add('$normalizedSymbol:$normalizedExchange', null);
    }

    add(normalizedSymbol, null);
    return candidates;
  }

  static String? normalizeExchange(String? exchange) {
    final value = exchange?.trim().toUpperCase();

    if (value == null || value.isEmpty || value == 'GLOBAL') {
      return null;
    }

    const aliases = {
      'BIST': 'XIST',
      'BORSA ISTANBUL': 'XIST',
      'BORSA İSTANBUL': 'XIST',
      'IST': 'XIST',
      'ISTANBUL': 'XIST',
      'NASDAQ GLOBAL SELECT': 'NASDAQ',
      'NASDAQ GLOBAL MARKET': 'NASDAQ',
      'NASDAQ CAPITAL MARKET': 'NASDAQ',
      'NYSE ARCA': 'ARCX',
      'LONDON STOCK EXCHANGE': 'XLON',
      'XETRA': 'XETR',
      'EURONEXT PARIS': 'XPAR',
      'EURONEXT AMSTERDAM': 'XAMS',
      'TOKYO STOCK EXCHANGE': 'XTKS',
      'HONG KONG STOCK EXCHANGE': 'XHKG',
    };

    return aliases[value] ?? value;
  }

  static String? nosyGoldFallbackCode(String canonicalSymbol) {
    const codes = {
      'GRAM_ALTIN': 'gramaltin',
      'CEYREK_ALTIN': 'CEYREKALTIN',
      'YARIM_ALTIN': 'YARIMALTIN',
      'TAM_ALTIN': 'TEKALTIN',
      'ATA_ALTINI': 'ATA',
      'BESLI_ALTIN': 'ATA5',
      'GREMSE_ALTINI': 'GREMSE',
      'BILEZIK_22': '22AYAR',
      'RESAT_ALTINI': 'RESATALTIN',
      'CUMHURIYET_ALTINI': 'CUMHURIYETALTINI',
      'ZIYNET_ALTINI': 'ZIYNETALTINI',
    };

    return codes[canonicalSymbol.trim().toUpperCase()];
  }

  static List<String> localGoldSearchTerms(
    String canonicalSymbol,
  ) {
    const terms = {
      'GRAM_ALTIN': ['gram altın', 'gramaltin'],
      'CEYREK_ALTIN': ['çeyrek altın', 'yeni çeyrek'],
      'YARIM_ALTIN': ['yarım altın', 'yeni yarım'],
      'TAM_ALTIN': ['tam altın', 'yeni tam', 'teklik altın'],
      'ATA_ALTINI': ['ata altın', 'yeni ata'],
      'BESLI_ALTIN': ['beşli altın', 'ata 5', 'beşi bir yerde'],
      'GREMSE_ALTINI': ['gremse altın', 'yeni gremse'],
      'BILEZIK_22': ['22 ayar', '22 ayar altın'],
      'RESAT_ALTINI': ['reşat altın', 'resat altin'],
      'CUMHURIYET_ALTINI': [
        'cumhuriyet altını',
        'cumhuriyet altini',
      ],
      'ZIYNET_ALTINI': ['ziynet altını', 'ziynet altini'],
    };

    return terms[canonicalSymbol.trim().toUpperCase()] ??
        const [];
  }

  static String _normalizeSymbol(String symbol) {
    final value = symbol.trim().toUpperCase();

    const pairAliases = {
      'USDTRY': 'USD/TRY',
      'EURTRY': 'EUR/TRY',
      'GBPTRY': 'GBP/TRY',
      'CHFTRY': 'CHF/TRY',
      'EURUSD': 'EUR/USD',
      'GBPUSD': 'GBP/USD',
      'USDJPY': 'USD/JPY',
      'XAUUSD': 'XAU/USD',
      'XAGUSD': 'XAG/USD',
      'XPTUSD': 'XPT/USD',
      'XPDUSD': 'XPD/USD',
    };

    final compact = value
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll('/', '');

    return pairAliases[compact] ?? value;
  }

  static bool _looksLikePair(String symbol) {
    return symbol.contains('/') ||
        RegExp(r'^[A-Z]{6}$').hasMatch(
          symbol.replaceAll('/', ''),
        );
  }
}
