import 'package:myfin_mobile/services/ai/ai_service.dart';
import 'package:myfin_mobile/services/ai/conversation_memory.dart';
import 'package:myfin_mobile/services/ai/openai_provider.dart';
import 'package:myfin_mobile/services/ai/portfolio_context_builder.dart';
import 'package:myfin_mobile/models/ai/ai_intelligence.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/services/ai_advisor_service.dart';
import 'package:myfin_mobile/services/ai_analysis_service.dart';
import 'package:myfin_mobile/services/ai_simulation_service.dart';

/// Single entry point for MyFin AI features.
///
/// Place this file at:
/// lib/services/ai/ai_orchestrator.dart
///
/// UI screens should talk to this class instead of creating AIService,
/// OpenAIProvider, PromptBuilder, or PortfolioContextBuilder directly.
class AIOrchestrator {
  AIOrchestrator({
    AIService? service,
    AIProvider? provider,
    ConversationMemory? memory,
    PortfolioContextBuilder? portfolioContextBuilder,
    AIAnalysisService? analysisService,
    AIAdvisorService? advisorService,
    AISimulationService? simulationService,
    UserFinancialContext? userContext,
    List<IntelligenceSignal> initialSignals = const <IntelligenceSignal>[],
    bool useOpenAIProvider = true,
  })  : _portfolioContextBuilder =
            portfolioContextBuilder ?? const PortfolioContextBuilder(),
        _analysisService = analysisService ?? const AIAnalysisService(),
        _advisorService = advisorService ?? const AIAdvisorService(),
        _simulationService = simulationService ?? const AISimulationService(),
        _userContext = userContext,
        _signals = List<IntelligenceSignal>.of(initialSignals),
        _service = service ??
            AIService(
              memory: memory,
              provider: provider ??
                  (useOpenAIProvider
                      ? OpenAIProvider()
                      : const LocalMyFinAIProvider()),
            );

  final AIService _service;
  final PortfolioContextBuilder _portfolioContextBuilder;
  final AIAnalysisService _analysisService;
  final AIAdvisorService _advisorService;
  final AISimulationService _simulationService;

  UserFinancialContext? _userContext;
  PortfolioContext? _portfolioContext;
  List<IntelligenceSignal> _signals;
  bool _disposed = false;

  AIService get service => _service;
  ConversationMemory get memory => _service.memory;
  bool get isDisposed => _disposed;
  bool get hasConversation => _service.hasConversation;
  PortfolioContext? get portfolioContext => _portfolioContext;
  UserFinancialContext? get userContext => _userContext;
  List<IntelligenceSignal> get signals => List<IntelligenceSignal>.unmodifiable(_signals);

  /// Main method for chat screens.
  Future<AIResponse> ask({
    required String message,
    PortfolioContext? portfolioContext,
    PortfolioContextInput? portfolioInput,
    UserFinancialContext? userContext,
    List<IntelligenceSignal>? signals,
  }) async {
    if (_disposed) {
      return AIResponse.failure(
        'AI servisi kapalı görünüyor. Lütfen ekranı yenileyip tekrar dene.',
        error: 'AIOrchestrator is disposed.',
      );
    }

    final PortfolioContext? resolvedPortfolioContext = _resolvePortfolioContext(
      portfolioContext: portfolioContext,
      portfolioInput: portfolioInput,
    );

    if (userContext != null) {
      _userContext = userContext;
    }
    if (signals != null) {
      _signals = List<IntelligenceSignal>.of(signals);
    }

    return _service.generateResponse(
      userMessage: message,
      portfolioContext: resolvedPortfolioContext,
      userContext: _userContext,
      signals: _signals,
    );
  }

  /// Builds all local dashboard intelligence from portfolio items.
  ///
  /// This method does not call the remote AI provider. It aggregates the local
  /// score, analysis, advisor, and simulation layers into a single object so
  /// dashboard screens can depend on one stable model.
  AIIntelligence buildIntelligence(List<PortfolioItem> items) {
    final analysis = _analysisService.analyze(items);
    final advisor = _advisorService.advise(items);
    final simulation = _simulationService.simulate(items);

    return AIIntelligence(
      score: analysis.score,
      analysis: analysis,
      advisor: advisor,
      simulation: simulation,
      generatedAt: DateTime.now(),
    );
  }

  /// Convenience method for Intelligence cards that need a quick AI insight.
  Future<AIResponse> explainPortfolio({
    PortfolioContext? portfolioContext,
    PortfolioContextInput? portfolioInput,
    String message = 'Portföyümü kısa ve aksiyon odaklı yorumlar mısın?',
  }) {
    return ask(
      message: message,
      portfolioContext: portfolioContext,
      portfolioInput: portfolioInput,
    );
  }

  /// Keeps context updated without sending a user message to the provider.
  void updateContext({
    PortfolioContext? portfolioContext,
    PortfolioContextInput? portfolioInput,
    UserFinancialContext? userContext,
    List<IntelligenceSignal>? signals,
  }) {
    if (_disposed) return;

    final PortfolioContext? resolvedPortfolioContext = _resolvePortfolioContext(
      portfolioContext: portfolioContext,
      portfolioInput: portfolioInput,
    );

    if (resolvedPortfolioContext != null) {
      _portfolioContext = resolvedPortfolioContext;
    }
    if (userContext != null) {
      _userContext = userContext;
    }
    if (signals != null) {
      _signals = List<IntelligenceSignal>.of(signals);
    }
  }

  /// Runs a very small local check. It does not call the remote provider.
  bool warmUp() {
    if (_disposed) return false;
    return memory.messages.isNotEmpty || !hasConversation;
  }

  void addSignal(IntelligenceSignal signal) {
    if (_disposed) return;
    _signals = <IntelligenceSignal>[..._signals, signal];
  }

  void clearSignals() {
    if (_disposed) return;
    _signals = <IntelligenceSignal>[];
  }

  void resetConversation({bool keepSystemPrompt = true}) {
    if (_disposed) return;
    _service.resetConversation(keepSystemPrompt: keepSystemPrompt);
  }

  void clearMemory({bool keepSystemPrompt = true}) {
    resetConversation(keepSystemPrompt: keepSystemPrompt);
  }

  void dispose() {
    _disposed = true;
  }

  PortfolioContext? _resolvePortfolioContext({
    PortfolioContext? portfolioContext,
    PortfolioContextInput? portfolioInput,
  }) {
    if (portfolioContext != null) {
      _portfolioContext = portfolioContext;
      return _portfolioContext;
    }

    if (portfolioInput != null && !portfolioInput.isEmpty) {
      _portfolioContext = _portfolioContextBuilder.build(portfolioInput);
      return _portfolioContext;
    }

    return _portfolioContext;
  }
}
