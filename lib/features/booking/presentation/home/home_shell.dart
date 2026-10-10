import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design/components/components.dart';
import '../legacy_routes.dart';
import 'home_tab.dart';

/// The signed-in app: home, activity and account behind the bottom bar. Only the open
/// tab is built, so the others load nothing until they are opened.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  RiderTab _tab = RiderTab.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        resumeActiveTrip(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padded: false,
      bottomNavigation: AppBottomNav(
        current: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
      body: switch (_tab) {
        RiderTab.home => const HomeTab(),
        RiderTab.activity => legacyActivityTab(),
        RiderTab.account => legacyAccountTab(),
      },
    );
  }
}
