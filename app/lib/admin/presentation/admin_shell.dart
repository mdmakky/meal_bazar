import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/application/auth_providers.dart';
import 'admin_app.dart';
import 'ai_page.dart';
import 'branding_page.dart';
import 'credentials_page.dart';
import 'dashboard_page.dart';
import 'messes_users_pages.dart';
import 'settings_page.dart';

typedef _Dest = ({IconData icon, String label, Widget page});

/// NavigationRail at ≥ 900 px, a drawer below.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  List<_Dest> _destinations(AppLocalizations l) => [
    (
      icon: Icons.space_dashboard_outlined,
      label: l.adminNavDashboard,
      page: const DashboardPage(),
    ),
    (
      icon: Icons.home_work_outlined,
      label: l.adminNavMesses,
      page: const MessesPage(),
    ),
    (
      icon: Icons.people_outline,
      label: l.adminNavUsers,
      page: const UsersPage(),
    ),
    (icon: Icons.tune, label: l.adminNavSettings, page: const SettingsPage()),
    (
      icon: Icons.auto_awesome_outlined,
      label: l.adminNavAi,
      page: const AiPage(),
    ),
    (
      icon: Icons.palette_outlined,
      label: l.adminNavBranding,
      page: const BrandingPage(),
    ),
    (
      icon: Icons.key_outlined,
      label: l.adminNavCredentials,
      page: const CredentialsPage(),
    ),
    (
      icon: Icons.delete_sweep_outlined,
      label: l.adminNavDeletion,
      page: const DeletionQueuePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dests = _destinations(l);
    final signOut = IconButton(
      tooltip: l.adminSignOut,
      icon: const Icon(Icons.logout),
      onPressed: () => ref.read(authRepositoryProvider).signOut(),
    );
    final page = KeyedSubtree(key: ValueKey(_index), child: dests[_index].page);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: c.maxWidth >= 1200,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: c.maxWidth >= 1200
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Text(
                      l.adminTitleShort,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [const LocaleToggle(), signOut],
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final d in dests)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(dests[_index].label),
            actions: [const LocaleToggle(), signOut],
          ),
          drawer: NavigationDrawer(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              setState(() => _index = i);
              Navigator.pop(context);
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Text(
                  l.adminTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final d in dests)
                NavigationDrawerDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          body: page,
        );
      },
    );
  }
}
