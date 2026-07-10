import 'package:flutter/material.dart';

import '../../screens/intelligence/intelligence_page.dart';
import '../../screens/my_fin_home.dart';
import '../../screens/portfolio/portfolio_page.dart';
import '../../screens/settings/settings_page.dart';
import '../../screens/transactions/transaction_entry_page.dart';
import '../../utils/no_animation_route.dart';
class MyFinBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  const MyFinBottomNav({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (onDestinationSelected != null) {
          onDestinationSelected!(index);
          return;
        }

        if (index == selectedIndex) return;

        final Widget page = switch (index) {
          0 => const MyFinHome(),
          1 => const PortfolioPage(),
          2 => const TransactionEntryPage(),
          3 => const IntelligencePage(),
          4 => const SettingsPage(),
          _ => const MyFinHome(),
        };

        Navigator.of(context).pushAndRemoveUntil(
          noAnimationRoute(builder: (_) => page),
          (route) => false,
        );
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
          label: 'İşlem',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_rounded),
          label: 'AI',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          label: 'Ayarlar',
        ),
      ],
    );
  }
}