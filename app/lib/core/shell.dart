import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/gen/app_localizations.dart';
import 'widgets/widgets.dart';

/// The 5-tab scaffold: হোম · মিল · বাজার · হিসাব · আরও.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.palette.border)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.restaurant_outlined),
              selectedIcon: const Icon(Icons.restaurant),
              label: l.navMeals,
            ),
            NavigationDestination(
              icon: const Icon(Icons.shopping_basket_outlined),
              selectedIcon: const Icon(Icons.shopping_basket),
              label: l.navBazar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet),
              label: l.navMoney,
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              selectedIcon: const Icon(Icons.more_horiz),
              label: l.navMore,
            ),
          ],
        ),
      ),
    );
  }
}
