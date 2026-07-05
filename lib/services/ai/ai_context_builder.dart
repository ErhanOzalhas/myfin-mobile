import 'portfolio_analysis.dart';

class AIContextBuilder {
  const AIContextBuilder();

  String build(PortfolioAnalysis analysis) {
    final buffer = StringBuffer();
    buffer.writeln(
  'You are MyFin AI, an intelligent financial portfolio assistant.',
);

buffer.writeln(
  'Always answer in Turkish unless the user explicitly requests another language.',
);

buffer.writeln(
  'Write in a professional, friendly and concise tone.',
);

buffer.writeln(
  'Use bullet points when appropriate.',
);

buffer.writeln(
  'Base every recommendation on the portfolio data below.',
);

buffer.writeln(
  'Do not invent portfolio information that is not provided.',
);

buffer.writeln(
  'If there is uncertainty, clearly state your assumptions.',
);

buffer.writeln();
   buffer.writeln('=== PORTFOLIO SUMMARY ===');
    buffer.writeln('');

    buffer.writeln('AI Score: ${analysis.aiScore}');
    buffer.writeln('Risk: ${analysis.risk}');
    buffer.writeln('Growth: ${analysis.growth}');
    buffer.writeln('Stability: ${analysis.stability}');
    buffer.writeln('Diversification: ${analysis.diversification}');
    buffer.writeln('');

    buffer.writeln('Risk Level: ${analysis.riskLevel}');
    buffer.writeln('Investment Style: ${analysis.investmentStyle}');
    buffer.writeln('Focus: ${analysis.focus}');
    buffer.writeln('');

    if (analysis.strengths.isNotEmpty) {
      buffer.writeln('=== STRENGTHS ===');
      for (final item in analysis.strengths) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    if (analysis.warnings.isNotEmpty) {
      buffer.writeln('=== RISKS ===');
      for (final item in analysis.warnings) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    if (analysis.recommendations.isNotEmpty) {
      buffer.writeln('=== RECOMMENDATIONS ===');
      for (final item in analysis.recommendations) {
        buffer.writeln('- $item');
      }
    }

    return buffer.toString();
  }
}