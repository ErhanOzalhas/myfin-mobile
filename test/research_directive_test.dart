import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/services/ai/research_directive.dart';

void main() {
  test('builds web search directive for long-term history questions', () {
    const question = 'Dolar kuru son 10 yılda nasıl gelişti?';
    final directive = buildResearchDirective(question);

    expect(directive, contains('=== ENABLE_WEB_SEARCH ==='));
    expect(directive, contains('son 10 yıla kadar')); 
    expect(directive, contains('geçmiş raporlar'));
  });

  test('builds web search directive for crisis-related history questions', () {
    const question = 'Altın geçmişte kriz dönemlerinde nasıl davranmış?';
    final directive = buildResearchDirective(question);

    expect(directive, contains('=== ENABLE_WEB_SEARCH ==='));
    expect(directive, contains('son 15 yıla kadar'));
  });

  test('returns empty directive for unrelated short questions', () {
    const question = 'Bugün portföyümdeki risk nedir?';
    final directive = buildResearchDirective(question);

    expect(directive, isEmpty);
  });
}
