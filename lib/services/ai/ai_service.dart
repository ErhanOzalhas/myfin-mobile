import 'conversation_memory.dart';

/// Core AI service layer for MyFin.
///
/// This file keeps AI logic outside the UI. It is intentionally provider-agnostic:
/// today it can run with the local fallback provider, and later it can be wired
/// to OpenAI, Gemini, Firebase Functions, or another backend without changing
/// the chat screen.
class AIService {
  AIService({
    ConversationMemory? memory,
    AIProvider? provider,
    int maxPromptLength = 12000,
  }) : memory =
           memory ??
           ConversationMemory(
             maxMessages: 50,
             systemPrompt: _defaultSystemPrompt,
           ),
       provider = provider ?? const LocalMyFinAIProvider(),
       _maxPromptLength = maxPromptLength < 500 ? 500 : maxPromptLength;

  final ConversationMemory memory;
  final AIProvider provider;
  final int _maxPromptLength;

  static const String _defaultSystemPrompt =
      'You are MyFin AI, a calm, practical, and premium personal finance assistant. '
      'Help the user understand their portfolio, spending, risk, alerts, and next actions. '
      'Do not provide guaranteed investment outcomes. Keep answers clear, useful, and responsible.';

  bool get hasConversation => memory.isNotEmpty;

  /// Main entry point used by UI screens.
  Future<AIResponse> generateResponse({
    required String userMessage,
    PortfolioContext? portfolioContext,
    UserFinancialContext? userContext,
    List<IntelligenceSignal> signals = const <IntelligenceSignal>[],
  }) async {
    final PromptValidation validation = validatePrompt(userMessage);
    if (!validation.isValid) {
      return AIResponse.failure(validation.message);
    }

    final String trimmedMessage = userMessage.trim();
    memory.addUser(trimmedMessage);

    final AIPrompt prompt = buildPrompt(
      userMessage: trimmedMessage,
      portfolioContext: portfolioContext,
      userContext: userContext,
      signals: signals,
    );

    try {
      final AIResponse response = await provider.complete(prompt);
      final String answer = response.content.trim().isEmpty
          ? 'Şu anda net bir cevap üretemedim. Lütfen sorunu biraz daha açık yazar mısın?'
          : response.content.trim();

      memory.addAssistant(answer);

      return response.copyWith(content: answer, success: true, prompt: prompt);
    } catch (error) {
      const String fallbackMessage =
          'AI yanıtı oluşturulurken bir sorun oluştu. Bağlantı veya servis yapılandırması kontrol edildikten sonra tekrar deneyebilirsin.';
      memory.addAssistant(fallbackMessage);
      return AIResponse.failure(
        fallbackMessage,
        error: error.toString(),
        prompt: prompt,
      );
    }
  }

  /// Streaming entry point used by chat screens.
  ///
  /// It yields text chunks as the provider receives them. Conversation memory is
  /// updated only after the full assistant answer is completed.
  Stream<String> generateResponseStream({
    required String userMessage,
    PortfolioContext? portfolioContext,
    UserFinancialContext? userContext,
    List<IntelligenceSignal> signals = const <IntelligenceSignal>[],
  }) async* {
    final PromptValidation validation = validatePrompt(userMessage);
    if (!validation.isValid) {
      yield validation.message;
      return;
    }

    final String trimmedMessage = userMessage.trim();
    memory.addUser(trimmedMessage);

    final AIPrompt prompt = buildPrompt(
      userMessage: trimmedMessage,
      portfolioContext: portfolioContext,
      userContext: userContext,
      signals: signals,
    );

    final StringBuffer answerBuffer = StringBuffer();

    try {
      await for (final String chunk in provider.stream(prompt)) {
        if (chunk.isEmpty) continue;
        answerBuffer.write(chunk);
        yield chunk;
      }

      final String answer = answerBuffer.toString().trim();
      if (answer.isEmpty) {
        const String fallbackMessage =
            'Şu anda net bir cevap üretemedim. Lütfen sorunu biraz daha açık yazar mısın?';
        memory.addAssistant(fallbackMessage);
        yield fallbackMessage;
        return;
      }

      memory.addAssistant(answer);
    } catch (error) {
      final String partialAnswer = answerBuffer.toString().trim();
      if (partialAnswer.isNotEmpty) {
        memory.addAssistant(partialAnswer);
        return;
      }

      const String fallbackMessage =
          'AI yanıtı oluşturulurken bir sorun oluştu. Bağlantı veya servis yapılandırması kontrol edildikten sonra tekrar deneyebilirsin.';
      memory.addAssistant(fallbackMessage);
      yield fallbackMessage;
    }
  }

  AIPrompt buildPrompt({
    required String userMessage,
    PortfolioContext? portfolioContext,
    UserFinancialContext? userContext,
    List<IntelligenceSignal> signals = const <IntelligenceSignal>[],
  }) {
    final String systemPrompt = buildSystemPrompt(userContext: userContext);
    final String conversationContext = buildConversationContext();
    final String portfolioText = buildPortfolioContext(portfolioContext);
    final String userText = buildUserContext(userContext);
    final String signalText = buildSignalsContext(signals);

    final String composed = <String>[
      'SYSTEM:\n$systemPrompt',
      if (userText.isNotEmpty) 'USER CONTEXT:\n$userText',
      if (portfolioText.isNotEmpty) 'PORTFOLIO CONTEXT:\n$portfolioText',
      if (signalText.isNotEmpty) 'INTELLIGENCE SIGNALS:\n$signalText',
      if (conversationContext.isNotEmpty)
        'CONVERSATION MEMORY:\n$conversationContext',
      'CURRENT USER MESSAGE:\n$userMessage',
    ].join('\n\n');

    return AIPrompt(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      fullPrompt: _limitText(composed, _maxPromptLength),
      portfolioContext: portfolioContext,
      userContext: userContext,
      signals: signals,
    );
  }

  String buildSystemPrompt({UserFinancialContext? userContext}) {
    final StringBuffer buffer = StringBuffer(_defaultSystemPrompt);

    buffer.writeln();
    buffer.writeln('Rules:');
    buffer.writeln('- Be concise, specific, and action-oriented.');
    buffer.writeln('- Use Turkish unless the user writes in another language.');
    buffer.writeln('- Explain uncertainty clearly.');
    buffer.writeln(
      '- Never claim real-time market data unless provided in context.',
    );
    buffer.writeln(
      '- For investment topics, frame ideas as analysis, not as guaranteed advice.',
    );

    if (userContext?.riskProfile != null &&
        userContext!.riskProfile!.trim().isNotEmpty) {
      buffer.writeln(
        '- User risk profile: ${userContext.riskProfile!.trim()}.',
      );
    }

    return buffer.toString().trim();
  }

  String buildConversationContext({int lastMessages = 12}) {
    final List<ConversationMessage> messages = memory.lastMessages(
      lastMessages,
    );
    if (messages.isEmpty) return '';

    return messages
        .where((ConversationMessage message) => !message.isSystem)
        .map((ConversationMessage message) {
          final String role = message.role.toUpperCase();
          return '$role: ${message.content.trim()}';
        })
        .join('\n');
  }

  String buildPortfolioContext(PortfolioContext? context) {
    if (context == null || context.isEmpty) return '';

    final StringBuffer buffer = StringBuffer();
    if (context.totalValueText != null) {
      buffer.writeln('Total value: ${context.totalValueText}');
    }
    if (context.dailyChangeText != null) {
      buffer.writeln('Daily change: ${context.dailyChangeText}');
    }
    if (context.cashBalanceText != null) {
      buffer.writeln('Cash balance: ${context.cashBalanceText}');
    }
    if (context.riskLevel != null) {
      buffer.writeln('Risk level: ${context.riskLevel}');
    }
    if (context.holdings.isNotEmpty) {
      buffer.writeln('Holdings:');
      for (final PortfolioHolding holding in context.holdings.take(20)) {
        buffer.writeln('- ${holding.symbol}: ${holding.displaySummary}');
      }
    }

    return buffer.toString().trim();
  }

  String buildUserContext(UserFinancialContext? context) {
    if (context == null || context.isEmpty) return '';

    final StringBuffer buffer = StringBuffer();
    if (context.name != null) buffer.writeln('Name: ${context.name}');
    if (context.baseCurrency != null) {
      buffer.writeln('Base currency: ${context.baseCurrency}');
    }
    if (context.riskProfile != null) {
      buffer.writeln('Risk profile: ${context.riskProfile}');
    }
    if (context.goals.isNotEmpty) {
      buffer.writeln('Goals: ${context.goals.join(', ')}');
    }
    if (context.preferences.isNotEmpty) {
      buffer.writeln('Preferences: ${context.preferences.join(', ')}');
    }

    return buffer.toString().trim();
  }

  String buildSignalsContext(List<IntelligenceSignal> signals) {
    if (signals.isEmpty) return '';

    return signals
        .take(10)
        .map((IntelligenceSignal signal) {
          return '- [${signal.priority}] ${signal.title}: ${signal.description}';
        })
        .join('\n');
  }

  PromptValidation validatePrompt(String userMessage) {
    final String value = userMessage.trim();
    if (value.isEmpty) {
      return const PromptValidation.invalid('Lütfen AI için bir mesaj yaz.');
    }
    if (value.length > _maxPromptLength) {
      return PromptValidation.invalid(
        'Mesaj çok uzun. Lütfen daha kısa ve net bir soru gönder.',
      );
    }
    return const PromptValidation.valid();
  }

  void resetConversation({bool keepSystemPrompt = true}) {
    memory.clear(keepSystemMessages: keepSystemPrompt);
    if (keepSystemPrompt &&
        memory.messagesByRole(ConversationRole.system).isEmpty) {
      memory.addSystem(_defaultSystemPrompt);
    }
  }

  String _limitText(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(value.length - maxLength);
  }
}

abstract class AIProvider {
  Future<AIResponse> complete(AIPrompt prompt);

  Stream<String> stream(AIPrompt prompt);
}

/// Temporary local provider until a real LLM backend is connected.
/// It gives useful deterministic answers and keeps the app functional offline.
class LocalMyFinAIProvider implements AIProvider {
  const LocalMyFinAIProvider();

  @override
  Future<AIResponse> complete(AIPrompt prompt) async {
    final String message = prompt.userMessage.toLowerCase();
    final PortfolioContext? portfolio = prompt.portfolioContext;

    String content;
    if (message.contains('risk') || message.contains('risk')) {
      content = _riskAnswer(portfolio);
    } else if (message.contains('portföy') || message.contains('portfolio')) {
      content = _portfolioAnswer(portfolio);
    } else if (message.contains('alarm') || message.contains('alert')) {
      content =
          'Fiyat alarmı için takip etmek istediğin varlığı, hedef fiyatı ve yönü belirleyebilirsin. MyFin tarafında bunu Intelligence sinyaline dönüştürmek iyi olur.';
    } else {
      content =
          'Bunu MyFin bağlamında değerlendirebilirim. Portföy, risk, nakit dengesi, alarm veya işlem planı üzerinden daha net analiz çıkarabilirim.';
    }

    return AIResponse.success(
      content,
      providerName: 'local-myfin-provider',
      prompt: prompt,
    );
  }

  @override
  Stream<String> stream(AIPrompt prompt) async* {
    final AIResponse response = await complete(prompt);

    for (final int codeUnit in response.content.codeUnits) {
      yield String.fromCharCode(codeUnit);
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
  }

  String _portfolioAnswer(PortfolioContext? portfolio) {
    if (portfolio == null || portfolio.isEmpty) {
      return 'Portföy verisi henüz AI bağlamına gelmedi. Bağlandığında toplam değer, günlük değişim, nakit oranı ve varlık dağılımına göre özet çıkaracağım.';
    }

    final String value = portfolio.totalValueText ?? 'belirtilmemiş';
    final String change = portfolio.dailyChangeText ?? 'günlük değişim yok';
    final int count = portfolio.holdings.length;

    return 'Portföy özetin: toplam değer $value, günlük değişim $change. Şu anda $count varlık görünüyor. İlk bakılacak noktalar: yoğunlaşma riski, nakit oranı ve alarm gerektiren sert hareketler.';
  }

  String _riskAnswer(PortfolioContext? portfolio) {
    if (portfolio?.riskLevel != null) {
      return 'Mevcut risk seviyesi ${portfolio!.riskLevel}. Bunu varlık dağılımı, tek hisse ağırlığı, nakit oranı ve günlük oynaklıkla birlikte yorumlamak gerekir.';
    }
    return 'Risk analizi için portföy dağılımı, nakit oranı ve varlık ağırlıkları gerekli. Bu veriler bağlandığında MyFin sana net bir risk özeti sunabilir.';
  }
}

class AIPrompt {
  const AIPrompt({
    required this.systemPrompt,
    required this.userMessage,
    required this.fullPrompt,
    this.portfolioContext,
    this.userContext,
    this.signals = const <IntelligenceSignal>[],
  });

  final String systemPrompt;
  final String userMessage;
  final String fullPrompt;
  final PortfolioContext? portfolioContext;
  final UserFinancialContext? userContext;
  final List<IntelligenceSignal> signals;
}

class AIResponse {
  const AIResponse({
    required this.content,
    required this.success,
    this.error,
    this.providerName,
    this.prompt,
  });

  final String content;
  final bool success;
  final String? error;
  final String? providerName;
  final AIPrompt? prompt;

  factory AIResponse.success(
    String content, {
    String? providerName,
    AIPrompt? prompt,
  }) {
    return AIResponse(
      content: content,
      success: true,
      providerName: providerName,
      prompt: prompt,
    );
  }

  factory AIResponse.failure(
    String message, {
    String? error,
    AIPrompt? prompt,
  }) {
    return AIResponse(
      content: message,
      success: false,
      error: error,
      prompt: prompt,
    );
  }

  AIResponse copyWith({
    String? content,
    bool? success,
    String? error,
    String? providerName,
    AIPrompt? prompt,
  }) {
    return AIResponse(
      content: content ?? this.content,
      success: success ?? this.success,
      error: error ?? this.error,
      providerName: providerName ?? this.providerName,
      prompt: prompt ?? this.prompt,
    );
  }
}

class PromptValidation {
  const PromptValidation._({required this.isValid, required this.message});

  final bool isValid;
  final String message;

  const PromptValidation.valid() : this._(isValid: true, message: '');

  const PromptValidation.invalid(String message)
    : this._(isValid: false, message: message);
}

class UserFinancialContext {
  const UserFinancialContext({
    this.name,
    this.baseCurrency,
    this.riskProfile,
    this.goals = const <String>[],
    this.preferences = const <String>[],
  });

  final String? name;
  final String? baseCurrency;
  final String? riskProfile;
  final List<String> goals;
  final List<String> preferences;

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) &&
      (baseCurrency == null || baseCurrency!.trim().isEmpty) &&
      (riskProfile == null || riskProfile!.trim().isEmpty) &&
      goals.isEmpty &&
      preferences.isEmpty;
}

class PortfolioContext {
  const PortfolioContext({
    this.totalValueText,
    this.dailyChangeText,
    this.cashBalanceText,
    this.riskLevel,
    this.holdings = const <PortfolioHolding>[],
  });

  final String? totalValueText;
  final String? dailyChangeText;
  final String? cashBalanceText;
  final String? riskLevel;
  final List<PortfolioHolding> holdings;

  bool get isEmpty =>
      (totalValueText == null || totalValueText!.trim().isEmpty) &&
      (dailyChangeText == null || dailyChangeText!.trim().isEmpty) &&
      (cashBalanceText == null || cashBalanceText!.trim().isEmpty) &&
      (riskLevel == null || riskLevel!.trim().isEmpty) &&
      holdings.isEmpty;
}

class PortfolioHolding {
  const PortfolioHolding({
    required this.symbol,
    this.name,
    this.quantityText,
    this.valueText,
    this.changeText,
    this.weightText,
  });

  final String symbol;
  final String? name;
  final String? quantityText;
  final String? valueText;
  final String? changeText;
  final String? weightText;

  String get displaySummary {
    final List<String> parts = <String>[
      if (name != null && name!.trim().isNotEmpty) name!,
      if (quantityText != null && quantityText!.trim().isNotEmpty)
        'qty $quantityText',
      if (valueText != null && valueText!.trim().isNotEmpty) valueText!,
      if (changeText != null && changeText!.trim().isNotEmpty) changeText!,
      if (weightText != null && weightText!.trim().isNotEmpty)
        'weight $weightText',
    ];
    return parts.isEmpty ? 'no details' : parts.join(', ');
  }
}

class IntelligenceSignal {
  const IntelligenceSignal({
    required this.title,
    required this.description,
    this.priority = IntelligencePriority.medium,
  });

  final String title;
  final String description;
  final String priority;
}

class IntelligencePriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
}
