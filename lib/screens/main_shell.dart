import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../services/app_startup_coordinator.dart';
import '../services/price_alert_service.dart';
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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const MyFinHome(showBottomNav: false),
    const PortfolioPage(showBottomNav: false),
    const TransactionEntryPage(showBottomNav: false),
    const IntelligencePage(showBottomNav: false),
    const SettingsPage(showBottomNav: false),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStartupCoordinator.instance.preloadSecondary();
      PriceAlertService.instance.checkNow();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PriceAlertService.instance.checkNow();
    }
  }

  void _selectPage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.data == null) return const LoginPage();
        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: MyFinBottomNav(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
          ),
        );
      },
    );
  }
}
