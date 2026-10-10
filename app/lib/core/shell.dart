import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/gen/app_localizations.dart';
import 'sync_strip.dart';
import 'widgets/widgets.dart';

/// The 5-tab scaffold: হোম · মিল · বাজার · হিসাব · আরও.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// `StatefulShellRoute.navigatorContainerBuilder`: tabs fade through.
  static Widget branchContainer(
    BuildContext context,
    StatefulNavigationShell shell,
    List<Widget> children,
  ) => FadeThroughBranches(index: shell.currentIndex, children: children);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      // Unsent changes are announced app-wide, right above the tabs. The strip
      // floats over the page instead of pushing it (and its + button) up.
      body: Stack(
        children: [
          shell,
          const Align(alignment: Alignment.bottomCenter, child: SyncStrip()),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          AppNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l.navHome,
          ),
          AppNavItem(
            icon: Icons.restaurant_outlined,
            selectedIcon: Icons.restaurant,
            label: l.navMeals,
          ),
          AppNavItem(
            icon: Icons.shopping_basket_outlined,
            selectedIcon: Icons.shopping_basket,
            label: l.navBazar,
          ),
          AppNavItem(
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
            label: l.navMoney,
          ),
          AppNavItem(
            icon: Icons.more_horiz,
            selectedIcon: Icons.more_horiz,
            label: l.navMore,
          ),
        ],
      ),
    );
  }
}
