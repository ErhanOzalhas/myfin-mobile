class DashboardSummary {
  final double totalCost;
  final double currentValue;
  final double profitLoss;
  final double profitPercent;

  final String? bestPerformer;
  final double bestPerformance;

  final String? worstPerformer;
  final double worstPerformance;

  const DashboardSummary({
    required this.totalCost,
    required this.currentValue,
    required this.profitLoss,
    required this.profitPercent,
    required this.bestPerformer,
    required this.bestPerformance,
    required this.worstPerformer,
    required this.worstPerformance,
  });
}