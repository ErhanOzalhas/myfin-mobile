import 'package:flutter/material.dart';
import '../transactions/transaction_entry_page.dart';
import '../performance/profit_loss_detail_page.dart';
import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_valuation_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/empty_state_line.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/common/thin_divider.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../../utils/no_animation_route.dart';
import 'asset_detail_page.dart';
import 'portfolio_asset_page.dart';

String _normalizedPortfolioCategory(String type) {
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

bool _samePortfolioCategory(String first, String second) {
  return _normalizedPortfolioCategory(first) ==
      _normalizedPortfolioCategory(second);
}

String _portfolioCategoryLabel(String type) {
  switch (_normalizedPortfolioCategory(type)) {
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

String _assetSortLabel(_AssetSort sort) {
  switch (sort) {
    case _AssetSort.nameAsc:
      return 'A – Z';
    case _AssetSort.nameDesc:
      return 'Z – A';
    case _AssetSort.quantityDesc:
      return 'Adet ↓';
    case _AssetSort.quantityAsc:
      return 'Adet ↑';
    case _AssetSort.costDesc:
      return 'Maliyet ↓';
    case _AssetSort.costAsc:
      return 'Maliyet ↑';
  }
}

class PortfolioPage extends StatefulWidget {
  final bool showBottomNav;
  final String? initialCategory;

  const PortfolioPage({
    super.key,
    this.showBottomNav = true,
    this.initialCategory,
  });

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  Future<PortfolioValuation>? _valuationFuture;
  PortfolioValuation? _lastValuation;
  String? _valuationFingerprint;

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Tümü';
  String _searchText = '';
  _AssetSort _selectedSort = _AssetSort.nameAsc;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory?.trim();
    if (initial != null && initial.isNotEmpty) {
      _selectedCategory = _portfolioCategoryLabel(initial);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category && category != 'Tümü'
          ? 'Tümü'
          : category;
    });
  }

  List<PortfolioItem> _visibleItems(List<PortfolioItem> items) {
    final query = _searchText.trim().toLowerCase();

    final filtered = items.where((item) {
      final matchesCategory =
          _selectedCategory == 'Tümü' ||
          _samePortfolioCategory(item.type, _selectedCategory);

      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      return item.name.toLowerCase().contains(query) ||
          item.symbol.toLowerCase().contains(query) ||
          _portfolioCategoryLabel(item.type).toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final firstTitle = (a.name.isNotEmpty ? a.name : a.symbol).toLowerCase();
      final secondTitle = (b.name.isNotEmpty ? b.name : b.symbol).toLowerCase();

      switch (_selectedSort) {
        case _AssetSort.nameAsc:
          return firstTitle.compareTo(secondTitle);
        case _AssetSort.nameDesc:
          return secondTitle.compareTo(firstTitle);
        case _AssetSort.quantityDesc:
          return b.quantity.compareTo(a.quantity);
        case _AssetSort.quantityAsc:
          return a.quantity.compareTo(b.quantity);
        case _AssetSort.costDesc:
          return b.totalCost.compareTo(a.totalCost);
        case _AssetSort.costAsc:
          return a.totalCost.compareTo(b.totalCost);
      }
    });

    return filtered;
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

  Future<PortfolioValuation> _valuationFor(List<PortfolioItem> items) {
    final fingerprint = _fingerprint(items);
    final cached = PortfolioValuationService.instance.peek(items);
    if (cached != null) _lastValuation = cached;

    // Bu sayfa instance'ında aynı hesap zaten kullanılıyorsa tekrar başlatma.
    if (_valuationFuture != null && _valuationFingerprint == fingerprint) {
      return _valuationFuture!;
    }

    _valuationFingerprint = fingerprint;

    // Ana sayfa ile aynı servis önbelleğini ve aynı devam eden isteği paylaş.
    final future = PortfolioValuationService.instance.calculate(items).then((
      valuation,
    ) {
      _lastValuation = valuation;
      return valuation;
    });

    _valuationFuture = future;

    return future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portföy'), centerTitle: false),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: PortfolioRepository.instance.watchPortfolio(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && !snapshot.hasData) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: const [
                  SurfaceCard(
                    child: Text(
                      'Portföy verisi alınırken bir hata oluştu.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            }

            final items = snapshot.data ?? <PortfolioItem>[];
            final valuationFuture = _valuationFor(items);

            return FutureBuilder<PortfolioValuation>(
              future: valuationFuture,
              initialData:
                  PortfolioValuationService.instance.peek(items) ??
                  _lastValuation,
              builder: (context, summarySnapshot) {
                final valuation = summarySnapshot.data ?? _lastValuation;

                final selectedSummary = _SelectedCategorySnapshot.from(
                  category: _selectedCategory,
                  items: items,
                  valuation: valuation,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  children: [
                    _PortfolioSectionHeader(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Varlıklarım',
                      actionLabel:
                          '${valuation?.assetCount ?? items.length} Varlık',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const PortfolioAssetPage(showBottomNav: false),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    valuation == null
                        ? const SurfaceCard(
                            child: SizedBox(
                              height: 126,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : _PortfolioSummaryCard(summary: valuation),
                    const SizedBox(height: 18),
                    _DistributionCard(
                      items: items,
                      valuation: valuation,
                      selectedCategory: _selectedCategory,
                      onCategoryTap: _selectCategory,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchText = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Varlık ara...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchText.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Temizle',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchText = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFD7E0EA),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFD7E0EA),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF0284C7),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _PortfolioCategoryFilters(
                      items: items,
                      selectedCategory: _selectedCategory,
                      onSelected: _selectCategory,
                    ),
                    const SizedBox(height: 14),
                    _AssetsHeader(
                      sort: _selectedSort,
                      onSortSelected: (value) {
                        setState(() => _selectedSort = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (selectedSummary != null) ...[
                      _SelectedCategorySummary(snapshot: selectedSummary),
                      const SizedBox(height: 10),
                    ],
                    _PortfolioList(
                      refreshTick: 0,
                      items: _visibleItems(items),
                      valuation: valuation,
                      isValuationLoading:
                          summarySnapshot.connectionState ==
                          ConnectionState.waiting,
                      emptyMessage: _searchText.trim().isNotEmpty
                          ? 'Aramana uygun varlık bulunamadı.'
                          : _selectedCategory == 'Tümü'
                          ? 'Henüz portföy varlığı yok.'
                          : '$_selectedCategory kategorisinde varlık bulunamadı.',
                    ),
                  ],
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
          ? const MyFinBottomNav(selectedIndex: 1)
          : null,
    );
  }
}

class _PortfolioSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String actionLabel;
  final VoidCallback onActionTap;

  const _PortfolioSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -.2,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onActionTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF0284C7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final List<PortfolioItem> items;
  final PortfolioValuation? valuation;
  final String selectedCategory;
  final ValueChanged<String> onCategoryTap;

  const _DistributionCard({
    required this.items,
    required this.valuation,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final distribution = valuation == null
        ? _DistributionSnapshot.fromCost(items)
        : _DistributionSnapshot.fromValuation(valuation!);
    final performanceByCategory = _CategoryPerformance.fromValuation(valuation);
    const categories = <String>['Altın', 'Hisse', 'Döviz', 'Kripto'];

    final segments = categories
        .map((category) {
          return distribution.segments.firstWhere(
            (segment) => segment.label == category,
            orElse: () => _DistributionSegment(
              label: category,
              ratio: 0,
              color: _assetTypeColor(category),
            ),
          );
        })
        .where((segment) => segment.ratio > 0)
        .toList(growable: false);

    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portföy Dağılımı',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          for (int index = 0; index < segments.length; index++) ...[
            _DistributionProgressRow(
              segment: segments[index],
              value: distribution.totalValue * segments[index].ratio,
              changePercent:
                  performanceByCategory[segments[index].label]?.changePercent,
              onTap: () => onCategoryTap(segments[index].label),
            ),
            if (index != segments.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _DistributionProgressRow extends StatelessWidget {
  final _DistributionSegment segment;
  final double value;
  final double? changePercent;
  final VoidCallback onTap;

  const _DistributionProgressRow({
    required this.segment,
    required this.value,
    required this.changePercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = segment.ratio * 100;
    final change = changePercent;
    final isPositive = change != null && change > 0;
    final isNegative = change != null && change < 0;
    final changeColor = isPositive
        ? const Color(0xFF16A34A)
        : isNegative
        ? const Color(0xFFDC2626)
        : const Color(0xFF94A3B8);
    final changeLabel = change == null || change.abs() < 0.005
        ? '–'
        : '${isPositive ? '▲ +' : '▼ -'}${change.abs().toStringAsFixed(2).replaceAll('.', ',')}%';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    segment.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Text(
                  formatCurrency(value),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 68,
                  child: Text(
                    changeLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isPositive || isNegative
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: changeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _MinimumVisibleProgressBar(
                    value: segment.ratio,
                    color: segment.color,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${percent.toStringAsFixed(1).replaceAll('.', ',')}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
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

class _MinimumVisibleProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _MinimumVisibleProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final normalized = value.clamp(0.0, 1.0).toDouble();
        final fillWidth = normalized <= 0
            ? 0.0
            : (constraints.maxWidth * normalized)
                  .clamp(4.0, constraints.maxWidth)
                  .toDouble();

        return Container(
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: fillWidth,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }
}

class _DistributionFilterRow extends StatelessWidget {
  final _DistributionSegment segment;
  final bool selected;
  final VoidCallback onTap;

  const _DistributionFilterRow({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = segment.ratio * 100;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    segment.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: selected ? segment.color : const Color(0xFF334155),
                    ),
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  size: 16,
                  color: selected ? segment.color : const Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: segment.ratio.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(segment.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioCategoryFilters extends StatelessWidget {
  final List<PortfolioItem> items;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _PortfolioCategoryFilters({
    required this.items,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = <String>['Tümü'];

    for (final item in items) {
      final label = _portfolioCategoryLabel(item.type);
      if (!categories.contains(label)) categories.add(label);
    }

    const order = <String>[
      'Tümü',
      'Altın',
      'Hisse',
      'Döviz',
      'Kripto',
      'Fon',
      'Endeks',
      'Diğer',
    ];

    categories.sort((a, b) {
      final aIndex = order.indexOf(a);
      final bIndex = order.indexOf(b);
      final safeA = aIndex == -1 ? order.length : aIndex;
      final safeB = bIndex == -1 ? order.length : bIndex;
      return safeA.compareTo(safeB);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((category) {
              final selected = category == selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => onSelected(category),
                  selectedColor: const Color(0xFF0F73C5),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF0F73C5)
                        : const Color(0xFFD7E0EA),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _AssetsHeader extends StatelessWidget {
  final _AssetSort sort;
  final ValueChanged<_AssetSort> onSortSelected;

  const _AssetsHeader({required this.sort, required this.onSortSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Varlıklar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        PopupMenuButton<_AssetSort>(
          tooltip: 'Sıralama seç',
          initialValue: sort,
          onSelected: onSortSelected,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              height: 32,
              value: _AssetSort.nameAsc,
              child: Text('A – Z'),
            ),
            PopupMenuItem(
              height: 32,
              value: _AssetSort.nameDesc,
              child: Text('Z – A'),
            ),
            PopupMenuDivider(height: 4),
            PopupMenuItem(
              height: 32,
              value: _AssetSort.quantityDesc,
              child: Text('Adet ↓'),
            ),
            PopupMenuItem(
              height: 32,
              value: _AssetSort.quantityAsc,
              child: Text('Adet ↑'),
            ),
            PopupMenuDivider(height: 4),
            PopupMenuItem(
              height: 32,
              value: _AssetSort.costDesc,
              child: Text('Maliyet ↓'),
            ),
            PopupMenuItem(
              height: 32,
              value: _AssetSort.costAsc,
              child: Text('Maliyet ↑'),
            ),
          ],
          child: IgnorePointer(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.swap_vert_rounded, size: 19),
              label: Text(_assetSortLabel(sort)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedCategorySnapshot {
  final String category;
  final double totalCost;
  final double? changePercent;

  const _SelectedCategorySnapshot({
    required this.category,
    required this.totalCost,
    required this.changePercent,
  });

  factory _SelectedCategorySnapshot.from({
    required String category,
    required List<PortfolioItem> items,
    required PortfolioValuation? valuation,
  }) {
    final isAll = category == 'Tümü';

    final totalCost = isAll && valuation != null
        ? valuation.totalCost
        : items
              .where((item) => _portfolioCategoryLabel(item.type) == category)
              .fold<double>(0, (sum, item) => sum + item.totalCost);

    final performance = _CategoryPerformance.fromValuation(valuation)[category];

    return _SelectedCategorySnapshot(
      category: category,
      totalCost: totalCost,
      changePercent: isAll
          ? valuation?.profitPercent
          : performance?.changePercent,
    );
  }
}

class _SelectedCategorySummary extends StatelessWidget {
  final _SelectedCategorySnapshot snapshot;

  const _SelectedCategorySummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final change = snapshot.changePercent;
    final isPositive = change != null && change > 0;
    final isNegative = change != null && change < 0;
    final changeColor = isPositive
        ? const Color(0xFF16A34A)
        : isNegative
        ? const Color(0xFFDC2626)
        : const Color(0xFF94A3B8);
    final changeLabel = change == null || change.abs() < 0.005
        ? '–'
        : '${isPositive ? '▲ +' : '▼ -'}${change.abs().toStringAsFixed(2).replaceAll('.', ',')}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              snapshot.category,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            formatCurrency(snapshot.totalCost),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 72,
            child: Text(
              changeLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isPositive || isNegative
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: changeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  final PortfolioValuation summary;

  const _PortfolioSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final profitPositive = summary.totalProfit >= 0;
    final profitColor = profitPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final profitPrefix = profitPositive ? '+' : '-';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Güncel Değer',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatCurrency(summary.totalValue, summary.baseCurrency),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              height: 1.02,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () {
                  Navigator.of(context).push(
                    noAnimationRoute(
                      builder: (_) => const ProfitLossDetailPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        profitPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 15,
                        color: profitColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '$profitPrefix${formatCurrency(summary.totalProfit.abs(), summary.baseCurrency)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: profitColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        profitPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 15,
                        color: profitColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        formatPercent(summary.profitPercent),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: profitColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: profitColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const ThinDivider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Maliyet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0F3A5D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatCurrency(summary.totalCost, summary.baseCurrency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F3A5D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CompactSummaryValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PortfolioList extends StatelessWidget {
  final int refreshTick;
  final List<PortfolioItem>? items;
  final PortfolioValuation? valuation;
  final bool isValuationLoading;
  final String? emptyMessage;

  const _PortfolioList({
    required this.refreshTick,
    this.items,
    this.valuation,
    this.isValuationLoading = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final providedItems = items;
    if (providedItems != null) {
      return _PortfolioListContent(
        items: providedItems,
        valuation: valuation,
        isValuationLoading: isValuationLoading,
        emptyMessage: emptyMessage,
      );
    }

    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SurfaceCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SurfaceCard(
            child: Text(
              'Portföy verisi alınırken bir hata oluştu.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        }

        return _PortfolioListContent(
          items: snapshot.data ?? [],
          valuation: valuation,
          isValuationLoading: isValuationLoading,
          emptyMessage: emptyMessage,
        );
      },
    );
  }
}

class _PortfolioListContent extends StatelessWidget {
  final List<PortfolioItem> items;
  final PortfolioValuation? valuation;
  final bool isValuationLoading;
  final String? emptyMessage;

  const _PortfolioListContent({
    required this.items,
    required this.valuation,
    required this.isValuationLoading,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SurfaceCard(
        child: Text(
          emptyMessage ??
              'Henüz portföy varlığı yok. Yeni İşlem butonuyla ilk varlığını ekleyebilirsin.',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      );
    }

    final valuationsById = <String, PortfolioItemValuation>{
      for (final value in valuation?.items ?? const <PortfolioItemValuation>[])
        value.item.id: value,
    };

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _PortfolioAssetTile(
              item: items[index],
              valuation: valuationsById[items[index].id],
              isLoading: isValuationLoading,
            ),
            if (index != items.length - 1) const ThinDivider(),
          ],
        ],
      ),
    );
  }
}

class _PortfolioAssetTile extends StatelessWidget {
  final PortfolioItem item;
  final PortfolioItemValuation? valuation;
  final bool isLoading;

  const _PortfolioAssetTile({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(noAnimationRoute(builder: (_) => AssetDetailPage(item: item)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  item.symbol.isNotEmpty
                      ? item.symbol.characters.first.toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${formatQuantity(item.quantity)} adet',
                            style: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: ' • ${item.type}'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Alış: ${formatCurrency(item.averagePrice, item.currency)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96, maxWidth: 132),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasLivePrice ? 'Güncel Değer' : 'Maliyet',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valuation == null
                          ? formatCurrency(item.totalCost, item.currency)
                          : formatCurrency(
                              valuation!.currentValueInBaseCurrency,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -.15,
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
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: hasLivePrice
                            ? performanceColor
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPerformance {
  final double changePercent;

  const _CategoryPerformance({required this.changePercent});

  static Map<String, _CategoryPerformance> fromValuation(
    PortfolioValuation? valuation,
  ) {
    if (valuation == null) return const {};

    final costs = <String, double>{};
    final currentValues = <String, double>{};
    final hasLivePrice = <String, bool>{};

    for (final itemValuation in valuation.items) {
      final category = _portfolioCategoryLabel(itemValuation.item.type);
      costs[category] =
          (costs[category] ?? 0) + itemValuation.costInBaseCurrency;
      currentValues[category] =
          (currentValues[category] ?? 0) +
          itemValuation.currentValueInBaseCurrency;
      hasLivePrice[category] =
          (hasLivePrice[category] ?? false) || itemValuation.hasLivePrice;
    }

    final result = <String, _CategoryPerformance>{};

    for (final entry in costs.entries) {
      final category = entry.key;
      final cost = entry.value;

      if (cost <= 0 || hasLivePrice[category] != true) continue;

      final currentValue = currentValues[category] ?? cost;
      result[category] = _CategoryPerformance(
        changePercent: ((currentValue - cost) / cost) * 100,
      );
    }

    return result;
  }
}

class _DistributionSnapshot {
  final double totalValue;
  final List<_DistributionSegment> segments;

  const _DistributionSnapshot({
    required this.totalValue,
    required this.segments,
  });

  factory _DistributionSnapshot.fromCost(List<PortfolioItem> items) {
    final totals = <String, double>{};
    for (final item in items) {
      totals[item.type] = (totals[item.type] ?? 0) + item.totalCost;
    }
    return _DistributionSnapshot.fromTotals(totals);
  }

  factory _DistributionSnapshot.fromValuation(PortfolioValuation valuation) {
    final totals = <String, double>{};

    for (final itemValuation in valuation.items) {
      final category = _portfolioCategoryLabel(itemValuation.item.type);
      totals[category] =
          (totals[category] ?? 0) + itemValuation.currentValueInBaseCurrency;
    }

    return _DistributionSnapshot.fromTotals(totals);
  }

  factory _DistributionSnapshot.fromTotals(Map<String, double> totals) {
    final total = totals.values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      return const _DistributionSnapshot(
        totalValue: 0,
        segments: [
          _DistributionSegment(
            label: 'Diğer',
            ratio: 1,
            color: Color(0xFF64748B),
          ),
        ],
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final segments = entries.take(4).map((entry) {
      return _DistributionSegment(
        label: _assetTypeLabel(entry.key),
        ratio: entry.value / total,
        color: _assetTypeColor(entry.key),
      );
    }).toList();

    return _DistributionSnapshot(totalValue: total, segments: segments);
  }
}

class _DistributionSegment {
  final String label;
  final double ratio;
  final Color color;

  const _DistributionSegment({
    required this.label,
    required this.ratio,
    required this.color,
  });
}

String _assetTypeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'altin':
    case 'altın':
      return 'Altın';
    case 'hisse':
    case 'bist':
      return 'Hisse';
    case 'doviz':
    case 'döviz':
      return 'Döviz';
    case 'fon':
      return 'Fon';
    case 'kripto':
      return 'Kripto';
    case 'endeks':
      return 'Endeks';
    default:
      return type.isEmpty ? 'Diğer' : type;
  }
}

Color _assetTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'altin':
    case 'altın':
      return const Color(0xFFF59E0B);
    case 'hisse':
    case 'bist':
      return const Color(0xFF2563EB);
    case 'doviz':
    case 'döviz':
      return const Color(0xFF16A34A);
    case 'fon':
      return const Color(0xFF7C3AED);
    case 'kripto':
      return const Color(0xFFF97316);
    case 'endeks':
      return const Color(0xFF0F766E);
    default:
      return const Color(0xFF64748B);
  }
}
