import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/utils/turkish_currency_input_formatter.dart';

void main() {
  const formatter = TurkishCurrencyInputFormatter();

  TextEditingValue format(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  test('Türkçe virgüllü küsurat girişini korur', () {
    expect(format('815', '815,').text, '815,');
    expect(format('815,1', '815,13').text, '815,13');
  });

  test('iOS nokta tuşunu ondalık virgüle dönüştürür', () {
    expect(format('815', '815.').text, '815,');
    expect(format('815,1', '815,13').text, '815,13');
  });

  test('binlik ayıracı eklemeye devam eder', () {
    expect(format('81.513', '81.5134').text, '815.134');
  });
}
