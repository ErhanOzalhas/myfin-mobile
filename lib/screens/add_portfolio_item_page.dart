import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/portfolio_item.dart';
import '../repositories/portfolio_repository.dart';
import '../services/market_asset_catalog_service.dart';

class AddPortfolioItemPage extends StatefulWidget {
  const AddPortfolioItemPage({super.key});

  @override
  State<AddPortfolioItemPage> createState() => _AddPortfolioItemPageState();
}

class _AddPortfolioItemPageState extends State<AddPortfolioItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _averagePriceController = TextEditingController();

  String _type = 'Hisse';
  String _currency = 'TRY';
  bool _isSaving = false;
  final _catalogService = const MarketAssetCatalogService();
  List<MarketAsset> _suggestions = const [];
  bool _isSearching = false;

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

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _averagePriceController.dispose();
    super.dispose();
  }

  void _selectSuggestion(MarketAsset suggestion) {
    setState(() {
      _symbolController.text = suggestion.symbol;
      _nameController.text = suggestion.name;
      _type = suggestion.type;
      _currency = suggestion.currency;
      _suggestions = const [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final item = PortfolioItem(
        id: '',
        name: _nameController.text.trim(),
        symbol: _symbolController.text.trim().toUpperCase(),
        type: _type,
        quantity: _parseDouble(_quantityController.text),
        averagePrice: _parseDouble(_averagePriceController.text),
        currency: _currency,
      );

      await PortfolioRepository.instance.addPortfolioItem(item);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Varlık kaydedilirken bir hata oluştu.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Geçerli bir sayı gir';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Varlık Ekle'),
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _FieldCard(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Hisse', child: Text('Hisse')),
                    DropdownMenuItem(value: 'Fon', child: Text('Fon')),
                    DropdownMenuItem(value: 'Altın', child: Text('Altın')),
                    DropdownMenuItem(value: 'Kripto', child: Text('Kripto')),
                    DropdownMenuItem(value: 'Döviz', child: Text('Döviz')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                        _suggestions = const [];
                        _symbolController.clear();
                        _nameController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _FieldCard(
                child: TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(
                    labelText: 'Varlık ara',
                    hintText: '2-3 harf yaz: ASE, USD, ALT, AAPL...',
                    border: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: _requiredText,
                  onChanged: _searchAssets,
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 8),
                const _FieldCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Varlık kataloğu aranıyor...'),
                      ],
                    ),
                  ),
                ),
              ] else if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SuggestionPanel(
                  suggestions: suggestions,
                  onSelected: _selectSuggestion,
                ),
              ],
              const SizedBox(height: 12),
              _FieldCard(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Seçilen varlık',
                    hintText: 'Listeden seçince otomatik dolar',
                    border: InputBorder.none,
                  ),
                  readOnly: true,
                  validator: _requiredText,
                ),
              ),
              const SizedBox(height: 12),
              _FieldCard(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Adet / Miktar',
                    hintText: 'Örn: 10',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(height: 12),
              _FieldCard(
                child: TextFormField(
                  controller: _averagePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Alış birim fiyatı',
                    hintText: 'Örn: 125,50',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(height: 12),
              _FieldCard(
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Para birimi',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _currency = value);
                  },
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Varlık Ekle'),
                ),
              ),
            ],
          ),
        ),
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
            color: Colors.black.withOpacity(.045),
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
              backgroundColor: const Color(0xFF008DB9).withOpacity(.12),
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

class _FieldCard extends StatelessWidget {
  final Widget child;

  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
