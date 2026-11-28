import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/widgets/brand_mark.dart';
import '../auth/application/auth_controller.dart';
import '../workout/discard_guard.dart';

const _tabs = [
  (label: 'Home', icon: Icons.home_outlined, selected: Icons.home),
  (label: 'Quests', icon: Icons.flag_outlined, selected: Icons.flag),
  (
    label: 'Ranking',
    icon: Icons.emoji_events_outlined,
    selected: Icons.emoji_events,
  ),
  (
    label: 'Rewards',
    icon: Icons.card_giftcard_outlined,
    selected: Icons.card_giftcard,
  ),
];

/// Navigation around the main pages: a bottom bar on phones, a side rail on
/// larger screens.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  // Tapping the current tab again returns to its first page.
  Future<void> _open(BuildContext context, WidgetRef ref, int index) async {
    final again = index == shell.currentIndex;
    // The workout lives under Home, so only Home again would discard it.
    if (again && index == 0 && !await confirmDiscard(context, ref)) return;
    shell.goBranch(index, initialLocation: again);
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authControllerProvider.notifier);
    if (await confirmDiscard(context, ref)) await auth.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rail = Breakpoints.useRail(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wideRail;

    return Scaffold(
      body: Row(
        children: [
          if (rail)
            NavigationRail(
              extended: wide,
              minExtendedWidth: 220,
              labelType: wide
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => _open(context, ref, index),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(radius: 18),
                    if (wide) ...const [
                      SizedBox(width: 10),
                      Text(
                        'Overcise',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Log out',
                      icon: const Icon(Icons.logout),
                      onPressed: () => _logOut(context, ref),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final tab in _tabs)
                  NavigationRailDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selected),
                    label: Text(tab.label),
                  ),
              ],
            ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: rail
          ? null
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => _open(context, ref, index),
              destinations: [
                for (final tab in _tabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selected),
                    label: tab.label,
                  ),
              ],
            ),
    );
  }
}
