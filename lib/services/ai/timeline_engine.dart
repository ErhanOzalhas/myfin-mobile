import 'ai_history_entry.dart';
import 'ai_trend_result.dart';
import 'portfolio_analysis.dart';

class AITimelineEvent {
  final String label;
  final String title;
  final String message;
  final TimelineEventTone tone;

  const AITimelineEvent({
    required this.label,
    required this.title,
    required this.message,
    required this.tone,
  });
}

enum TimelineEventTone {
  positive,
  neutral,
  warning,
}

class TimelineEngine {
  const TimelineEngine();

  List<AITimelineEvent> build({
    required PortfolioAnalysis analysis,
    required AITrendResult trend,
    List<AIHistoryEntry> history = const [],
  }) {
    final events = <AITimelineEvent>[];

    if (!trend.hasPreviousData) {
      events.add(
        AITimelineEvent(
          label: 'Bugün',
          title: 'İlk AI analizi oluşturuldu',
          message:
              'AI Score ${analysis.aiScore}, risk ${analysis.risk}, çeşitlendirme ${analysis.diversification} olarak hesaplandı.',
          tone: TimelineEventTone.neutral,
        ),
      );
    } else {
      final aiChange = trend.aiScoreChange ?? 0;
      final riskChange = trend.riskChange ?? 0;
      final diversificationChange = trend.diversificationChange ?? 0;

      events.add(
        AITimelineEvent(
          label: 'Bugün',
          title: aiChange >= 0
              ? 'AI skoru iyileşti'
              : 'AI skoru geriledi',
          message: aiChange == 0
              ? 'AI Score son analize göre sabit kaldı.'
              : 'AI Score son analize göre ${_signed(aiChange)} puan değişti.',
          tone: aiChange >= 0 ? TimelineEventTone.positive : TimelineEventTone.warning,
        ),
      );

      events.add(
        AITimelineEvent(
          label: 'Risk',
          title: riskChange <= 0 ? 'Risk azaldı' : 'Risk yükseldi',
          message: riskChange == 0
              ? 'Risk seviyesi son analize göre sabit kaldı.'
              : 'Risk son analize göre ${_signed(riskChange)} puan değişti.',
          tone: riskChange <= 0 ? TimelineEventTone.positive : TimelineEventTone.warning,
        ),
      );

      events.add(
        AITimelineEvent(
          label: 'Dağılım',
          title: diversificationChange >= 0
              ? 'Çeşitlendirme iyileşti'
              : 'Çeşitlendirme zayıfladı',
          message: diversificationChange == 0
              ? 'Çeşitlendirme son analize göre sabit kaldı.'
              : 'Çeşitlendirme son analize göre ${_signed(diversificationChange)} puan değişti.',
          tone: diversificationChange >= 0
              ? TimelineEventTone.positive
              : TimelineEventTone.warning,
        ),
      );
    }

    if (analysis.warnings.isNotEmpty) {
      events.add(
        AITimelineEvent(
          label: 'Uyarı',
          title: 'AI yeni risk sinyali üretti',
          message: analysis.warnings.first,
          tone: TimelineEventTone.warning,
        ),
      );
    }

    if (analysis.recommendations.isNotEmpty) {
      events.add(
        AITimelineEvent(
          label: 'Öneri',
          title: 'Yeni aksiyon önerisi',
          message: analysis.recommendations.first,
          tone: TimelineEventTone.neutral,
        ),
      );
    }

    final lastHistorical = history.length >= 2 ? history[history.length - 2] : null;
    if (lastHistorical != null) {
      events.add(
        AITimelineEvent(
          label: _formatRelativeDate(lastHistorical.date),
          title: 'Önceki analiz kaydı',
          message:
              'Önceki AI Score ${lastHistorical.aiScore}, risk ${lastHistorical.risk}, çeşitlendirme ${lastHistorical.diversification}.',
          tone: TimelineEventTone.neutral,
        ),
      );
    }

    return events.take(5).toList();
  }

  String _signed(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays <= 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta önce';
    return '${(diff.inDays / 30).floor()} ay önce';
  }
}
