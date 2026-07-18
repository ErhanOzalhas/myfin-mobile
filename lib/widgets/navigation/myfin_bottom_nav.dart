import 'package:flutter/material.dart';

import '../../screens/intelligence/intelligence_page.dart';
import '../../screens/market/live_market_page.dart';
import '../../screens/market/price_alert_page.dart';
import '../../screens/my_fin_home.dart';
import '../../screens/portfolio/portfolio_page.dart';
import '../../screens/settings/settings_page.dart';
import '../../screens/transactions/transaction_entry_page.dart';
import '../../screens/transactions/transaction_history_page.dart';
import '../../utils/no_animation_route.dart';

enum _TransactionQuickAction { newTransaction, history, priceAlert, liveMarket }

class MyFinBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool allowSelectedDestinationNavigation;

  const MyFinBottomNav({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.allowSelectedDestinationNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) async {
        if (index == 2) {
          final action = await _showTransactionMenu(context);
          if (action == null || !context.mounted) return;
          _openTransactionAction(context, action);
          return;
        }

        if (onDestinationSelected != null) {
          onDestinationSelected!(index);
          return;
        }

        if (index == selectedIndex && !allowSelectedDestinationNavigation) {
          return;
        }

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

  Future<_TransactionQuickAction?> _showTransactionMenu(BuildContext context) {
    return showGeneralDialog<_TransactionQuickAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'İşlem menüsünü kapat',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        final bottomPadding = MediaQuery.paddingOf(dialogContext).bottom;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 88,
              child: Center(
                child: _TransactionMenuBubble(
                  onSelected: (action) {
                    Navigator.of(dialogContext).pop(action);
                  },
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            alignment: Alignment.bottomCenter,
            scale: Tween<double>(begin: .94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _openTransactionAction(
    BuildContext context,
    _TransactionQuickAction action,
  ) {
    switch (action) {
      case _TransactionQuickAction.newTransaction:
        if (onDestinationSelected != null) {
          onDestinationSelected!(2);
          return;
        }
        _openRoot(context, const TransactionEntryPage());
      case _TransactionQuickAction.history:
        Navigator.of(context).push(
          noAnimationRoute(builder: (_) => const TransactionHistoryPage()),
        );
      case _TransactionQuickAction.priceAlert:
        Navigator.of(
          context,
        ).push(noAnimationRoute(builder: (_) => const PriceAlertPage()));
      case _TransactionQuickAction.liveMarket:
        Navigator.of(
          context,
        ).push(noAnimationRoute(builder: (_) => const LiveMarketPage()));
    }
  }

  void _openRoot(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      noAnimationRoute(builder: (_) => page),
      (route) => false,
    );
  }
}

class _TransactionMenuBubble extends StatelessWidget {
  final ValueChanged<_TransactionQuickAction> onSelected;

  const _TransactionMenuBubble({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 14,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: .18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFDCE5EF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 244,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TransactionMenuItem(
              icon: Icons.add_circle_outline_rounded,
              label: 'Yeni İşlem',
              color: const Color(0xFF0284C7),
              onTap: () => onSelected(_TransactionQuickAction.newTransaction),
            ),
            const Divider(height: 1, indent: 52, endIndent: 12),
            _TransactionMenuItem(
              icon: Icons.history_rounded,
              label: 'İşlem Geçmişi',
              color: const Color(0xFF16A34A),
              onTap: () => onSelected(_TransactionQuickAction.history),
            ),
            const Divider(height: 1, indent: 52, endIndent: 12),
            _TransactionMenuItem(
              icon: Icons.notifications_active_rounded,
              label: 'Fiyat Alarmı',
              color: const Color(0xFF7C3AED),
              onTap: () => onSelected(_TransactionQuickAction.priceAlert),
            ),
            const Divider(height: 1, indent: 52, endIndent: 12),
            _TransactionMenuItem(
              icon: Icons.show_chart_rounded,
              label: 'Canlı Piyasa',
              color: const Color(0xFF0F75BD),
              onTap: () => onSelected(_TransactionQuickAction.liveMarket),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TransactionMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 13),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
