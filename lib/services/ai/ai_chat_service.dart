import 'ai_context_builder.dart';
import 'ai_provider.dart';
import 'portfolio_analysis.dart';

class AIChatService {
  final AIProvider provider;
  final AIContextBuilder contextBuilder;

  AIChatService({
    required this.provider,
    AIContextBuilder? contextBuilder,
  }) : contextBuilder = contextBuilder ?? const AIContextBuilder();

  Future<String> ask({
    required PortfolioAnalysis analysis,
    required String question,
  }) async {
    final context = contextBuilder.build(analysis);

    return provider.ask(
      context: context,
      question: question,
    );
  }
}