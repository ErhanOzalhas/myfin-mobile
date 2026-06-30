import 'package:flutter/material.dart';

void main() {
  runApp(const MyFinApp());
}

class MyFinApp extends StatelessWidget {
  const MyFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008DB9),
        ),
      ),
      home: const MyFinHome(),
    );
  }
}

class MyFinHome extends StatelessWidget {
  const MyFinHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008DB9), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MyFin',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      Text(
                        'Smart Wealth Tracker',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _MetricCard(
              title: 'Toplam Portföy',
              value: '₺318.387,39',
              subtitle: 'Bugün +₺3.820  ▲ %1,24',
              icon: Icons.account_balance_wallet_rounded,
              positive: true,
            ),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                  child: _MetricCard(
                    title: 'Bekleyen Kâr',
                    value: '₺42.810',
                    subtitle: '+%8,7',
                    icon: Icons.trending_up_rounded,
                    positive: true,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    title: 'Net Servet',
                    value: '₺318K',
                    subtitle: 'Cloud sync',
                    icon: Icons.diamond_rounded,
                    positive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _SectionTitle(title: 'Canlı Piyasa'),
            const _MarketRow(name: 'USD/TRY', value: '₺32,14', change: '▲ %0,42'),
            const _MarketRow(name: 'EUR/TRY', value: '₺34,91', change: '▼ %0,12', positive: false),
            const _MarketRow(name: 'Gram Altın', value: '₺2.438', change: '▲ %0,88'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.pie_chart_rounded), label: 'Portföy'),
          NavigationDestination(icon: Icon(Icons.add_circle_rounded), label: 'Ekle'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Analiz'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool positive;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF008DB9), size: 25),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        'Canlı Piyasa',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  final String name;
  final String value;
  final String change;
  final bool positive;

  const _MarketRow({
    required this.name,
    required this.value,
    required this.change,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Text(change, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}