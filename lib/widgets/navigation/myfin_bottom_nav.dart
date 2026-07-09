import 'package:flutter/material.dart';
import '../../screens/intelligence/intelligence_page.dart';
import '../../screens/my_fin_home.dart';
import '../../screens/portfolio/portfolio_page.dart';
class MyFinBottomNav extends StatelessWidget {
  final int selectedIndex;

  const MyFinBottomNav({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) return;

        if (index == 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyFinHome()),
            (route) => false,
          );
          return;
        }

        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PortfolioPage()),
          );
          return;
        }

        if (index == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionEntryPage()),
          );
          return;
        }

        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IntelligencePage()),
          );
          return;
        }

        if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_rounded),
          label: 'Ana Sayfa',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_rounded),
          label: 'Portföy',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          label: 'Yeni İşlem',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_graph_rounded),
          label: 'Analiz',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          label: 'Ayarlar',
        ),
      ],
    );
  }
}