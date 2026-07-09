import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/market_asset_catalog_service.dart';
import '../../services/portfolio_rebuild_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';

class TransactionEntryPage extends StatefulWidget {
  final String? transactionId;
  final Map<String, dynamic>? transactionData;
  final String? formattedDate;

  const TransactionEntryPage({
    super.key,
    this.transactionId,
    this.transactionData,
    this.formattedDate,
  });

  bool get isEdit => transactionId != null && transactionData != null;

  @override
  State<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _TransactionEntryPageState extends State<TransactionEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _assetSearchController = TextEditingController();
final _catalogService = const MarketAssetCatalogService();

List<MarketAsset> _suggestions = const [];
bool _isSearching = false;

String _assetName = '';
String _assetType = 'Hisse';
  final _noteController = TextEditingController();

  String _transactionType = 'Alış';
  String _currency = 'TRY';
  DateTime _transactionDate = DateTime.now();
  @override

void initState() {

  super.initState();

  final data = widget.transactionData;

  if (data == null) return;

  final symbol = (data['symbol'] ?? '').toString();

  final assetName = (data['assetName'] ?? '').toString();

  final type = (data['type'] ?? 'Alış').toString();

  final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;

  final price = (data['price'] as num?)?.toDouble() ?? 0;

  final currency = (data['currency'] ?? 'TRY').toString();

  final note = (data['note'] ?? '').toString();

  _transactionType = type;

  _currency = currency;

  _assetName = assetName;
_assetType = (data['assetType'] ?? _assetType).toString();
  _symbolController.text = symbol;

  _assetSearchController.text =

      assetName.isEmpty || assetName == symbol ? symbol : '$symbol • $assetName';

  _quantityController.text = formatQuantity(quantity);

  _priceController.text = price.toString().replaceAll('.', ',');

  _noteController.text = note;

  final rawDate = data['transactionDate'];

  if (rawDate is Timestamp) {

    _transactionDate = rawDate.toDate();

  }

}
  @override
void dispose() {
  _assetSearchController.dispose(); 

  _symbolController.dispose();
  _quantityController.dispose();
  _priceController.dispose();
  _noteController.dispose();

  super.dispose();
}
Future<void> _searchAssets(String value) async {
  final query = value.trim();

  if (query.length < 2) {
    setState(() => _suggestions = const []);
    return;
  }

  setState(() => _isSearching = true);

  final results = await _catalogService.search(
  query: query,
);

  if (!mounted) return;

  setState(() {
    _suggestions = results;
    _isSearching = false;
  });
}

void _selectAsset(MarketAsset asset) {
  setState(() {
    _symbolController.text = asset.symbol;
    _assetSearchController.text = '${asset.symbol} • ${asset.name}';
    _assetName = asset.name;
    _assetType = asset.type;
    _currency = asset.currency;
    _suggestions = const [];
  });

  FocusScope.of(context).unfocus();
}
  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked == null) return;

    setState(() => _transactionDate = picked);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final quantity = _parseDouble(_quantityController.text);
    final price = _parseDouble(_priceController.text);
final resolvedAssetType = _resolveAssetType(symbol, _assetType);
final resolvedAssetName =
    _assetName.trim().isEmpty ? _resolveAssetName(symbol) : _assetName.trim();
    try {
      final items = await PortfolioRepository.instance.watchPortfolio().first;
      if (widget.isEdit) {
  await PortfolioRepository.instance.updateTransaction(
  widget.transactionId!,
  {
    'symbol': symbol,
    'assetName': _assetName.isEmpty ? symbol : _assetName,
    'assetType': _assetType,
    'type': _transactionType,
    'quantity': quantity,
    'price': price,
    'total': quantity * price,
    'currency': _currency,
    'transactionDate': Timestamp.fromDate(_transactionDate),
    'note': _noteController.text.trim(),
  },
);

await PortfolioRebuildService().rebuildFromTransactions();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('İşlem güncellendi.')),
  );

  Navigator.of(context).pop();
  Navigator.of(context).pop();
  return;
}
      PortfolioItem? existingItem;
      for (final item in items) {
       final itemSymbol = item.symbol.trim().toUpperCase();
final itemName = item.name.trim().toUpperCase();

if (itemSymbol == symbol || itemName == symbol || itemName == _assetName.trim().toUpperCase()) {
  existingItem = item;
  break;
} 
      }

      if (_transactionType == 'Alış') {
        if (existingItem == null) {
          await PortfolioRepository.instance.addPortfolioItem(
         PortfolioItem(
  id: '',
  name: resolvedAssetName,
  symbol: symbol,
  type: resolvedAssetType,  

  quantity: quantity,

  averagePrice: price,

  currency: _currency,

),
          );
        } else {
          final oldTotalCost = existingItem.totalCost;
          final newTotalCost = quantity * price;
          final newQuantity = existingItem.quantity + quantity;
          final newAveragePrice = (oldTotalCost + newTotalCost) / newQuantity;

          await PortfolioRepository.instance.updatePortfolioItem(
          existingItem.copyWith(
  quantity: newQuantity,
  averagePrice: newAveragePrice,
  currency: _currency,
  type: resolvedAssetType,
),  
          );
        }
      } else {
        if (existingItem == null) {
          throw Exception('Bu varlık portföyde bulunamadı.');
        }

        if (quantity > existingItem.quantity) {
          throw Exception('Satış adedi portföydeki adetten büyük olamaz.');
        }

        final remainingQuantity = existingItem.quantity - quantity;

        if (remainingQuantity <= 0) {
          await PortfolioRepository.instance.deletePortfolioItem(existingItem.id);
        } else {
          await PortfolioRepository.instance.updatePortfolioItem(
            existingItem.copyWith(quantity: remainingQuantity),
          );
        }
      }

      await PortfolioRepository.instance.addTransaction({
        'symbol': symbol,
        'assetName': resolvedAssetName,
'assetType': resolvedAssetType,
        'type': _transactionType,
        'quantity': quantity,
        'price': price,
        'total': quantity * price,
        'currency': _currency,
        'transactionDate': Timestamp.fromDate(_transactionDate),
        'note': _noteController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$symbol için $_transactionType işlemi kaydedildi.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('TRANSACTION ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem kaydedilemedi: $error')),
      );
    }
  }
String _resolveAssetType(String symbol, String currentType) {
  switch (symbol) {
    case 'USD':
    case 'EUR':
    case 'GBP':
    case 'CHF':
      return 'Döviz';
    case 'XAU':
    case 'ALTIN':
    case 'GAU':
    case 'XAUUSD':
      return 'Altın';
    case 'BTC':
    case 'ETH':
    case 'SOL':
      return 'Kripto';
    default:
      return currentType.trim().isEmpty ? 'Hisse' : currentType;
  }
}

String _resolveAssetName(String symbol) {
  switch (symbol) {
    case 'USD':
      return 'Amerikan Doları';
    case 'EUR':
      return 'Euro';
    case 'GBP':
      return 'İngiliz Sterlini';
    case 'CHF':
      return 'İsviçre Frangı';
    case 'XAU':
    case 'ALTIN':
    case 'GAU':
      return 'Gram Altın';
    case 'BTC':
      return 'Bitcoin';
    case 'ETH':
      return 'Ethereum';
    case 'SOL':
      return 'Solana';
    default:
      return symbol;
  }
}
  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bu alan zorunlu.';
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bu alan zorunlu.';
    final parsed = _parseDouble(value);
    if (parsed <= 0) return 'Geçerli bir sayı gir.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İşlem'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const SectionTitle(title: 'İşlem'),
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portföyüne alış veya satış işlemi ekle. İşlem geçmişin otomatik güncellenir.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Alış', label: Text('Alış')),
                        ButtonSegment(value: 'Satış', label: Text('Satış')),
                      ],
                      selected: {_transactionType},
                      onSelectionChanged: (value) {
                        setState(() => _transactionType = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
  controller: _assetSearchController,
  decoration: const InputDecoration(
    labelText: 'Varlık Ara',
    hintText: 'ASELS, THYAO, AAPL, BTC...',
    prefixIcon: Icon(Icons.search_rounded),
    border: OutlineInputBorder(),
  ),
  validator: _requiredText,
  onChanged: _searchAssets,
),
const SizedBox(height: 8),
if (_isSearching) const LinearProgressIndicator(),
if (_suggestions.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: _SuggestionPanel(
      suggestions: _suggestions,
      onSelected: _selectAsset,
    ),
  ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Adet / Miktar',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Birim fiyat',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Para birimi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'İşlem tarihi',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        child: Text(_formatDate(_transactionDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Not',
                        hintText: 'Opsiyonel',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saveTransaction,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
  widget.isEdit
      ? 'Değişiklikleri Kaydet'
      : 'İşlemi Kaydet',
),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(

        selectedIndex: 2,

      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  final List<MarketAsset> suggestions;
  final ValueChanged<MarketAsset> onSelected;

  const _SuggestionPanel({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: suggestions.map((item) {
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF008DB9).withValues(alpha: .12),
              child: Text(
                item.symbol.characters.first,
                style: const TextStyle(
                  color: Color(0xFF008DB9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              '${item.symbol} • ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${item.market} • ${item.currency}'),
            onTap: () => onSelected(item),
          );
        }).toList(),
      ),
    );
  }
}
