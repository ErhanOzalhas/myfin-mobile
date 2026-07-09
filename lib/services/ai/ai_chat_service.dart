import 'package:myfin_mobile/services/ai/ai_context_builder.dart';
import 'package:myfin_mobile/services/ai/ai_orchestrator.dart';
import 'package:myfin_mobile/services/ai/ai_service.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';

/// Compatibility layer for the existing AI chat screen.
///
/// The UI can keep using [AIChatService], but the actual AI flow goes through
/// [AIOrchestrator]. It also injects the current portfolio analysis into every
/// request so MyFin AI answers with live portfolio context.
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
  final AIContextBuilder _contextBuilder = const AIContextBuilder();

  Future<String> ask({
    required PortfolioAnalysis analysis,
    required String question,
  }) async {
    final AIResponse response = await _orchestrator.ask(
      message: _buildMessage(analysis: analysis, question: question),
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

  Stream<String> askStream({
    required PortfolioAnalysis analysis,
    required String question,
  }) {
    return _orchestrator.askStream(
      message: _buildMessage(analysis: analysis, question: question),
      userContext: const UserFinancialContext(
        name: 'MyFin User',
        baseCurrency: 'TRY',
      ),
    );
  }

  String _buildMessage({
    required PortfolioAnalysis analysis,
    required String question,
  }) {
    final String context = _contextBuilder.build(analysis).trim();

    return '''
$context

=== USER QUESTION ===
$question
'''
        .trim();
  }

  void resetConversation() {
    _orchestrator.resetConversation();
  }

  void dispose() {
    _orchestrator.dispose();
  }
}
