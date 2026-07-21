import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/services/ai/research_directive.dart';

void main() {
  test('explicit 10-year USD/TRY trend question triggers 10-year scope', () {
    const question = 'USD/TRY için son 10 yıllık trend nedir?';
    final directive = buildResearchDirective(question);

    expect(directive, contains('son 10 yıla kadar'));
    expect(directive, contains('ASIDE'));
  });

  test('generic portfolio question without historical intent returns empty directive', () {
    const question = 'Portföyümdeki riski değerlendirir misin?';
    final directive = buildResearchDirective(question);

    expect(directive, isEmpty);
  });
}
