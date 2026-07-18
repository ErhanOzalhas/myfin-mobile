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
import '../portfolio/asset_detail_page.dart';

enum _PerformanceFilter { all, winners, losers }

class ProfitLossDetailPage extends StatefulWidget {
  const ProfitLossDetailPage({super.key});

  @override
  State<ProfitLossDetailPage> createState() => _ProfitLossDetailPageState();
}

class _ProfitLossDetailPageState extends State<ProfitLossDetailPage> {
  Future<PortfolioValuation>? _valuationFuture;
  PortfolioValuation? _lastValuation;
  String? _valuationFingerprint;
  _PerformanceFilter _filter = _PerformanceFilter.all;
  bool _sortDescending = true;

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
    final cached = PortfolioValuationService.instance.peek(items);
    if (cached != null) _lastValuation = cached;

    if (!forceRefresh &&
        _valuationFuture != null &&
        _valuationFingerprint == fingerprint) {
      return _valuationFuture!;
    }

    _valuationFingerprint = fingerprint;
    return _valuationFuture = PortfolioValuationService.instance
        .calculate(items, forceRefresh: forceRefresh)
        .then((valuation) {
          _lastValuation = valuation;
          return valuation;
        });
  }

  Future<void> _refresh(List<PortfolioItem> items) async {
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
        title: const Text('Kâr / Zarar Detayı'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: PortfolioRepository.instance.watchPortfolio(),
          builder: (context, portfolioSnapshot) {
            if (portfolioSnapshot.connectionState == ConnectionState.waiting &&
                !portfolioSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (portfolioSnapshot.hasError && !portfolioSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: SurfaceCard(child: Text('Portföy verisi alınamadı.')),
              );
            }

            final items = portfolioSnapshot.data ?? <PortfolioItem>[];

            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: SurfaceCard(
                  child: Text('Performansı gösterilecek varlık bulunmuyor.'),
                ),
              );
            }

            return FutureBuilder<PortfolioValuation>(
              future: _valuationFor(items),
              initialData:
                  PortfolioValuationService.instance.peek(items) ??
                  _lastValuation,
              builder: (context, valuationSnapshot) {
                final valuation = valuationSnapshot.data ?? _lastValuation;

                if (valuation == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final visibleItems =
                    valuation.items.where((item) {
                      if (!item.hasLivePrice) {
                        return _filter == _PerformanceFilter.all;
                      }
                      return switch (_filter) {
                        _PerformanceFilter.all => true,
                        _PerformanceFilter.winners =>
                          item.profitLossInBaseCurrency > 0,
                        _PerformanceFilter.losers =>
                          item.profitLossInBaseCurrency < 0,
                      };
                    }).toList()..sort((a, b) {
                      final comparison = a.profitLossInBaseCurrency.compareTo(
                        b.profitLossInBaseCurrency,
                      );
                      return _sortDescending ? -comparison : comparison;
                    });

                final winners = valuation.items
                    .where(
                      (item) =>
                          item.hasLivePrice &&
                          item.profitLossInBaseCurrency > 0,
                    )
                    .length;
                final losers = valuation.items
                    .where(
                      (item) =>
                          item.hasLivePrice &&
                          item.profitLossInBaseCurrency < 0,
                    )
                    .length;

                return RefreshIndicator(
                  onRefresh: () => _refresh(items),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    children: [
                      _ProfitLossSummary(valuation: valuation),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChip(
                              label: 'Tümü',
                              count: valuation.items.length,
                              selected: _filter == _PerformanceFilter.all,
                              onTap: () => setState(
                                () => _filter = _PerformanceFilter.all,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterChip(
                              label: 'Kazandıran',
                              count: winners,
                              selected: _filter == _PerformanceFilter.winners,
                              onTap: () => setState(
                                () => _filter = _PerformanceFilter.winners,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterChip(
                              label: 'Kaybettiren',
                              count: losers,
                              selected: _filter == _PerformanceFilter.losers,
                              onTap: () => setState(
                                () => _filter = _PerformanceFilter.losers,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Varlık Performansı',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Text(
                            'Fiyat',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 3),
                          _SortIconButton(
                            icon: Icons.arrow_downward_rounded,
                            tooltip: 'En yüksekten en düşüğe',
                            selected: _sortDescending,
                            onTap: () => setState(() => _sortDescending = true),
                          ),
                          _SortIconButton(
                            icon: Icons.arrow_upward_rounded,
                            tooltip: 'En düşükten en yükseğe',
                            selected: !_sortDescending,
                            onTap: () =>
                                setState(() => _sortDescending = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (visibleItems.isEmpty)
                        const SurfaceCard(
                          child: Text(
                            'Bu filtreye uygun varlık bulunmuyor.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < visibleItems.length;
                                index++
                              ) ...[
                                _PerformanceTile(
                                  valuation: visibleItems[index],
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
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 0,
        allowSelectedDestinationNavigation: true,
      ),
    );
  }
}

class _SortIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _SortIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Icon(
            icon,
            size: 24,
            color: selected ? const Color(0xFF0E7490) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _ProfitLossSummary extends StatelessWidget {
  final PortfolioValuation valuation;

  const _ProfitLossSummary({required this.valuation});

  @override
  Widget build(BuildContext context) {
    final isPositive = valuation.totalProfit >= 0;
    final color = isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: .018),
            const Color(0xFFFCFDFE),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: .055)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toplam Kâr / Zarar',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${valuation.totalProfit >= 0 ? '+' : ''}${formatCurrency(valuation.totalProfit)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatPercent(valuation.profitPercent),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Güncel portföy değeri ${formatCurrency(valuation.totalValue)}',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F73C5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0F73C5) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceTile extends StatelessWidget {
  final PortfolioItemValuation valuation;

  const _PerformanceTile({required this.valuation});

  @override
  Widget build(BuildContext context) {
    final item = valuation.item;
    final title = item.name.isNotEmpty ? item.name : item.symbol;
    final isPositive = valuation.profitLossInBaseCurrency >= 0;
    final color = isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(noAnimationRoute(builder: (_) => AssetDetailPage(item: item))),
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
                item.symbol.isEmpty ? '?' : item.symbol.characters.first,
                style: const TextStyle(
                  color: Color(0xFF075985),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
                            fontWeight: FontWeight.w700,
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 104, maxWidth: 145),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valuation.hasLivePrice
                        ? '${valuation.profitLossInBaseCurrency >= 0 ? '+' : ''}${formatCurrency(valuation.profitLossInBaseCurrency)}'
                        : 'Canlı fiyat yok',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valuation.hasLivePrice
                          ? color
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (valuation.hasLivePrice)
                    Text(
                      formatPercent(valuation.profitPercent),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    )
                  else
                    const Text(
                      'Hesaplanamadı',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
