import 'package:flutter/material.dart';
import '../transactions/transaction_entry_page.dart';
import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_valuation_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/empty_state_line.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/common/thin_divider.dart';
import '../../widgets/dashboard/distribution_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../my_fin_home.dart' as legacy;
import '../../utils/no_animation_route.dart';
import 'portfolio_asset_page.dart';
import 'asset_detail_page.dart';
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

class PortfolioPage extends StatelessWidget {
  final bool showBottomNav;
  final String? initialCategory;

  const PortfolioPage({
    super.key,
    this.showBottomNav = true,
    this.initialCategory,
  });

  void _openAssets(BuildContext context, {String? category}) {
    Navigator.of(context).push(
      noAnimationRoute(
        builder: (_) => PortfolioAssetPage(
          initialCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portföy'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<PortfolioItem>>(
          stream: PortfolioRepository.instance.watchPortfolio(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
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

            return FutureBuilder<PortfolioValuation>(
              key: ValueKey(
                'portfolio-live-summary-${items.length}-${items.fold<double>(0, (sum, item) => sum + item.totalCost)}',
              ),
              future: PortfolioValuationService.instance.calculate(items),
              builder: (context, summarySnapshot) {
                final valuation = summarySnapshot.data;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  children: [
                    if (valuation == null)
                      const SurfaceCard(
                        child: SizedBox(
                          height: 210,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else
                      _PortfolioSummaryCard(summary: valuation),
                    const SizedBox(height: 18),
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _openAssets(
                        context,
                        category: initialCategory,
                      ),
                      child: SurfaceCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Portföy Varlıklarını Gör',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${items.length} varlık • filtrele ve incele',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF0284C7),
                            ),
                          ],
                        ),
                      ),
                    ),
                     
                     const SizedBox(height: 14),
                    _DistributionCard(refreshTick: items.length),
                    
                    
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
              builder: (_) => const TransactionEntryPage(
                showBottomNav: true,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni İşlem'),
      ),
      bottomNavigationBar:
          showBottomNav ? const MyFinBottomNav(selectedIndex: 1) : null,
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final int refreshTick;

  const _DistributionCard({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SurfaceCard(
            child: SizedBox(
              height: 145,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return const SurfaceCard(
            child: EmptyStateLine(
              icon: Icons.donut_large_rounded,
              title: 'Dağılım için veri yok',
              subtitle:
                  'Varlık eklediğinde portföy dağılımı otomatik hesaplanacak.',
            ),
          );
        }

        return FutureBuilder<_DistributionSnapshot>(
          key: ValueKey('distribution-$refreshTick-${items.length}'),
          future: _loadDistributionSnapshot(items),
          builder: (context, distributionSnapshot) {
            final distribution =
                distributionSnapshot.data ?? _DistributionSnapshot.fromCost(items);
            return DistributionCard(
              title: 'Portföy Dağılımı',
              items: distribution.segments
                  .map(
                    (segment) => DistributionItem(
                      label: segment.label,
                      value: segment.ratio * distribution.totalValue,
                      color: segment.color,
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  final PortfolioValuation summary;

  const _PortfolioSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final profitPositive = summary.totalProfit >= 0;
    final profitColor =
        profitPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final profitPrefix = profitPositive ? '+' : '';

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBox(
                icon: Icons.account_balance_wallet_rounded,
                color: Color(0xFF008DB9),
                size: 46,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portföy Özeti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Canlı piyasa verileriyle güncellenir',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF008DB9).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${summary.assetCount} varlık',
                  style: const TextStyle(
                    color: Color(0xFF008DB9),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            formatCurrency(summary.totalValue, summary.baseCurrency),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Güncel Portföy Değeri',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: profitColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  profitPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: profitColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$profitPrefix${formatCurrency(summary.totalProfit.abs(), summary.baseCurrency)}',
                    style: TextStyle(
                      color: profitColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatPercent(summary.profitPercent),
                  style: TextStyle(
                    color: profitColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PortfolioSummaryMetric(
                  label: 'Toplam Maliyet',
                  value: formatCurrency(
                    summary.totalCost,
                    summary.baseCurrency,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PortfolioSummaryMetric(
                  label: 'Toplam Getiri',
                  value: formatPercent(summary.profitPercent),
                  valueColor: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioSummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PortfolioSummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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
      ),
    );
  }
}

class _PortfolioList extends StatelessWidget {
  final int refreshTick;
  final List<PortfolioItem>? items;

  const _PortfolioList({required this.refreshTick, this.items});

  @override
  Widget build(BuildContext context) {
    final providedItems = items;
    if (providedItems != null) {
      return _PortfolioListContent(items: providedItems);
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

        return _PortfolioListContent(items: snapshot.data ?? []);
      },
    );
  }
}

class _PortfolioListContent extends StatelessWidget {
  final List<PortfolioItem> items;

  const _PortfolioListContent({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SurfaceCard(
        child: Text(
          'Henüz portföy varlığı yok. Yeni Varlık butonuyla ilk varlığını ekleyebilirsin.',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      );
    }

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _PortfolioAssetTile(item: items[index]),
            if (index != items.length - 1) const ThinDivider(),
          ],
        ],
      ),
    );
  }
}

class _PortfolioAssetTile extends StatelessWidget {
  final PortfolioItem item;

  const _PortfolioAssetTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item.name.isNotEmpty ? item.name : item.symbol;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          noAnimationRoute(
            builder: (_) => AssetDetailPage(item: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFBAE6FD),
              child: Text(
                item.symbol.isNotEmpty ? item.symbol.characters.first : '?',
                style: const TextStyle(
                  color: Color(0xFF075985),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatQuantity(item.quantity)} adet • ${item.type}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w700,
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
                  formatCurrency(item.totalCost, item.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Maliyet',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

Future<_DistributionSnapshot> _loadDistributionSnapshot(
  List<PortfolioItem> items,
) async {
  return _DistributionSnapshot.fromCost(items);
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
