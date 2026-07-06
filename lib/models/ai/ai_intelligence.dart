import '../../models/ai_portfolio_score.dart';
import '../../services/ai_analysis_service.dart';
import '../../services/ai_advisor_service.dart';
import '../../services/ai_simulation_service.dart';

/// Central model that contains every AI output required by the dashboard.
///
/// Sprint 4 introduces this object so the UI only consumes a single model
/// instead of talking to multiple AI services independently.
class AIIntelligence {
  const AIIntelligence({
    required this.score,
    required this.analysis,
    required this.advisor,
    required this.simulation,
    this.generatedAt,
  });

  /// Overall portfolio score.
  final AIPortfolioScore score;

  /// Portfolio analysis.
  final AIAnalysisResult analysis;

  /// Action-oriented advisor.
  final AIAdvisorResult advisor;

  /// What-if simulation.
  final AISimulationResult simulation;

  /// Timestamp of the generated intelligence.
  final DateTime? generatedAt;

  AIIntelligence copyWith({
    AIPortfolioScore? score,
    AIAnalysisResult? analysis,
    AIAdvisorResult? advisor,
    AISimulationResult? simulation,
    DateTime? generatedAt,
  }) {
    return AIIntelligence(
      score: score ?? this.score,
      analysis: analysis ?? this.analysis,
      advisor: advisor ?? this.advisor,
      simulation: simulation ?? this.simulation,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}