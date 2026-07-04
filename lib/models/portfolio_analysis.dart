// lib/models/portfolio_analysis.dart

import 'package:flutter/foundation.dart';

@immutable
class PortfolioAnalysis {
  final double totalValue;
  final double totalCost;
  final double totalProfit;
  final double profitPercent;

  final double healthScore;
  final double diversificationScore;
  final double riskScore;

  final Map<String, double> allocation;

  const PortfolioAnalysis({
    required this.totalValue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitPercent,
    required this.healthScore,
    required this.diversificationScore,
    required this.riskScore,
    required this.allocation,
  });

  bool get isProfit => totalProfit >= 0;

  PortfolioAnalysis copyWith({
    double? totalValue,
    double? totalCost,
    double? totalProfit,
    double? profitPercent,
    double? healthScore,
    double? diversificationScore,
    double? riskScore,
    Map<String, double>? allocation,
  }) {
    return PortfolioAnalysis(
      totalValue: totalValue ?? this.totalValue,
      totalCost: totalCost ?? this.totalCost,
      totalProfit: totalProfit ?? this.totalProfit,
      profitPercent: profitPercent ?? this.profitPercent,
      healthScore: healthScore ?? this.healthScore,
      diversificationScore:
          diversificationScore ?? this.diversificationScore,
      riskScore: riskScore ?? this.riskScore,
      allocation: allocation ?? this.allocation,
    );
  }

  factory PortfolioAnalysis.empty() {
    return const PortfolioAnalysis(
      totalValue: 0,
      totalCost: 0,
      totalProfit: 0,
      profitPercent: 0,
      healthScore: 0,
      diversificationScore: 0,
      riskScore: 0,
      allocation: {},
    );
  }
}