import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/market_asset_catalog_service.dart';
import '../../services/portfolio_rebuild_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';

import 'transaction_history_page.dart';

class TransactionEntryPage extends StatefulWidget {
  final bool showBottomNav;
  final String? transactionId;
  final Map<String, dynamic>? transactionData;
  final String? formattedDate;

  const TransactionEntryPage({
    super.key,
    this.showBottomNav = true,
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
  final _noteController = TextEditingController();
  final _quantityFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _catalogService = const MarketAssetCatalogService();

  List<MarketAsset> _suggestions = const [];
  bool _isSearching = false;
  bool _isSaving = false;
  bool _isSaved = false;

  String _assetName = '';
  String _assetType = 'Hisse';
  String _transactionType = 'Alış';
  String _currency = 'TRY';
  DateTime _transactionDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _assetSearchController.addListener(_handleFormChanged);
    _quantityController.addListener(_handleFormChanged);
    _priceController.addListener(_handleFormChanged);
    _quantityFocusNode.addListener(_handleQuantityFocusChanged);
    _priceFocusNode.addListener(_handlePriceFocusChanged);

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
    _assetSearchController.text = assetName.isEmpty || assetName == symbol
        ? symbol
        : '$symbol • $assetName';
    _quantityController.text = formatQuantity(quantity);
    _priceController.text = _formatPriceInput(price);
    _noteController.text = note;

    final rawDate = data['transactionDate'];
    if (rawDate is Timestamp) {
      _transactionDate = rawDate.toDate();
    }
  }

  @override
  void dispose() {
    _assetSearchController.removeListener(_handleFormChanged);
    _quantityController.removeListener(_handleFormChanged);
    _priceController.removeListener(_handleFormChanged);
    _quantityFocusNode.removeListener(_handleQuantityFocusChanged);
    _priceFocusNode.removeListener(_handlePriceFocusChanged);
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _assetSearchController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleQuantityFocusChanged() {
    if (_quantityFocusNode.hasFocus) return;
    _quantityController.text = _formatQuantityText(_quantityController.text);
  }

  void _handlePriceFocusChanged() {
    if (_priceFocusNode.hasFocus) return;
    _priceController.text = _formatCurrencyText(_priceController.text);
  }

  bool get _isFormReady {
    return _assetSearchController.text.trim().isNotEmpty &&
        _parseDouble(_quantityController.text) > 0 &&
        _parseDouble(_priceController.text) > 0;
  }

  void _resetForm() {
    _symbolController.clear();
    _quantityController.clear();
    _priceController.clear();
    _assetSearchController.clear();
    _noteController.clear();

    setState(() {
      _suggestions = const [];
      _isSearching = false;
      _isSaving = false;
      _isSaved = false;
      _assetName = '';
      _assetType = 'Hisse';
      _transactionType = 'Alış';
      _currency = 'TRY';
      _transactionDate = DateTime.now();
    });
  }

  Future<void> _goBack() async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    try {
      await navigator.pushNamedAndRemoveUntil('/', (route) => false);
    } catch (_) {
      if (!mounted) return;
      navigator.popUntil((route) => route.isFirst);
    }
  }

  String _formatPriceInput(num value) {
    final raw = value.toStringAsFixed(2).replaceAll('.', ',');
    return _TurkishDecimalTextInputFormatter(
      decimalDigits: 2,
      dotAsDecimal: false,
    ).formatString(raw);
  }

  String _formatQuantityText(String value) {
    final formatted = const _TurkishDecimalTextInputFormatter(
      decimalDigits: 8,
      dotAsDecimal: true,
      trimTrailingZeroDecimals: true,
    ).formatString(value);

    if (formatted.isEmpty) return '';
    final separatorIndex = formatted.indexOf(',');

    if (separatorIndex == -1) return '$formatted,00';

    final integer = formatted.substring(0, separatorIndex);
    final decimal = formatted.substring(separatorIndex + 1);
    if (decimal.isEmpty) return '$integer,00';

    if (decimal.length == 1) return '$integer,${decimal}0';
    return '$integer,$decimal';
  }

  String _formatCurrencyText(String value) {
    final formatted = const _TurkishDecimalTextInputFormatter(
      decimalDigits: 2,
      dotAsDecimal: true,
    ).formatString(value);

    if (formatted.isEmpty) return '';
    final separatorIndex = formatted.indexOf(',');

    if (separatorIndex == -1) return '$formatted,00';

    final integer = formatted.substring(0, separatorIndex);
    final decimal = formatted.substring(separatorIndex + 1);
    final normalizedDecimal = decimal.padRight(2, '0');
    return '$integer,${normalizedDecimal.substring(0, 2)}';
  }

  Future<void> _showSuccessAndClose({required bool popTwice}) async {
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSaved = true;
    });

    await Future.delayed(const Duration(milliseconds: 320));

    if (!mounted) return;
    if (!widget.isEdit) {
      _resetForm();
    }
    Navigator.of(context).pop();
    if (popTwice && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _searchAssets(String value) async {
    final query = value.trim();

    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }

    setState(() => _isSearching = true);

    final results = await _catalogService.search(query: query);

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
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
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
    if (_isSaving || !_isFormReady) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _isSaved = false;
    });

    final symbol = _symbolController.text.trim().toUpperCase();
    final quantity = _parseDouble(_quantityController.text);
    final price = _parseDouble(_priceController.text);
    final resolvedAssetType = _resolveAssetType(symbol, _assetType);
    final resolvedAssetName = _assetName.trim().isEmpty
        ? _resolveAssetName(symbol)
        : _assetName.trim();

    try {
      final items = await PortfolioRepository.instance.watchPortfolio().first;

      if (widget.isEdit) {
        await PortfolioRepository.instance.updateTransaction(
          widget.transactionId!,
          {
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
          },
        );

        await PortfolioRebuildService().rebuildFromTransactions();

        if (!mounted) return;

        await _showSuccessAndClose(popTwice: true);
        return;
      }

      PortfolioItem? existingItem;
      for (final item in items) {
        final itemSymbol = item.symbol.trim().toUpperCase();
        final itemName = item.name.trim().toUpperCase();
        final assetName = _assetName.trim().toUpperCase();

        if (itemSymbol == symbol || itemName == symbol || itemName == assetName) {
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

      await _showSuccessAndClose(popTwice: false);
    } catch (error, stackTrace) {
      debugPrint('TRANSACTION ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isSaved = false;
      });

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

  void _openTransactionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TransactionHistoryPage(showBottomNav: false),
      ),
    );
  }

  static const Color _brandBlue = Color(0xFF075DA8);
  static const Color _softBlue = Color(0xFFEAF4FF);
  static const Color _borderColor = Color(0xFFD7DEE8);

  InputDecoration _fieldDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      suffixIconConstraints: const BoxConstraints(minWidth: 48),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 24, color: const Color(0xFF344052)),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 22, color: const Color(0xFF344052)),
      labelStyle: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF7B8494),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brandBlue, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  ButtonStyle _segmentStyle(BuildContext context) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(0, 46)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        return BorderSide(
          color: states.contains(WidgetState.selected)
              ? _brandBlue
              : const Color(0xFF6B7280),
          width: 1.2,
        );
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? _brandBlue
            : const Color(0xFF111827);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? _softBlue
            : Colors.white;
      }),
    );
  }

  Widget _sectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: _softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: _brandBlue,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'İşlem',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Alış veya satış işlemini ekle. Portföy ve işlem geçmişi otomatik güncellenir.',
          style: TextStyle(
            color: Color(0xFF596273),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _isFormReady && !_isSaving;
    final label = _isSaving
        ? 'Kaydediliyor...'
        : _isSaved
            ? 'İşlem kaydedildi'
            : widget.isEdit
                ? 'Değişiklikleri Kaydet'
                : 'Yeni İşlemi Kaydet';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isEnabled ? _saveTransaction : null,
        icon: _isSaving
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _isSaved ? Icons.check_circle_rounded : Icons.check_rounded,
                size: 22,
              ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.1,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _isSaved ? const Color(0xFF16A34A) : _brandBlue,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBack,
        ),
        title: Text(widget.isEdit ? 'İşlemi Düzenle' : 'Yeni İşlem'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: _openTransactionHistory,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Geçmiş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandBlue,
                backgroundColor: _softBlue,
                side: const BorderSide(color: _brandBlue, width: 1.2),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 8, 16, keyboardInset > 0 ? 92 : 20),
            children: [
              _sectionHeader(),
              const SizedBox(height: 18),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Alış',
                            label: Text('Alış'),
                            icon: Icon(Icons.check_rounded),
                          ),
                          ButtonSegment(value: 'Satış', label: Text('Satış')),
                        ],
                        style: _segmentStyle(context),
                        selected: {_transactionType},
                        onSelectionChanged: (value) {
                          setState(() => _transactionType = value.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _assetSearchController,
                      decoration: _fieldDecoration(
                        labelText: 'Varlık ara',
                        hintText: 'Örn: ASELS, USD, Altın...',
                        prefixIcon: Icons.search_rounded,
                      ),
                      validator: _requiredText,
                      onChanged: _searchAssets,
                    ),
                    const SizedBox(height: 8),
                    if (_isSearching) const LinearProgressIndicator(minHeight: 2),
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
                      focusNode: _quantityFocusNode,
                      decoration: _fieldDecoration(
                        labelText: 'Adet / Miktar',
                        hintText: 'Örn: 0,34567',
                        suffixIcon: Icons.trending_up_rounded,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: const [
  _TurkishDecimalTextInputFormatter(
    decimalDigits: 2,
    dotAsDecimal: true,
  ),
],
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        _quantityController.text =
                            _formatQuantityText(_quantityController.text);
                        FocusScope.of(context).nextFocus();
                      },
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      decoration: _fieldDecoration(
                        labelText: 'Birim fiyat (TL)',
                        hintText: 'Örn: 123,45',
                        suffixIcon: Icons.currency_lira_rounded,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: const [
                        _TurkishDecimalTextInputFormatter(
                          decimalDigits: 2,
                          dotAsDecimal: true,
                        ),
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        _priceController.text =
                            _formatCurrencyText(_priceController.text);
                        FocusScope.of(context).unfocus();
                      },
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: _fieldDecoration(labelText: 'Para birimi'),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: _fieldDecoration(
                                labelText: 'İşlem tarihi',
                                suffixIcon: Icons.calendar_today_rounded,
                              ),
                              child: Text(
                                _formatDate(_transactionDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      decoration: _fieldDecoration(
                        labelText: 'Not (isteğe bağlı)',
                        hintText: 'Not ekleyin...',
                      ),
                      minLines: 2,
                      maxLines: 2,
                      maxLength: 200,
                      buildCounter: (
                        BuildContext context, {
                        required int currentLength,
                        required bool isFocused,
                        required int? maxLength,
                      }) {
                        return Text(
                          '$currentLength/${maxLength ?? 200}',
                          style: const TextStyle(
                            color: Color(0xFF596273),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: _buildSaveButton(),
              ),
              if (widget.showBottomNav && keyboardInset == 0)
                const MyFinBottomNav(selectedIndex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurkishDecimalTextInputFormatter extends TextInputFormatter {
  final int decimalDigits;
  final bool dotAsDecimal;
  final bool trimTrailingZeroDecimals;

  const _TurkishDecimalTextInputFormatter({
    this.decimalDigits = 2,
    this.dotAsDecimal = true,
    this.trimTrailingZeroDecimals = false,
  });

  String formatString(String value) {
    return _format(value);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _format(newValue.text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    final sanitized = StringBuffer();
    for (final codeUnit in text.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      if (isDigit || char == ',' || char == '.' || char == '/') {
        sanitized.write(char == '/' ? ',' : char);
      }
    }

    final raw = sanitized.toString();
    if (raw.isEmpty) return '';

    final separatorIndex = _decimalSeparatorIndex(raw);
    String integerSource;
    String decimalSource = '';

    if (separatorIndex == -1 || decimalDigits == 0) {
      integerSource = raw;
    } else {
      integerSource = raw.substring(0, separatorIndex);
      decimalSource = raw.substring(separatorIndex + 1);
    }

    var integerDigits = _digitsOnly(integerSource);
    if (integerDigits.isEmpty) integerDigits = '0';
    integerDigits = integerDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    var decimalText = _digitsOnly(decimalSource);
    if (decimalText.length > decimalDigits) {
      decimalText = decimalText.substring(0, decimalDigits);
    }

    if (trimTrailingZeroDecimals && decimalText.length > 2) {
      decimalText = decimalText.replaceFirst(RegExp(r'0+$'), '');
      if (decimalText.length < 2) {
        decimalText = decimalText.padRight(2, '0');
      }
    }

    final groupedInteger = _groupThousands(integerDigits);

    if (separatorIndex == -1 || decimalDigits == 0) return groupedInteger;
    return '$groupedInteger,$decimalText';
  }

  int _decimalSeparatorIndex(String raw) {
    final commaIndex = raw.lastIndexOf(',');
    final slashNormalizedCommaIndex = commaIndex;
    if (slashNormalizedCommaIndex != -1) return slashNormalizedCommaIndex;

    if (!dotAsDecimal) return -1;

    final dotMatches = RegExp(r'\.').allMatches(raw).toList();
    if (dotMatches.length != 1) return -1;

    final dotIndex = dotMatches.first.start;
    final digitsBeforeDot = _digitsOnly(raw.substring(0, dotIndex)).length;
    final digitsAfterDot = _digitsOnly(raw.substring(dotIndex + 1)).length;

    if (digitsAfterDot == 0) return dotIndex;

    // Mac / external keyboards often send '.' for decimals.
    // Treat a single dot as decimal when it clearly looks like decimal typing.
    if (digitsBeforeDot <= 2 && digitsAfterDot <= decimalDigits) {
      return dotIndex;
    }

    if (digitsAfterDot <= decimalDigits && digitsAfterDot != 3) {
      return dotIndex;
    }

    return -1;
  }

  String _digitsOnly(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  String _groupThousands(String digits) {
    final reversed = digits.split('').reversed.toList();
    final grouped = <String>[];

    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) grouped.add('.');
      grouped.add(reversed[i]);
    }

    return grouped.reversed.join();
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.map((item) {
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              tileColor: Colors.white,
              leading: CircleAvatar(
                radius: 16,
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
      ),
    );
  }
}
