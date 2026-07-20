import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../models/portfolio_item.dart';
import '../../services/market/market_service.dart';
import '../../services/market/models/market_quote.dart';
import '../../utils/myfin_formatters.dart';
import '../../utils/no_animation_route.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/common/thin_divider.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import '../transactions/transaction_history_page.dart';

String _formatAssetDate(DateTime? date) {
  if (date == null) return 'Tarih bilgisi yok';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day.$month.$year';
}

String _formatUpdatedAt(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');

  return '$hour:$minute:$second';
}

String _marketStatusLabel(MarketStatus status) {
  return switch (status) {
    MarketStatus.open => 'Piyasa açık',
    MarketStatus.closed => 'Piyasa kapalı',
    MarketStatus.preMarket => 'Seans öncesi',
    MarketStatus.afterHours => 'Seans sonrası',
    MarketStatus.alwaysOpen => '7/24 açık',
    MarketStatus.unknown => 'Piyasa durumu bilinmiyor',
  };
}

Color _marketStatusColor(MarketStatus status) {
  return switch (status) {
    MarketStatus.open || MarketStatus.alwaysOpen => const Color(0xFF16A34A),
    MarketStatus.preMarket ||
    MarketStatus.afterHours => const Color(0xFFD97706),
    MarketStatus.closed => const Color(0xFF64748B),
    MarketStatus.unknown => const Color(0xFF94A3B8),
  };
}

class AssetDetailPage extends StatefulWidget {
  final PortfolioItem item;

  const AssetDetailPage({super.key, required this.item});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late Future<MarketQuote> _quoteFuture;

  PortfolioItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _quoteFuture = _loadQuote();
  }

  Future<MarketQuote> _loadQuote({bool forceRefresh = false}) {
    return MarketService.instance.getQuote(
      _marketSymbolFor(item),
      exchange: _marketExchangeFor(item),
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _quoteFuture = _loadQuote(forceRefresh: true);
    });

    try {
      await _quoteFuture;
    } catch (_) {
      // FutureBuilder shows the error state.
    }
  }

  void _retry() {
    setState(() {
      _quoteFuture = _loadQuote(forceRefresh: true);
    });
  }

  String _marketSymbolFor(PortfolioItem item) {
    final rawSymbol = item.symbol.trim().toUpperCase();
    final normalizedType = item.type.trim().toLowerCase();

    if (normalizedType == 'döviz' || normalizedType == 'doviz') {
      if (rawSymbol.contains('/')) {
        return rawSymbol;
      }

      if (rawSymbol.length == 3) {
        return '$rawSymbol/TRY';
      }
    }

    return rawSymbol;
  }

  String? _marketExchangeFor(PortfolioItem item) {
    final normalizedType = item.type.trim().toLowerCase();
    final currency = item.currency.trim().toUpperCase();

    if ((normalizedType == 'hisse' || normalizedType == 'bist') &&
        currency == 'TRY') {
      return 'XIST';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: Text(item.symbol),
        centerTitle: false,
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<MarketQuote>(
            future: _quoteFuture,
            builder: (context, snapshot) {
              final quote = snapshot.data;
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              final hasError = snapshot.hasError;

              return _buildContent(
                context,
                quote: quote,
                loading: loading,
                hasError: hasError,
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 1,
        allowSelectedDestinationNavigation: true,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required MarketQuote? quote,
    required bool loading,
    required bool hasError,
  }) {
    final totalCost = item.totalCost;
    final currenciesMatch =
        quote == null ||
        quote.currency.trim().toUpperCase() ==
            item.currency.trim().toUpperCase();

    final currentValue = quote == null
        ? totalCost
        : item.quantity * quote.price;

    final profitLoss = currenciesMatch ? currentValue - totalCost : 0.0;

    final profitPercent = currenciesMatch && totalCost > 0
        ? (profitLoss / totalCost) * 100
        : 0.0;

    final isProfit = profitLoss >= 0;
    final profitColor = isProfit
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final title = item.name.isNotEmpty ? item.name : item.symbol;
    final displayCurrency = quote?.currency ?? item.currency;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7FCFF), Color(0xFFEAF6FF), Color(0xFFDDF1FF)],
            ),
            border: Border.all(color: const Color(0xFFB9DDF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7CC5E8).withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD8EEFC),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.symbol.isNotEmpty
                          ? item.symbol.characters.first
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.symbol} • ${item.type} • $displayCurrency',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (loading)
                const SizedBox(
                  height: 39,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              else
                Text(
                  formatCurrency(currentValue, displayCurrency),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 31,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -.6,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                quote == null ? 'Maliyet bazlı değer' : 'Güncel değer',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: currenciesMatch
                      ? profitColor.withValues(alpha: .08)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: currenciesMatch
                    ? Row(
                        children: [
                          Icon(
                            isProfit
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: profitColor,
                            size: 21,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              '${isProfit ? '+' : ''}'
                              '${formatCurrency(profitLoss, displayCurrency)}',
                              style: TextStyle(
                                color: profitColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            formatPercent(profitPercent),
                            style: TextStyle(
                              color: profitColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Maliyet ve canlı fiyat farklı para birimlerinde.',
                              style: TextStyle(
                                color: Color(0xFF9A3412),
                                fontWeight: FontWeight.w400,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.of(context).push(
              noAnimationRoute(
                builder: (_) =>
                    TransactionHistoryPage(symbolFilter: item.symbol),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Text(
                  'İşlem geçmişini görüntüle',
                  style: TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Color(0xFF0284C7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Miktar',
                value: formatQuantity(item.quantity),
                icon: Icons.layers_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Canlı fiyat',
                value: quote == null
                    ? 'Bekleniyor'
                    : formatCurrency(quote.price, quote.currency),
                icon: Icons.show_chart_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Varlık Detayları',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              _AssetDetailRow(label: 'Kategori', value: item.type),
              const ThinDivider(),
              _AssetDetailRow(label: 'Para birimi', value: item.currency),
              const ThinDivider(),
              _AssetDetailRow(
                label: 'Alış tarihi',
                value: _formatAssetDate(item.createdAt),
                icon: Icons.calendar_today_outlined,
              ),
              const ThinDivider(),
              _AssetDetailRow(
                label: 'Birim maliyet',
                value: formatCurrency(item.averagePrice, item.currency),
              ),
              const ThinDivider(),
              _AssetDetailRow(
                label: 'Miktar',
                value: formatQuantity(item.quantity),
              ),
              const ThinDivider(),
              _AssetDetailRow(
                label: 'Toplam maliyet',
                value: formatCurrency(totalCost, item.currency),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _LiveMarketStatusCard(
          quote: quote,
          loading: loading,
          hasError: hasError,
          onRetry: _retry,
        ),
      ],
    );
  }
}

class _LiveMarketStatusCard extends StatelessWidget {
  final MarketQuote? quote;
  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;

  const _LiveMarketStatusCard({
    required this.quote,
    required this.loading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Canlı piyasa verisi alınıyor...',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasError || quote == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bu varlık için canlı fiyat henüz alınamadı.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w400,
                  fontSize: 12.5,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }

    final hasKnownStatus = quote!.marketStatus != MarketStatus.unknown;
    final statusColor = _marketStatusColor(quote!.marketStatus);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCDEED8)),
      ),
      child: Row(
        crossAxisAlignment: hasKnownStatus
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (hasKnownStatus) ...[
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasKnownStatus) ...[
                  Text(
                    _marketStatusLabel(quote!.marketStatus),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  'Son güncelleme: '
                  '${_formatUpdatedAt(quote!.updatedAt)} • '
                  '${quote!.exchange}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0284C7), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w400,
                    fontSize: 14.5,
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

class _AssetDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _AssetDetailRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
