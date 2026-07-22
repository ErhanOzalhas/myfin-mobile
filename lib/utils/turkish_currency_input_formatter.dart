import 'package:flutter/services.dart';

/// Para girişini yazım sırasında Türkçe biçime dönüştürür.
/// Örnek: 295798,5 -> 295.798,5
class TurkishCurrencyInputFormatter extends TextInputFormatter {
  const TurkishCurrencyInputFormatter({this.decimalDigits = 2});

  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final normalized = newValue.text.replaceAll(RegExp(r'[^0-9,.]'), '');
    var decimalIndex = normalized.lastIndexOf(',');

    // iOS sayısal klavyesi cihaz diline göre ondalık tuşunu nokta olarak
    // gönderebilir. Kullanıcının yeni yazdığı noktayı binlik ayıracı değil,
    // ondalık ayıracı kabul edip ekranda Türkçe virgüle dönüştürüyoruz.
    if (decimalIndex < 0) {
      final oldText = oldValue.text;
      final insertedDecimalPoint =
          normalized.endsWith('.') ||
          (!oldText.contains('.') && normalized.contains('.'));
      if (insertedDecimalPoint) decimalIndex = normalized.lastIndexOf('.');
    }

    final integerSource = decimalIndex < 0
        ? normalized
        : normalized.substring(0, decimalIndex);
    final decimalSource = decimalIndex < 0
        ? ''
        : normalized.substring(decimalIndex + 1);

    var integerDigits = integerSource.replaceAll(RegExp(r'[^0-9]'), '');
    if (integerDigits.isEmpty) integerDigits = '0';
    integerDigits = integerDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    var decimalDigitsText = decimalSource.replaceAll(RegExp(r'[^0-9]'), '');
    if (decimalDigitsText.length > decimalDigits) {
      decimalDigitsText = decimalDigitsText.substring(0, decimalDigits);
    }

    final reversed = integerDigits.split('').reversed.toList();
    final grouped = <String>[];
    for (var index = 0; index < reversed.length; index++) {
      if (index > 0 && index % 3 == 0) grouped.add('.');
      grouped.add(reversed[index]);
    }

    final integerText = grouped.reversed.join();
    final formatted = decimalIndex < 0
        ? integerText
        : '$integerText,$decimalDigitsText';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
