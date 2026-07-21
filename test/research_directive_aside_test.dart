import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/services/ai/research_directive.dart';

void main() {
  test('research directive instructs to add an ASIDE note', () {
    const question = 'Altın geçmişte kriz dönemlerinde nasıl davranmış?';
    final directive = buildResearchDirective(question);

    expect(directive, contains('ASIDE'));
    expect(directive, contains('veri kapsamına dayandığın'));
    expect(directive, contains('güvenilir olduğu'));
  });
}
