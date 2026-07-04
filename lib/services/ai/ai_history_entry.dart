class AIHistoryEntry {
  final DateTime date;

  final int aiScore;
  final int risk;
  final int growth;
  final int stability;
  final int diversification;

  const AIHistoryEntry({
    required this.date,
    required this.aiScore,
    required this.risk,
    required this.growth,
    required this.stability,
    required this.diversification,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'aiScore': aiScore,
      'risk': risk,
      'growth': growth,
      'stability': stability,
      'diversification': diversification,
    };
  }

  factory AIHistoryEntry.fromMap(Map<String, dynamic> map) {
    return AIHistoryEntry(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      aiScore: map['aiScore'],
      risk: map['risk'],
      growth: map['growth'],
      stability: map['stability'],
      diversification: map['diversification'],
    );
  }
}