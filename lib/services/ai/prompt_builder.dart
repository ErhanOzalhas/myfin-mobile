import 'package:myfin_mobile/services/ai/ai_service.dart';

/// Builds the final prompt that goes from MyFin to the selected AI provider.
///
/// Place this file at:
/// lib/services/ai/prompt_builder.dart
class PromptBuilder {
  const PromptBuilder({
    this.maxCharacters = 8000,
    this.memoryMessageLimit = 12,
  });

  final int maxCharacters;
  final int memoryMessageLimit;

  AIPrompt build({
    required String userMessage,
    String? systemPrompt,
    String? conversationMemory,
    PortfolioContext? portfolioContext,
    UserFinancialContext? userContext,
    List<IntelligenceSignal> signals = const <IntelligenceSignal>[],
  }) {
    final String normalizedUserMessage = _normalize(userMessage);
    final String resolvedSystemPrompt = buildSystemPrompt(
      baseSystemPrompt: systemPrompt,
      userContext: userContext,
    );

    final List<String> sections = <String>[
      _section('SYSTEM', resolvedSystemPrompt),
      _section('USER CONTEXT', buildUserContext(userContext)),
      _section('PORTFOLIO CONTEXT', buildPortfolioContext(portfolioContext)),
      _section('INTELLIGENCE SIGNALS', buildSignalsContext(signals)),
      _section('CONVERSATION MEMORY', conversationMemory ?? ''),
      _section('CURRENT USER MESSAGE', normalizedUserMessage),
    ];

    final String fullPrompt = _limit(
      sections.where((String section) => section.trim().isNotEmpty).join('\n\n'),
    );

    return AIPrompt(
      systemPrompt: resolvedSystemPrompt,
      userMessage: normalizedUserMessage,
      fullPrompt: fullPrompt,
      portfolioContext: portfolioContext,
      userContext: userContext,
      signals: signals,
    );
  }

  String buildSystemPrompt({
    String? baseSystemPrompt,
    UserFinancialContext? userContext,
  }) {
    final StringBuffer buffer = StringBuffer(
      _normalize(baseSystemPrompt).isEmpty
          ? 'You are MyFin AI, a premium personal finance assistant inside the MyFin app.'
          : _normalize(baseSystemPrompt),
    );

    buffer.writeln();
    buffer.writeln('Core rules:');
    buffer.writeln('- Answer in Turkish unless the user clearly asks for another language.');
    buffer.writeln('- Be concise, calm, practical, and action-oriented.');
    buffer.writeln('- Do not fabricate prices, balances, performance, or market data.');
    buffer.writeln('- If data is missing, say exactly what is missing.');
    buffer.writeln('- Do not present investment analysis as guaranteed advice.');
    buffer.writeln('- Prefer one clear next step at the end.');

    final String riskProfile = _normalize(userContext?.riskProfile);
    if (riskProfile.isNotEmpty) {
      buffer.writeln('- User risk profile: $riskProfile.');
    }

    return _normalize(buffer.toString());
  }

  String buildUserContext(UserFinancialContext? context) {
    if (context == null || context.isEmpty) return '';

    final List<String> lines = <String>[
      if (_normalize(context.name).isNotEmpty) 'Name: ${_normalize(context.name)}',
      if (_normalize(context.baseCurrency).isNotEmpty)
        'Base currency: ${_normalize(context.baseCurrency)}',
      if (_normalize(context.riskProfile).isNotEmpty)
        'Risk profile: ${_normalize(context.riskProfile)}',
      if (context.goals.isNotEmpty) 'Goals: ${context.goals.map(_normalize).where((String item) => item.isNotEmpty).join(', ')}',
      if (context.preferences.isNotEmpty)
        'Preferences: ${context.preferences.map(_normalize).where((String item) => item.isNotEmpty).join(', ')}',
    ];

    return lines.where((String line) => line.trim().isNotEmpty).join('\n');
  }

  String buildPortfolioContext(PortfolioContext? context) {
    if (context == null || context.isEmpty) return '';

    final List<String> lines = <String>[
      if (_normalize(context.totalValueText).isNotEmpty)
        'Total value: ${_normalize(context.totalValueText)}',
      if (_normalize(context.dailyChangeText).isNotEmpty)
        'Daily change: ${_normalize(context.dailyChangeText)}',
      if (_normalize(context.cashBalanceText).isNotEmpty)
        'Cash balance: ${_normalize(context.cashBalanceText)}',
      if (_normalize(context.riskLevel).isNotEmpty)
        'Risk level: ${_normalize(context.riskLevel)}',
    ];

    if (context.holdings.isNotEmpty) {
      lines.add('Holdings:');
      for (final PortfolioHolding holding in context.holdings.take(20)) {
        final String symbol = _normalize(holding.symbol);
        final String summary = _normalize(holding.displaySummary);
        if (symbol.isEmpty && summary.isEmpty) continue;
        lines.add('- $symbol: $summary');
      }
    }

    return lines.where((String line) => line.trim().isNotEmpty).join('\n');
  }

  String buildSignalsContext(List<IntelligenceSignal> signals) {
    if (signals.isEmpty) return '';

    return signals.take(10).map((IntelligenceSignal signal) {
      final String priority = _normalize(signal.priority);
      final String title = _normalize(signal.title);
      final String description = _normalize(signal.description);
      return '- [$priority] $title: $description';
    }).where((String line) => line.trim().isNotEmpty).join('\n');
  }

  String buildConversationSection(String? conversationMemory) {
    return _normalize(conversationMemory);
  }

  String buildUserMessageSection(String userMessage) {
    return _normalize(userMessage);
  }

  String buildFinalPrompt({
    required String userMessage,
    String? systemPrompt,
    String? conversationMemory,
    PortfolioContext? portfolioContext,
    UserFinancialContext? userContext,
    List<IntelligenceSignal> signals = const <IntelligenceSignal>[],
  }) {
    return build(
      userMessage: userMessage,
      systemPrompt: systemPrompt,
      conversationMemory: conversationMemory,
      portfolioContext: portfolioContext,
      userContext: userContext,
      signals: signals,
    ).fullPrompt;
  }

  String _section(String title, String value) {
    final String normalized = _normalize(value);
    if (normalized.isEmpty) return '';
    return '$title:\n$normalized';
  }

  String _limit(String value) {
    final int limit = maxCharacters < 1000 ? 1000 : maxCharacters;
    if (value.length <= limit) return value;

    final String tail = value.substring(value.length - limit);
    return 'Earlier context was trimmed because the prompt became too long.\n\n$tail';
  }

  String _normalize(String? value) {
    if (value == null) return '';

    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((String line) => line.trimRight())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
