String formatCurrency(double value, [String currency = 'TRY']) {
  final normalizedCurrency = currency.trim().isEmpty
      ? 'TRY'
      : currency.trim().toUpperCase();
  final formattedValue = formatTurkishDecimal(value);

  if (normalizedCurrency == 'TRY') {
    return '$formattedValue TL';
  }

  return '$formattedValue $normalizedCurrency';
}

String formatPercent(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2).replaceAll('.', ',')}%';
}

String formatQuantity(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(8);
  final parts = fixed.split('.');
  final integer = _groupTurkishThousands(parts.first);
  final decimal = parts.last.replaceFirst(RegExp(r'0+$'), '');
  final sign = isNegative ? '-' : '';

  if (decimal.isEmpty) return '$sign$integer';
  return '$sign$integer,$decimal';
}

String _groupTurkishThousands(String digits) {
  final reversed = digits.split('').reversed.toList();
  final grouped = <String>[];
  for (var index = 0; index < reversed.length; index++) {
    if (index > 0 && index % 3 == 0) grouped.add('.');
    grouped.add(reversed[index]);
  }
  return grouped.reversed.join();
}

String formatTurkishDecimal(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final decimal = parts.length > 1 ? parts.last : '00';

  final buffer = StringBuffer();

  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${isNegative ? '-' : ''}${buffer.toString()},$decimal';
}
