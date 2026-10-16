import 'package:flutter/material.dart';

import '../../../../design/components/components.dart';
import '../../../home/presentation/home_screen.dart';
import '../legacy_routes.dart';

/// The signed-in app: home, activity and account behind the bottom bar. Only the open
/// tab is built, so the others load nothing until they are opened.
///
/// A ride under way shows on top of the home; the rider opens it from there.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  RiderTab _tab = RiderTab.home;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padded: false,
      bottomNavigation: AppBottomNav(
        current: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
      body: switch (_tab) {
        RiderTab.home => const HomeScreen(),
        RiderTab.activity => legacyActivityTab(),
        RiderTab.account => legacyAccountTab(),
      },
    );
  }
}
