import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_valuation_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../utils/no_animation_route.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/common/thin_divider.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../transactions/transaction_entry_page.dart';
import 'asset_detail_page.dart';

String _normalizedCategory(String type) {
  switch (type.trim().toLowerCase()) {
    case 'altin':
    case 'altın':
      return 'altin';
    case 'hisse':
    case 'bist':
      return 'hisse';
    case 'doviz':
    case 'döviz':
      return 'doviz';
    case 'kripto':
      return 'kripto';
    case 'fon':
      return 'fon';
    case 'endeks':
      return 'endeks';
    default:
      return type.trim().toLowerCase();
  }
}

String _categoryLabel(String type) {
  switch (_normalizedCategory(type)) {
    case 'altin':
      return 'Altın';
    case 'hisse':
      return 'Hisse';
    case 'doviz':
      return 'Döviz';
    case 'kripto':
      return 'Kripto';
    case 'fon':
      return 'Fon';
    case 'endeks':
      return 'Endeks';
    default:
      return type.trim().isEmpty ? 'Diğer' : type.trim();
  }
}

enum _AssetSort {
  nameAsc,
  nameDesc,
  quantityDesc,
  quantityAsc,
  costDesc,
  costAsc,
}

String _sortLabel(_AssetSort sort) {
  switch (sort) {
    case _AssetSort.nameAsc:
      return 'A – Z';
    case _AssetSort.nameDesc:
      return 'Z – A';
    case _AssetSort.quantityDesc:
      return 'Adet ↓: Azalan';
    case _AssetSort.quantityAsc:
      return 'Adet ↑: Yükselen';
    case _AssetSort.costDesc:
      return 'Maliyet ↓: Azalan';
    case _AssetSort.costAsc:
      return 'Maliyet ↑: Yükselen';
  }
}

class PortfolioAssetPage extends StatefulWidget {
  final String? initialCategory;
  final bool showBottomNav;

  const PortfolioAssetPage({
    super.key,
    this.initialCategory,
    this.showBottomNav = true,
  });

  @override
  State<PortfolioAssetPage> createState() => _PortfolioAssetPageState();
}

class _PortfolioAssetPageState extends State<PortfolioAssetPage> {
  static const List<String> _categories = [
    'altin',
    'hisse',
    'doviz',
    'kripto',
    'fon',
    'endeks',
  ];

  late String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<PortfolioItem>> _portfolioStream;
  String _searchQuery = '';
  _AssetSort _selectedSort = _AssetSort.nameAsc;
  Future<PortfolioValuation>? _valuationFuture;
  String? _valuationFingerprint;

  @override
  void initState() {
    super.initState();
    _portfolioStream = PortfolioRepository.instance.watchPortfolio();
    final initial = widget.initialCategory?.trim();
    _selectedCategory = initial == null || initial.isEmpty
        ? null
        : _normalizedCategory(initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fingerprint(List<PortfolioItem> items) {
    final sorted = [...items]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map(
          (item) => [
            item.id,
            item.symbol,
            item.type,
            item.quantity.toStringAsFixed(8),
            item.averagePrice.toStringAsFixed(8),
            item.currency,
          ].join('|'),
        )
        .join('::');
  }

  Future<PortfolioValuation> _valuationFor(
    List<PortfolioItem> items, {
    bool forceRefresh = false,
  }) {
    final fingerprint = _fingerprint(items);
    if (!forceRefresh &&
        _valuationFuture != null &&
        _valuationFingerprint == fingerprint) {
      return _valuationFuture!;
    }

    _valuationFingerprint = fingerprint;
    return _valuationFuture = PortfolioValuationService.instance.calculate(
      items,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _refreshValuation(List<PortfolioItem> items) async {
    late final Future<PortfolioValuation> refreshFuture;
    setState(() {
      refreshFuture = _valuationFor(items, forceRefresh: true);
      _valuationFuture = refreshFuture;
    });
    await refreshFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Portföy Varlıkları'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: _portfolioStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: SurfaceCard(
                  child: Text(
                    'Portföy verisi alınırken bir hata oluştu.',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? <PortfolioItem>[];
            final query = _searchQuery.trim().toLowerCase();

            final visibleItems =
                items.where((item) {
                  final categoryMatches =
                      _selectedCategory == null ||
                      _normalizedCategory(item.type) == _selectedCategory;

                  final searchableText =
                      '${item.name} ${item.symbol} ${item.type}'.toLowerCase();
                  final searchMatches =
                      query.isEmpty || searchableText.contains(query);

                  return categoryMatches && searchMatches;
                }).toList()..sort((first, second) {
                  final firstTitle =
                      (first.name.isNotEmpty ? first.name : first.symbol)
                          .toLowerCase();
                  final secondTitle =
                      (second.name.isNotEmpty ? second.name : second.symbol)
                          .toLowerCase();

                  switch (_selectedSort) {
                    case _AssetSort.nameAsc:
                      return firstTitle.compareTo(secondTitle);
                    case _AssetSort.nameDesc:
                      return secondTitle.compareTo(firstTitle);
                    case _AssetSort.quantityDesc:
                      return second.quantity.compareTo(first.quantity);
                    case _AssetSort.quantityAsc:
                      return first.quantity.compareTo(second.quantity);
                    case _AssetSort.costDesc:
                      return second.totalCost.compareTo(first.totalCost);
                    case _AssetSort.costAsc:
                      return first.totalCost.compareTo(second.totalCost);
                  }
                });
            final categoryCount = items
                .map((item) => _normalizedCategory(item.type))
                .where((category) => category.isNotEmpty)
                .toSet()
                .length;

            final valuationFuture = _valuationFor(items);

            return FutureBuilder<PortfolioValuation>(
              future: valuationFuture,
              builder: (context, valuationSnapshot) {
                final valuation = valuationSnapshot.data;
                final valuationsById = <String, PortfolioItemValuation>{
                  for (final value
                      in valuation?.items ?? const <PortfolioItemValuation>[])
                    value.item.id: value,
                };
                final visibleValuations = visibleItems
                    .map((item) => valuationsById[item.id])
                    .whereType<PortfolioItemValuation>()
                    .toList(growable: false);
                final categoryTotal = visibleValuations.fold<double>(
                  0,
                  (sum, value) => sum + value.currentValueInBaseCurrency,
                );
                final categoryProfit = visibleValuations.fold<double>(
                  0,
                  (sum, value) => sum + value.profitLossInBaseCurrency,
                );
                final categoryCost = visibleValuations.fold<double>(
                  0,
                  (sum, value) => sum + value.costInBaseCurrency,
                );

                return RefreshIndicator(
                  onRefresh: () => _refreshValuation(items),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                    children: [
                      Text(
                        '${visibleItems.length} varlık • $categoryCount kategori',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Varlık ara...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Aramayı temizle',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF0284C7),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _CategoryFilter(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onSelected: (category) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCategory == null
                                  ? 'Varlıklar'
                                  : '${_categoryLabel(_selectedCategory!)} Varlıkları',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          PopupMenuButton<_AssetSort>(
                            tooltip: 'Sırala',
                            initialValue: _selectedSort,
                            onSelected: (sort) {
                              setState(() => _selectedSort = sort);
                            },
                            itemBuilder: (context) => _AssetSort.values
                                .map(
                                  (sort) => PopupMenuItem<_AssetSort>(
                                    value: sort,
                                    child: Row(
                                      children: [
                                        if (_selectedSort == sort)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                              color: Color(0xFF0284C7),
                                            ),
                                          )
                                        else
                                          const SizedBox(width: 26),
                                        Text(_sortLabel(sort)),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF8FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFBAE6FD),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.swap_vert_rounded,
                                    size: 18,
                                    color: Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _sortLabel(_selectedSort),
                                    style: const TextStyle(
                                      color: Color(0xFF0369A1),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedCategory != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: valuation == null
                              ? const SizedBox(
                                  height: 24,
                                  child: Center(
                                    child: LinearProgressIndicator(),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Toplam ${_categoryLabel(_selectedCategory!)} Değeri',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'K/Z ${formatCurrency(categoryProfit)} '
                                            '(${formatPercent(categoryCost <= 0 ? 0 : categoryProfit / categoryCost * 100)})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: categoryProfit > 0
                                                  ? const Color(0xFF16A34A)
                                                  : categoryProfit < 0
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(categoryTotal, 'TRY'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (visibleItems.isEmpty)
                        SurfaceCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 34,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Eşleşen varlık bulunamadı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'Arama kelimesini veya kategori filtresini değiştir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                int index = 0;
                                index < visibleItems.length;
                                index++
                              ) ...[
                                _AssetTile(
                                  item: visibleItems[index],
                                  valuation:
                                      valuationsById[visibleItems[index].id],
                                  isLoading:
                                      valuationSnapshot.connectionState ==
                                      ConnectionState.waiting,
                                ),
                                if (index != visibleItems.length - 1)
                                  const ThinDivider(),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            noAnimationRoute(
              builder: (_) => const TransactionEntryPage(showBottomNav: true),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni İşlem'),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const MyFinBottomNav(
              selectedIndex: 1,
              allowSelectedDestinationNavigation: true,
            )
          : null,
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const _CategoryFilter({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tümü'),
              selected: selectedCategory == null,
              showCheckmark: false,
              selectedColor: const Color(0xFF0F73C5),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selectedCategory == null
                    ? Colors.white
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w400,
              ),
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_categoryLabel(category)),
                selected: selectedCategory == category,
                showCheckmark: false,
                selectedColor: const Color(0xFF0F73C5),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selectedCategory == category
                      ? Colors.white
                      : const Color(0xFF475569),
                  fontWeight: FontWeight.w400,
                ),
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final PortfolioItem item;
  final PortfolioItemValuation? valuation;
  final bool isLoading;

  const _AssetTile({
    required this.item,
    required this.valuation,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.name.isNotEmpty ? item.name : item.symbol;
    final hasLivePrice = valuation?.hasLivePrice == true;
    final profitLoss = valuation?.profitLossInBaseCurrency ?? 0;
    final profitPercent = valuation?.profitPercent ?? 0;
    final performanceColor = profitLoss > 0
        ? const Color(0xFF16A34A)
        : profitLoss < 0
        ? const Color(0xFFDC2626)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(noAnimationRoute(builder: (_) => AssetDetailPage(item: item)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFBAE6FD),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                item.symbol.isNotEmpty ? item.symbol.characters.first : '?',
                style: const TextStyle(
                  color: Color(0xFF075985),
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${formatQuantity(item.quantity)} adet',
                          style: const TextStyle(
                            color: Color(0xFF0369A1),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(text: ' • ${_categoryLabel(item.type)}'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Alış: ${formatCurrency(item.averagePrice, item.currency)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasLivePrice ? 'Güncel Değer' : 'Maliyet',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valuation == null
                      ? formatCurrency(item.totalCost, item.currency)
                      : formatCurrency(valuation!.currentValueInBaseCurrency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading && valuation == null
                      ? 'Fiyat alınıyor…'
                      : hasLivePrice
                      ? '${profitLoss >= 0 ? '+' : ''}${formatCurrency(profitLoss)} • ${formatPercent(profitPercent)}'
                      : 'Canlı fiyat yok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasLivePrice
                        ? performanceColor
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
