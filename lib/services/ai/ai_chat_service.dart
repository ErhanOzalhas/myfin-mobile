import 'package:myfin_mobile/services/ai/ai_context_builder.dart';
import 'package:myfin_mobile/services/ai/ai_orchestrator.dart';
import 'package:myfin_mobile/services/ai/ai_service.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';
import 'package:myfin_mobile/services/ai/portfolio_ai_context_service.dart';
import 'package:myfin_mobile/services/portfolio_valuation_service.dart';
import 'package:myfin_mobile/repositories/cash_repository.dart';

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
  }) : _orchestrator =
           orchestrator ?? AIOrchestrator(service: service, provider: provider);

  final AIOrchestrator _orchestrator;
  final AIContextBuilder _contextBuilder = const AIContextBuilder();
  final PortfolioAIContextService _portfolioContextService =
      const PortfolioAIContextService();

  Future<String> ask({
    required PortfolioAnalysis analysis,
    PortfolioValuation? valuation,
    required String question,
  }) async {
    final AIResponse response = await _orchestrator.ask(
      message: _buildMessage(
        analysis: analysis,
        valuation: valuation,
        question: question,
      ),
      portfolioInput: valuation == null
          ? null
          : _portfolioContextService.buildInput(
              valuation,
              cashBalance: CashRepository.instance.latest.balance,
            ),
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
    PortfolioValuation? valuation,
    required String question,
  }) {
    return _orchestrator.askStream(
      message: _buildMessage(
        analysis: analysis,
        valuation: valuation,
        question: question,
      ),
      portfolioInput: valuation == null
          ? null
          : _portfolioContextService.buildInput(
              valuation,
              cashBalance: CashRepository.instance.latest.balance,
            ),
      userContext: const UserFinancialContext(
        name: 'MyFin User',
        baseCurrency: 'TRY',
      ),
    );
  }

  String _buildMessage({
    required PortfolioAnalysis analysis,
    PortfolioValuation? valuation,
    required String question,
  }) {
    final String context = _contextBuilder.build(analysis).trim();
    final String valuationContext = valuation == null
        ? 'Gerçek portföy değerlemesi bu istekte mevcut değil.'
        : _portfolioContextService.buildDetailedFacts(
            valuation,
            cashBalance: CashRepository.instance.latest.balance,
          );
    final String searchDirective = _needsCurrentNews(question)
        ? '=== ENABLE_WEB_SEARCH ===\nBu soru güncel haber/gelişme gerektiriyor. Güncel web kaynaklarını ara; haber tarihlerini ve kaynak bağlantılarını ver. Eski haberleri güncelmiş gibi sunma.'
        : '';
    final String chartDirective = _needsChart(question)
        ? '=== NATIVE_CHART_ENABLED ===\nUygulama grafiği gerçek portföy verisinden yerel olarak çizecek. Yanıtta kod bloğu, ASCII çubuk, metin tabanlı grafik veya grafik tablosu üretme; yalnızca grafiği açıklayan kısa yorumu ver.'
        : '';

    return '''
$context

$valuationContext

$searchDirective

$chartDirective

=== USER QUESTION ===
$question
'''
        .trim();
  }

  bool _needsChart(String question) {
    final value = question.toLowerCase();
    return value.contains('grafik') ||
        value.contains('grafiğ') ||
        value.contains('görsel') ||
        value.contains('pasta') ||
        value.contains('sütun') ||
        value.contains('dağılım') ||
        value.contains('dagilim') ||
        value.contains('karşılaştır') ||
        value.contains('karsilastir') ||
        value.contains('trend') ||
        value.contains('grafi') ||
        value.contains('artıyo') ||
        value.contains('arttı') ||
        value.contains('yoğunlaş') ||
        value.contains('yogunlas');
  }

  bool _needsCurrentNews(String question) {
    final value = question.toLowerCase();
    final explicitNewsRequest =
        value.contains('haber') ||
        value.contains('gündem') ||
        value.contains('gelişme') ||
        value.contains('geçmiş') ||
        value.contains('arttı') ||
        value.contains('temettü') ||
        value.contains('artıyo') ||
        value.contains('son 12') ||
        value.contains('KAP') ||
        value.contains('bist') ||
        value.contains('BIST') ||
        value.contains('trend') ||
        value.contains('grafi') ||
        value.contains('son durum') ||
        value.contains('bugün ne oldu') ||
        value.contains('ne oldu');
    final asksForReason =
        value.contains('neden') ||
        value.contains('niye') ||
        value.contains('sebep');
    final mentionsMarketMovement =
        value.contains('düş') ||
        value.contains('yüks') ||
        value.contains('son 12') ||
        value.contains('trend') ||
        value.contains('grafi') ||
        value.contains('geçmiş') ||
        value.contains('gerile') ||
        value.contains('arttı') ||
        value.contains('temettü') ||
        value.contains('KAP') ||
        value.contains('artıyor') ||
        value.contains('değer kayb') ||
        value.contains('değer kazan');
    return explicitNewsRequest || (asksForReason && mentionsMarketMovement);
  }

  void resetConversation() {
    _orchestrator.resetConversation();
  }

  void dispose() {
    _orchestrator.dispose();
  }
}
