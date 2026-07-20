import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/price_alert.dart';
import '../../services/market/market_service.dart';
import '../../services/market/registry/asset_info.dart';
import '../../services/market/search/coingecko_coin_index.dart';
import '../../services/market/search/unified_asset_search_service.dart';
import '../../services/price_alert_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_back_button.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';

class PriceAlertPage extends StatefulWidget {
  const PriceAlertPage({super.key});

  @override
  State<PriceAlertPage> createState() => _PriceAlertPageState();
}

class _PriceAlertPageState extends State<PriceAlertPage> {
  List<PriceAlert> _alerts = const [];
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final alerts = await PriceAlertService.instance.load();
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    await PriceAlertService.instance.checkNow();
    await _reload();
    if (!mounted) return;
    setState(() => _checking = false);
  }

  Future<void> _addAlert() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PriceAlertEditor(),
    );
    if (created == true) await _reload();
  }

  Future<void> _toggle(PriceAlert alert, bool enabled) async {
    await PriceAlertService.instance.setEnabled(alert, enabled);
    await _reload();
  }

  Future<void> _delete(PriceAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alarm silinsin mi?'),
        content: Text('${alert.symbol} fiyat alarmı kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PriceAlertService.instance.delete(alert.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _alerts.where((alert) => alert.enabled).length;
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Fiyat Alarmları'),
        actions: [
          IconButton(
            tooltip: 'Fiyatları şimdi kontrol et',
            onPressed: _checking ? null : _checkNow,
            icon: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  _AlertSummary(
                    totalCount: _alerts.length,
                    activeCount: activeCount,
                    onAdd: _addAlert,
                  ),
                  const SizedBox(height: 18),
                  if (_alerts.isEmpty)
                    SurfaceCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            size: 40,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Henüz fiyat alarmın yok',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bir varlık seçip üst ve alt fiyat seviyeleri için ayrı alarmlar oluşturabilirsin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _addAlert,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('İlk Alarmı Ekle'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const Text(
                      'Alarmlarım',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._alerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          alert: alert,
                          onEnabledChanged: (value) => _toggle(alert, value),
                          onDelete: () => _delete(alert),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Alarmlar uygulama açıldığında ve fiyatlar yenilendiğinde kontrol edilir. Kesintisiz arka plan takibi ileride sunucu bildirimiyle etkinleştirilecek.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _alerts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addAlert,
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Alarm Ekle'),
            ),
      bottomNavigationBar: const MyFinBottomNav(selectedIndex: 2),
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({
    required this.totalCount,
    required this.activeCount,
    required this.onAdd,
  });

  final int totalCount;
  final int activeCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E8FF), Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fiyat Takibi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount aktif • $totalCount toplam alarm',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Alarm ekle',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  final PriceAlert alert;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final above = alert.direction == PriceAlertDirection.above;
    final color = above ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              above ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.symbol} • ${alert.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Text(
                  '${above ? 'Üstüne çıkarsa' : 'Altına inerse'}  '
                  '${formatCurrency(alert.targetPrice, alert.currency)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.repeat == PriceAlertRepeat.once
                      ? 'Tek seferlik'
                      : 'Her yeni eşik geçişinde',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: alert.enabled, onChanged: onEnabledChanged),
          IconButton(
            tooltip: 'Alarmı sil',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _PriceAlertEditor extends StatefulWidget {
  const _PriceAlertEditor();

  @override
  State<_PriceAlertEditor> createState() => _PriceAlertEditorState();
}

class _PriceAlertEditorState extends State<_PriceAlertEditor> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _targetController = TextEditingController();
  final _searchService = UnifiedAssetSearchService();
  Timer? _debounce;
  List<AssetInfo> _results = const [];
  AssetInfo? _asset;
  double? _livePrice;
  String _currency = 'TRY';
  bool _searching = false;
  bool _loadingPrice = false;
  bool _saving = false;
  String? _saveError;
  PriceAlertDirection _direction = PriceAlertDirection.above;
  PriceAlertRepeat _repeat = PriceAlertRepeat.once;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _targetController.dispose();
    _searchService.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      final results = await _searchService.search(query, limit: 15);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    });
  }

  Future<void> _selectAsset(AssetInfo asset) async {
    setState(() {
      _asset = asset;
      _searchController.text = '${asset.symbol} • ${asset.name}';
      _results = const [];
      _currency = asset.currency;
      _loadingPrice = true;
      _livePrice = null;
    });
    FocusScope.of(context).unfocus();
    if (asset.provider == 'CoinGecko' && asset.providerAssetId != null) {
      CoinGeckoCoinIndex.instance.rememberPreferred(
        symbol: asset.symbol,
        coinId: asset.providerAssetId!,
      );
    }
    try {
      final quote = await MarketService.instance.getQuote(
        asset.symbol,
        exchange: asset.exchange,
        forceRefresh: true,
      );
      if (!mounted || _asset != asset) return;
      setState(() {
        _livePrice = quote.price;
        _currency = quote.currency;
        _loadingPrice = false;
      });
    } catch (_) {
      if (!mounted || _asset != asset) return;
      setState(() => _loadingPrice = false);
    }
  }

  double _parsePrice(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _asset == null) {
      setState(() {
        _saveError = 'Varlık ve hedef fiyat alanlarını kontrol et.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      unawaited(
        PriceAlertService.instance.requestPermission().catchError((error) {
          debugPrint('NOTIFICATION PERMISSION ERROR: $error');
          return false;
        }),
      );
      final now = DateTime.now();
      await PriceAlertService.instance.save(
        PriceAlert(
          id: now.microsecondsSinceEpoch.toString(),
          symbol: _asset!.symbol,
          name: _asset!.name,
          exchange: _asset!.exchange,
          currency: _currency,
          targetPrice: _parsePrice(_targetController.text),
          direction: _direction,
          repeat: _repeat,
          enabled: true,
          createdAt: now,
          lastObservedPrice: _livePrice,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      debugPrint('PRICE ALERT SAVE ERROR: $error');
      setState(() {
        _saving = false;
        _saveError = 'Alarm kaydedilemedi: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Yeni Fiyat Alarmı',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Varlık ara',
                    hintText: 'Örn: ASELS, USD, Bitcoin...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _asset == null
                        ? null
                        : IconButton(
                            onPressed: () => setState(() {
                              _asset = null;
                              _searchController.clear();
                              _livePrice = null;
                            }),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: _onSearchChanged,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (_) =>
                      _asset == null ? 'Listeden bir varlık seç.' : null,
                ),
                if (_searching) const LinearProgressIndicator(minHeight: 2),
                if (_results.isNotEmpty)
                  Material(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      margin: const EdgeInsets.only(top: 6),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final asset = _results[index];
                          return ListTile(
                            title: Text(
                              asset.symbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            subtitle: Text('${asset.name} • ${asset.exchange}'),
                            trailing: Text(asset.currency),
                            onTap: () => _selectAsset(asset),
                          );
                        },
                      ),
                    ),
                  ),
                if (_asset != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _loadingPrice
                          ? 'Canlı fiyat alınıyor...'
                          : _livePrice == null
                          ? 'Canlı fiyat alınamadı; hedefi elle girebilirsin.'
                          : 'Güncel fiyat: ${formatCurrency(_livePrice!, _currency)}',
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SegmentedButton<PriceAlertDirection>(
                  segments: const [
                    ButtonSegment(
                      value: PriceAlertDirection.above,
                      label: Text('Üstüne çıkarsa'),
                      icon: Icon(Icons.trending_up_rounded),
                    ),
                    ButtonSegment(
                      value: PriceAlertDirection.below,
                      label: Text('Altına inerse'),
                      icon: Icon(Icons.trending_down_rounded),
                    ),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (value) {
                    setState(() => _direction = value.first);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.text,
                  inputFormatters: const [_AlertPriceInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Hedef fiyat ($_currency)',
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  validator: (value) => _parsePrice(value ?? '') <= 0
                      ? 'Geçerli bir hedef fiyat gir.'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<PriceAlertRepeat>(
                  initialValue: _repeat,
                  decoration: const InputDecoration(
                    labelText: 'Bildirim sıklığı',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PriceAlertRepeat.once,
                      child: Text('Bir kez bildir ve alarmı kapat'),
                    ),
                    DropdownMenuItem(
                      value: PriceAlertRepeat.repeating,
                      child: Text('Her yeni eşik geçişinde bildir'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _repeat = value);
                  },
                ),
                const SizedBox(height: 18),
                if (_saveError != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _saveError!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.notifications_active_rounded),
                    label: const Text('Alarmı Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertPriceInputFormatter extends TextInputFormatter {
  const _AlertPriceInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');
    final separator = lastComma > lastDot ? lastComma : lastDot;
    var integerPart = separator < 0 ? text : text.substring(0, separator);
    var decimalPart = separator < 0 ? '' : text.substring(separator + 1);
    integerPart = integerPart.replaceAll(RegExp(r'[,.]'), '');
    decimalPart = decimalPart.replaceAll(RegExp(r'[,.]'), '');
    if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);
    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final groups = <String>[];
    for (var end = integerPart.length; end > 0; end -= 3) {
      groups.insert(0, integerPart.substring((end - 3).clamp(0, end), end));
    }
    text = groups.join('.');
    if (separator >= 0) text = '$text,$decimalPart';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
