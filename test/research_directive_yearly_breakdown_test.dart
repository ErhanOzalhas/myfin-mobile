import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/services/ai/research_directive.dart';

void main() {
  test('yearly breakdown directive is added for year-by-year requests', () {
    const question = 'Altın için yıl bazında yıl yıl bildirir misin?';
    final directive = buildResearchDirective(question);

    expect(directive, contains('yıl bazında')); 
    expect(directive, contains('"2020:')); 
    expect(directive, contains('yıllık liste')); 
  });
}
