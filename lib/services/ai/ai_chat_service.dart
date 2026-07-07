import 'package:myfin_mobile/services/ai/ai_orchestrator.dart';
import 'package:myfin_mobile/services/ai/ai_service.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';
import 'package:myfin_mobile/services/ai/ai_context_builder.dart';
/// Compatibility layer for the existing AI chat screen.
///
/// The UI can keep using [AIChatService], but the actual AI flow now goes
/// through [AIOrchestrator]. This prevents the old provider stack from coming
/// back and keeps the screen aligned with the new Sprint 7 architecture.
class AIChatService {
  AIChatService({
    AIProvider? provider,
    AIService? service,
    AIOrchestrator? orchestrator,
  }) : _orchestrator = orchestrator ??
            AIOrchestrator(
              service: service,
              provider: provider,
            );

  final AIOrchestrator _orchestrator;

  Future<String> ask({
  required PortfolioAnalysis analysis,
  required String question,
}) async {
  final String context = AIContextBuilder().build(analysis);

  final String prompt = '''
$context

=== USER QUESTION ===

$question
''';

  final AIResponse response = await _orchestrator.ask(
    message: prompt,
    userContext: const UserFinancialContext(
      name: 'MyFin User',
      baseCurrency: 'TRY',
    ),
  );

  final String answer = response.content.trim();
  if (answer.isEmpty) {
    return 'Şu anda net bir yanıt üretemedim. Sorunu biraz daha açık yazar mısın?';
  }

  return answer;
}

  void resetConversation() {
    _orchestrator.resetConversation();
  }

  void dispose() {
    _orchestrator.dispose();
  }
}
