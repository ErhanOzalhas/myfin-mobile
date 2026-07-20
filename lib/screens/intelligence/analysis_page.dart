import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/repositories/portfolio_repository.dart';
import 'package:myfin_mobile/services/ai_daily_brief_service.dart';
import 'package:myfin_mobile/services/ai_timeline_service.dart';
import 'package:myfin_mobile/services/portfolio_intelligence_service.dart';
import 'package:myfin_mobile/services/smart_insights_service.dart';
import 'package:myfin_mobile/widgets/dashboard/ai_timeline_card.dart';
import 'package:myfin_mobile/widgets/home/ai_score_section.dart';
import 'package:myfin_mobile/widgets/intelligence/ai_daily_brief_card.dart';
import 'package:myfin_mobile/widgets/intelligence/portfolio_pulse_card.dart';
import 'package:myfin_mobile/widgets/intelligence/smart_insights_card.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('AI Intelligence'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<PortfolioItem>>(
        stream: PortfolioRepository.instance.watchPortfolio(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <PortfolioItem>[];
          final brief = const AIDailyBriefService().build(items);
          final timeline = const AITimelineService().build(items);
          final portfolio = const PortfolioIntelligenceService().build(items);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              AIDailyBriefCard(brief: brief),
              const SizedBox(height: 16),
              AITimelineCard(points: timeline),
              const SizedBox(height: 16),
              const _AnalysisSectionTitle(
                title: 'Portföy Nabzı',
                subtitle: 'Değer, kâr/zarar ve yoğunlaşma özeti.',
              ),
              const SizedBox(height: 12),
              PortfolioPulseCard(portfolio: portfolio),
              const SizedBox(height: 16),
              const _AnalysisSectionTitle(
                title: 'Akıllı İçgörüler',
                subtitle: 'AI tarafından üretilen özet değerlendirmeler.',
              ),
              const SizedBox(height: 12),
              SmartInsightsCard(
                insights: const SmartInsightsService().build(
                  items: items,
                  timeline: timeline,
                ),
              ),
              const SizedBox(height: 16),
              const _AnalysisSectionTitle(
                title: 'Portföy AI Skoru',
                subtitle: 'Mevcut portföy sağlığı ve temel AI metrikleri.',
              ),
              const SizedBox(height: 12),
              AIScoreSection(),
              const SizedBox(height: 16),
              const _ComingSoonPanel(),
            ],
          );
        },
      ),
    );
  }
}

class _AnalysisSectionTitle extends StatelessWidget {
  const _AnalysisSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text(
                'Yakında',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'MyFin AI Chat çok yakında bu merkezin bir parçası olacak.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
