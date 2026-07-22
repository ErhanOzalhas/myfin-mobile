import 'ai_history_entry.dart';
import 'portfolio_analysis.dart';
import '../portfolio_profile_service.dart';

class AIHistoryService {
  const AIHistoryService();

  static final Map<String, List<AIHistoryEntry>> _entriesByProfile = {};

  List<AIHistoryEntry> get _entries => _entriesByProfile.putIfAbsent(
    PortfolioProfileService.instance.activeProfileId.value,
    () => <AIHistoryEntry>[],
  );

  List<AIHistoryEntry> get history {
    return List.unmodifiable(_entries);
  }

  AIHistoryEntry? get latest {
    if (_entries.isEmpty) return null;
    return _entries.last;
  }

  AIHistoryEntry? get previous {
    if (_entries.length < 2) return null;
    return _entries[_entries.length - 2];
  }

  bool get hasPreviousAnalysis => _entries.length >= 2;

  AIHistoryEntry saveAnalysis(PortfolioAnalysis analysis) {
    final entry = AIHistoryEntry(
      date: DateTime.now(),
      aiScore: analysis.aiScore,
      risk: analysis.risk,
      growth: analysis.growth,
      stability: analysis.stability,
      diversification: analysis.diversification,
    );

    _entries.add(entry);

    if (_entries.length > 30) {
      _entries.removeAt(0);
    }

    return entry;
  }

  /// Saves the analysis only if it is meaningfully different from the latest
  /// saved entry. This prevents the UI from creating many duplicate history
  /// rows while it rebuilds.
  AIHistoryEntry saveIfChanged(
    PortfolioAnalysis analysis, {
    int minScoreDelta = 1,
  }) {
    final latestEntry = latest;

    if (latestEntry == null) {
      return saveAnalysis(analysis);
    }

    final hasMeaningfulChange =
        (latestEntry.aiScore - analysis.aiScore).abs() >= minScoreDelta ||
        latestEntry.risk != analysis.risk ||
        latestEntry.growth != analysis.growth ||
        latestEntry.stability != analysis.stability ||
        latestEntry.diversification != analysis.diversification;

    if (!hasMeaningfulChange) {
      return latestEntry;
    }

    return saveAnalysis(analysis);
  }

  void seedDemoHistoryIfNeeded(PortfolioAnalysis current) {
    if (_entries.isNotEmpty) return;

    final now = DateTime.now();

    _entries.addAll([
      AIHistoryEntry(
        date: now.subtract(const Duration(days: 7)),
        aiScore: (current.aiScore - 5).clamp(0, 100).toInt(),
        risk: (current.risk + 6).clamp(0, 100).toInt(),
        growth: (current.growth - 2).clamp(0, 100).toInt(),
        stability: (current.stability - 3).clamp(0, 100).toInt(),
        diversification: (current.diversification - 8).clamp(0, 100).toInt(),
      ),
      AIHistoryEntry(
        date: now.subtract(const Duration(days: 2)),
        aiScore: (current.aiScore - 2).clamp(0, 100).toInt(),
        risk: (current.risk + 3).clamp(0, 100).toInt(),
        growth: (current.growth - 1).clamp(0, 100).toInt(),
        stability: (current.stability - 1).clamp(0, 100).toInt(),
        diversification: (current.diversification - 3).clamp(0, 100).toInt(),
      ),
    ]);
  }

  void clear() {
    _entries.clear();
  }
}
