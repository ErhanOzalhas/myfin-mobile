import 'package:flutter/material.dart';

import '../widgets/navigation/myfin_bottom_nav.dart';
import 'intelligence/intelligence_page.dart';
import 'my_fin_home.dart';
import 'portfolio/portfolio_page.dart';
import 'settings/settings_page.dart';
import 'transactions/transaction_entry_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const MyFinHome(showBottomNav: false),
    const PortfolioPage(showBottomNav: false),
    const TransactionEntryPage(showBottomNav: false),
    const IntelligencePage(showBottomNav: false),
    const SettingsPage(showBottomNav: false),
  ];

  void _selectPage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: MyFinBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
      ),
    );
  }
}