import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

/// The rider's three main tabs, in order.
enum RiderTab { home, activity, account }

/// The bottom navigation bar (ink background, the active tab in the brand colour; the
/// look comes from the theme).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onSelected});

  final RiderTab current;
  final ValueChanged<RiderTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (index) => onSelected(RiderTab.values[index]),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.navActivity,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.navAccount,
        ),
      ],
    );
  }
}
