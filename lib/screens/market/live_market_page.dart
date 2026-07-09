import 'package:flutter/material.dart';

import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';

class LiveMarketPage extends StatefulWidget {
  const LiveMarketPage({super.key});

  @override
  State<LiveMarketPage> createState() => _LiveMarketPageState();
}

class _LiveMarketPageState extends State<LiveMarketPage> {
  final Set<String> _favorites = <String>{'XAU'};
  String _category = 'Tümü';

  static const List<String> _categories = ['Tümü', 'Altın', 'Döviz', 'BIST'];

  static const List<_MarketAsset> _assets = [
    _MarketAsset(
      category: 'Döviz',
      symbol: 'USDTRY',
      name: 'USD / TRY',
      price: '39,82',
      change: '+0,18%',
      positive: true,
    ),
    _MarketAsset(
      category: 'Döviz',
      symbol: 'EURTRY',
      name: 'EUR / TRY',
      price: '46,73',
      change: '+0,09%',
      positive: true,
    ),
    _MarketAsset(
      category: 'Altın',
      symbol: 'XAU',
      name: 'Gram Altın',
      price: '4.851,00 TL',
      change: '-0,12%',
      positive: false,
    ),
    _MarketAsset(
      category: 'BIST',
      symbol: 'XU100',
      name: 'BIST 100',
      price: '10.421',
      change: '+1,34%',
      positive: true,
    ),
    _MarketAsset(
      category: 'BIST',
      symbol: 'ASELS',
      name: 'Aselsan',
      price: '145,80 TL',
      change: '+2,14%',
      positive: true,
    ),
    _MarketAsset(
      category: 'BIST',
      symbol: 'THYAO',
      name: 'Türk Hava Yolları',
      price: '318,40 TL',
      change: '-0,86%',
      positive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final assets = _category == 'Tümü'
        ? _assets
        : _assets.where((asset) => asset.category == _category).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Piyasa'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const SectionTitle(title: 'Piyasa'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < assets.length; i++) ...[
                    _MarketAssetRow(
                      asset: assets[i],
                      favorite: _favorites.contains(assets[i].symbol),
                      onFavorite: () {
                        setState(() {
                          if (!_favorites.add(assets[i].symbol)) {
                            _favorites.remove(assets[i].symbol);
                          }
                        });
                      },
                    ),
                    if (i != assets.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 0,
      ),
    );
  }
}

class _MarketAsset {
  final String category;
  final String symbol;
  final String name;
  final String price;
  final String change;
  final bool positive;

  const _MarketAsset({
    required this.category,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.positive,
  });
}

class _MarketAssetRow extends StatelessWidget {
  final _MarketAsset asset;
  final bool favorite;
  final VoidCallback onFavorite;

  const _MarketAssetRow({
    required this.asset,
    required this.favorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final color = asset.positive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: favorite ? const Color(0xFFF59E0B) : Colors.black26,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  asset.name,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                asset.price,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                asset.change,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
