import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/profile/active_profile_bar.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color _primary = Color(0xFF008DB9);
  static const Color _bg = Color(0xFFF7F9FC);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: const ActiveProfileBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: const [
          _DashboardHero(),
          SizedBox(height: 16),
          _SummaryGrid(),
          SizedBox(height: 16),
          _SectionTitle(title: 'Portföy Sağlığı'),
          SizedBox(height: 10),
          _HealthCard(),
          SizedBox(height: 16),
          _SectionTitle(title: 'AI Önerisi'),
          SizedBox(height: 10),
          _AiInsightCard(),
          SizedBox(height: 16),
          _SectionTitle(title: 'Hızlı İşlemler'),
          SizedBox(height: 10),
          _QuickDashboardActions(),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genel Finans Özeti',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: DashboardPage._text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Varlıkların, risk durumun ve AI destekli önerilerin tek ekranda.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: DashboardPage._muted,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashboardPage._primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: DashboardPage._primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dashboard Pro altyapısı hazır.',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: DashboardPage._text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Toplam Varlık',
                value: '₺0',
                icon: Icons.account_balance_wallet_rounded,
                color: DashboardPage._primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Günlük Değişim',
                value: '₺0',
                icon: Icons.trending_up_rounded,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Risk Skoru',
                value: '—',
                icon: Icons.shield_rounded,
                color: Color(0xFF7C3AED),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'AI Skoru',
                value: '—',
                icon: Icons.psychology_rounded,
                color: Color(0xFFF97316),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: DashboardPage._text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: DashboardPage._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dengeli başlangıç modu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: DashboardPage._text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Portföy verileri bağlandıkça çeşitlilik, yoğunlaşma ve risk analizi burada görünecek.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: DashboardPage._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: DashboardPage._primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI analizleri Sprint 7 içinde portföy verilerine bağlanacak. Şimdilik Dashboard ekranı aktif ve hazır.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: DashboardPage._text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDashboardActions extends StatelessWidget {
  const _QuickDashboardActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_rounded,
            label: 'Varlık',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.insights_rounded,
            label: 'Analiz',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.settings_rounded,
            label: 'Ayar',
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: DashboardPage._primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  color: DashboardPage._text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: DashboardPage._text,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
