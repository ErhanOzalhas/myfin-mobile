import '../models/asset_category.dart';
import '../models/asset_definition.dart';

class AssetUniverse {
  AssetUniverse._();

  static const List<AssetDefinition> localGold = [
    AssetDefinition(
      symbol: 'GRAM_ALTIN',
      name: 'Gram Altın',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['GRAM', 'ALTIN', 'GA'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'CEYREK_ALTIN',
      name: 'Çeyrek Altın',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['ÇEYREK', 'CEYREK', 'QUARTER_GOLD'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'YARIM_ALTIN',
      name: 'Yarım Altın',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['YARIM', 'HALF_GOLD'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'TAM_ALTIN',
      name: 'Tam Altın',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['TAM', 'FULL_GOLD'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'CUMHURIYET_ALTINI',
      name: 'Cumhuriyet Altını',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: [
        'CUMHURIYET',
        'CUMHURIYET ALTINI',
        'REPUBLIC_GOLD',
      ],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'ATA_ALTINI',
      name: 'Ata Altını',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['ATA', 'ATA LIRA', 'ATA_LIRA'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'RESAT_ALTINI',
      name: 'Reşat Altını',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['REŞAT', 'RESAT'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'GREMSE_ALTINI',
      name: 'Gremse Altını',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['GREMSE'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'BESLI_ALTIN',
      name: 'Beşli Altın',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['BEŞLİ', 'BESLI', 'BESIBIRYERDE'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'ZIYNET_ALTINI',
      name: 'Ziynet Altını',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: ['ZİYNET', 'ZIYNET'],
      isLocalTurkishGold: true,
    ),
    AssetDefinition(
      symbol: 'BILEZIK_22',
      name: '22 Ayar Bilezik',
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      aliases: [
        '22 AYAR',
        '22 AYAR BILEZIK',
        '22_AYAR_BILEZIK',
      ],
      isLocalTurkishGold: true,
    ),
  ];

  static const List<AssetDefinition> globalCommodities = [
    AssetDefinition(
      symbol: 'XAU/USD',
      name: 'Ons Altın',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['XAUUSD', 'GOLD', 'ONS ALTIN'],
    ),
    AssetDefinition(
      symbol: 'XAG/USD',
      name: 'Gümüş',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['XAGUSD', 'SILVER', 'GUMUS'],
    ),
    AssetDefinition(
      symbol: 'XPT/USD',
      name: 'Platin',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['XPTUSD', 'PLATINUM'],
    ),
    AssetDefinition(
      symbol: 'XPD/USD',
      name: 'Paladyum',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['XPDUSD', 'PALLADIUM'],
    ),
    AssetDefinition(
      symbol: 'WTI/USD',
      name: 'WTI Petrol',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['WTI', 'USOIL', 'WTI PETROL'],
    ),
    AssetDefinition(
      symbol: 'BRENT/USD',
      name: 'Brent Petrol',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['BRENT', 'UKOIL', 'BRENT PETROL'],
    ),
    AssetDefinition(
      symbol: 'NG/USD',
      name: 'Doğalgaz',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['NATGAS', 'NATURAL GAS', 'DOGALGAZ'],
    ),
    AssetDefinition(
      symbol: 'COPPER',
      name: 'Bakır',
      category: AssetCategory.commodity,
      exchange: 'COMMODITY',
      currency: 'USD',
      aliases: ['BAKIR'],
    ),
  ];

  static const List<AssetDefinition> forex = [
    AssetDefinition(
      symbol: 'USD/TRY',
      name: 'ABD Doları / Türk Lirası',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'TRY',
      aliases: ['USDTRY', 'DOLAR'],
    ),
    AssetDefinition(
      symbol: 'EUR/TRY',
      name: 'Euro / Türk Lirası',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'TRY',
      aliases: ['EURTRY', 'EURO'],
    ),
    AssetDefinition(
      symbol: 'GBP/TRY',
      name: 'Sterlin / Türk Lirası',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'TRY',
      aliases: ['GBPTRY', 'STERLIN'],
    ),
    AssetDefinition(
      symbol: 'CHF/TRY',
      name: 'İsviçre Frangı / Türk Lirası',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'TRY',
      aliases: ['CHFTRY'],
    ),
    AssetDefinition(
      symbol: 'EUR/USD',
      name: 'Euro / ABD Doları',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'USD',
      aliases: ['EURUSD'],
    ),
    AssetDefinition(
      symbol: 'GBP/USD',
      name: 'Sterlin / ABD Doları',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'USD',
      aliases: ['GBPUSD'],
    ),
    AssetDefinition(
      symbol: 'USD/JPY',
      name: 'ABD Doları / Japon Yeni',
      category: AssetCategory.currency,
      exchange: 'FX',
      currency: 'JPY',
      aliases: ['USDJPY'],
    ),
  ];

  static const List<AssetDefinition> indices = [
    AssetDefinition(
      symbol: 'SPX',
      name: 'S&P 500',
      category: AssetCategory.marketIndex,
      exchange: 'US',
      currency: 'USD',
      aliases: ['SP500', 'S&P500'],
    ),
    AssetDefinition(
      symbol: 'NDX',
      name: 'Nasdaq 100',
      category: AssetCategory.marketIndex,
      exchange: 'US',
      currency: 'USD',
      aliases: ['NASDAQ100'],
    ),
    AssetDefinition(
      symbol: 'DJI',
      name: 'Dow Jones',
      category: AssetCategory.marketIndex,
      exchange: 'US',
      currency: 'USD',
      aliases: ['DOWJONES'],
    ),
    AssetDefinition(
      symbol: 'DAX',
      name: 'DAX',
      category: AssetCategory.marketIndex,
      exchange: 'XETR',
      currency: 'EUR',
      aliases: ['DAX40'],
    ),
    AssetDefinition(
      symbol: 'FTSE',
      name: 'FTSE 100',
      category: AssetCategory.marketIndex,
      exchange: 'XLON',
      currency: 'GBP',
      aliases: ['FTSE100'],
    ),
    AssetDefinition(
      symbol: 'CAC',
      name: 'CAC 40',
      category: AssetCategory.marketIndex,
      exchange: 'XPAR',
      currency: 'EUR',
      aliases: ['CAC40'],
    ),
    AssetDefinition(
      symbol: 'N225',
      name: 'Nikkei 225',
      category: AssetCategory.marketIndex,
      exchange: 'XTKS',
      currency: 'JPY',
      aliases: ['NIKKEI225'],
    ),
    AssetDefinition(
      symbol: 'XU100',
      name: 'BIST 100',
      category: AssetCategory.marketIndex,
      exchange: 'XIST',
      currency: 'TRY',
      aliases: ['BIST100'],
    ),
  ];

  static const List<AssetDefinition> etfs = [
    AssetDefinition(
      symbol: 'SPY',
      name: 'SPDR S&P 500 ETF Trust',
      category: AssetCategory.etf,
      exchange: 'ARCX',
      currency: 'USD',
    ),
    AssetDefinition(
      symbol: 'QQQ',
      name: 'Invesco QQQ Trust',
      category: AssetCategory.etf,
      exchange: 'NASDAQ',
      currency: 'USD',
    ),
    AssetDefinition(
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      category: AssetCategory.etf,
      exchange: 'ARCX',
      currency: 'USD',
    ),
    AssetDefinition(
      symbol: 'VTI',
      name: 'Vanguard Total Stock Market ETF',
      category: AssetCategory.etf,
      exchange: 'ARCX',
      currency: 'USD',
    ),
    AssetDefinition(
      symbol: 'GLD',
      name: 'SPDR Gold Shares',
      category: AssetCategory.etf,
      exchange: 'ARCX',
      currency: 'USD',
    ),
    AssetDefinition(
      symbol: 'SLV',
      name: 'iShares Silver Trust',
      category: AssetCategory.etf,
      exchange: 'ARCX',
      currency: 'USD',
    ),
  ];

  static const List<AssetDefinition> popularBist = [
    AssetDefinition(
      symbol: 'ASELS',
      name: 'Aselsan',
      category: AssetCategory.bist,
      exchange: 'XIST',
      currency: 'TRY',
    ),
    AssetDefinition(
      symbol: 'THYAO',
      name: 'Türk Hava Yolları',
      category: AssetCategory.bist,
      exchange: 'XIST',
      currency: 'TRY',
    ),
    AssetDefinition(
      symbol: 'ISCTR',
      name: 'Türkiye İş Bankası C',
      category: AssetCategory.bist,
      exchange: 'XIST',
      currency: 'TRY',
    ),
    AssetDefinition(
      symbol: 'SISE',
      name: 'Şişecam',
      category: AssetCategory.bist,
      exchange: 'XIST',
      currency: 'TRY',
    ),
    AssetDefinition(
      symbol: 'ENJSA',
      name: 'Enerjisa Enerji',
      category: AssetCategory.bist,
      exchange: 'XIST',
      currency: 'TRY',
    ),
  ];

  static List<AssetDefinition> get all => [
        ...localGold,
        ...globalCommodities,
        ...forex,
        ...indices,
        ...etfs,
        ...popularBist,
      ];

  static AssetDefinition? find(String query) {
    for (final asset in all) {
      if (asset.matches(query)) {
        return asset;
      }
    }

    return null;
  }

  static bool isLocalGold(String symbol) {
    return localGold.any((asset) => asset.matches(symbol));
  }
}
