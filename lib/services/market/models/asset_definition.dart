import 'asset_category.dart';

class AssetDefinition {
  final String symbol;
  final String name;
  final AssetCategory category;
  final String exchange;
  final String currency;
  final List<String> aliases;
  final bool isLocalTurkishGold;

  const AssetDefinition({
    required this.symbol,
    required this.name,
    required this.category,
    required this.exchange,
    required this.currency,
    this.aliases = const [],
    this.isLocalTurkishGold = false,
  });

  bool matches(String query) {
    final normalized = _normalize(query);

    if (_normalize(symbol) == normalized ||
        _normalize(name) == normalized) {
      return true;
    }

    return aliases.any(
      (alias) => _normalize(alias) == normalized,
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'[\s_\-/.]'), '');
  }
}
