import 'portfolio_analysis.dart';

class AIContextBuilder {
  const AIContextBuilder();

  String build(PortfolioAnalysis analysis) {
    final buffer = StringBuffer();

    buffer.writeln('Portfolio Summary');
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
      buffer.writeln('Strengths:');
      for (final item in analysis.strengths) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    if (analysis.warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final item in analysis.warnings) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
    }

    if (analysis.recommendations.isNotEmpty) {
      buffer.writeln('Recommendations:');
      for (final item in analysis.recommendations) {
        buffer.writeln('- $item');
      }
    }

    return buffer.toString();
  }
}