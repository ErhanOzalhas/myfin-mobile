
import 'package:flutter/material.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
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
          brightness: Brightness.light,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF008DB9).withOpacity(.14),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
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
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: const [
            _Header(),
            SizedBox(height: 24),
            _HeroPortfolioCard(),
            SizedBox(height: 14),
            _KpiGrid(),
            SizedBox(height: 24),
            _SectionTitle(title: 'Canlı Piyasa', action: 'Tümü'),
            _MarketTicker(),
            SizedBox(height: 24),
            _SectionTitle(title: 'Portföy Dağılımı', action: 'Detay'),
            _DistributionCard(),
            SizedBox(height: 24),
            _SectionTitle(title: 'Hızlı İşlemler'),
            _QuickActions(),
            SizedBox(height: 24),
            _SectionTitle(title: 'Son İşlemler', action: 'Tümü'),
            _RecentTransactions(),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF008DB9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Benim Finans',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                      color: Color(0xFF0F172A))),
              SizedBox(height: 2),
              Text('Akıllı yatırım takibi',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
        _RoundIcon(icon: Icons.notifications_none_rounded),
      ],
    );
  }
}

class _HeroPortfolioCard extends StatelessWidget {
  const _HeroPortfolioCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEFF8FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Toplam Portföy Değeri',
                    style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w800)),
              ),
              Icon(Icons.visibility_rounded, color: Color(0xFF64748B), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          const Text('₺318.387,39',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          const Text('Bugün +₺3.820  ▲ %1,24',
              style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 22),
          Container(
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFF008DB9).withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomPaint(
              painter: _MiniLinePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Son güncelleme: 20:00',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Toplam Yatırım',
            value: '₺401.804',
            subtitle: 'Maliyet bazlı',
            icon: Icons.account_balance_wallet_rounded,
            color: Color(0xFF2563EB),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Bekleyen Kâr',
            value: '₺42.810',
            subtitle: '+%8,7',
            icon: Icons.north_east_rounded,
            color: Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MarketTicker extends StatelessWidget {
  const _MarketTicker();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _MarketRow(flag: '🇺🇸', name: 'USD/TRY', value: '₺32,14', change: '▲ %0,42', positive: true),
          _ThinDivider(),
          _MarketRow(flag: '🇪🇺', name: 'EUR/TRY', value: '₺34,91', change: '▼ %0,12', positive: false),
          _ThinDivider(),
          _MarketRow(flag: '🥇', name: 'Gram Altın', value: '₺2.438', change: '▲ %0,88', positive: true),
          _ThinDivider(),
          _MarketRow(flag: '📈', name: 'BIST 100', value: '10.245', change: '▲ %0,62', positive: true),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  final String flag;
  final String name;
  final String value;
  final String change;
  final bool positive;

  const _MarketRow({
    required this.flag,
    required this.name,
    required this.value,
    required this.change,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(change,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          SizedBox(
            height: 145,
            width: 145,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _DonutPainter(),
                  child: const SizedBox.expand(),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₺318K',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    Text('Toplam',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              children: [
                _LegendLine(color: Color(0xFF2563EB), name: 'Altın', value: '%55'),
                SizedBox(height: 12),
                _LegendLine(color: Color(0xFFF59E0B), name: 'BIST', value: '%28'),
                SizedBox(height: 12),
                _LegendLine(color: Color(0xFF16A34A), name: 'Döviz', value: '%17'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: .92,
      children: const [
        _QuickAction(icon: Icons.add_circle_rounded, title: 'Varlık Ekle', color: Color(0xFF008DB9)),
        _QuickAction(icon: Icons.swap_vert_rounded, title: 'İşlem Gir', color: Color(0xFFF97316)),
        _QuickAction(icon: Icons.notifications_active_rounded, title: 'Alarm Kur', color: Color(0xFF7C3AED)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _QuickAction({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconBox(icon: icon, color: color, size: 44),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _TransactionRow(symbol: 'ASELS', type: 'Alış', amount: '₺4.586', detail: '10 lot'),
          _ThinDivider(),
          _TransactionRow(symbol: 'THYAO', type: 'Satış', amount: '₺1.562', detail: '5 lot'),
          _ThinDivider(),
          _TransactionRow(symbol: 'Gram Altın', type: 'Alış', amount: '₺4.851', detail: '2 adet'),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String symbol;
  final String type;
  final String amount;
  final String detail;

  const _TransactionRow({
    required this.symbol,
    required this.type,
    required this.amount,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final positive = type == 'Alış';
    final color = positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(.12),
            child: Text(symbol.characters.first,
                style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symbol,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 3),
                Text(type,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 3),
              Text(detail,
                  style: const TextStyle(
                      color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
        if (action != null)
          Text(action!,
              style: const TextStyle(
                  color: Color(0xFF2563EB), fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: size * .56),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;

  const _RoundIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Icon(icon, color: const Color(0xFF0F172A)),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String name;
  final String value;

  const _LegendLine({required this.color, required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 11,
            height: 11,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB));
  }
}

class _MiniLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * .72),
      Offset(size.width * .12, size.height * .62),
      Offset(size.width * .24, size.height * .66),
      Offset(size.width * .36, size.height * .48),
      Offset(size.width * .48, size.height * .55),
      Offset(size.width * .60, size.height * .42),
      Offset(size.width * .72, size.height * .36),
      Offset(size.width * .84, size.height * .28),
      Offset(size.width, size.height * .18),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 22.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double start = -90 * 3.1415926535 / 180;
    final data = [
      const _DonutSlice(.55, Color(0xFF2563EB)),
      const _DonutSlice(.28, Color(0xFFF59E0B)),
      const _DonutSlice(.17, Color(0xFF16A34A)),
    ];

    for (final item in data) {
      final sweep = item.value * 2 * 3.1415926535;
      paint.color = item.color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep - .08, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutSlice {
  final double value;
  final Color color;
  const _DonutSlice(this.value, this.color);
}
