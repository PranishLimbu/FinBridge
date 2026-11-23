import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'customer_search_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'terminal_screen.dart';

/// Bottom navigation from the prototype: Counter | Customers | Journal | Terminal.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _journalKey = GlobalKey<JournalScreenState>();

  void _go(int i) {
    setState(() => _index = i);
    if (i == 0) _dashboardKey.currentState?.refresh();
    if (i == 2) _journalKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      DashboardScreen(key: _dashboardKey, onOpenTab: _go),
      const CustomerSearchScreen(),
      JournalScreen(key: _journalKey),
      const TerminalScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.point_of_sale), label: l10n.tabCounter),
          NavigationDestination(icon: const Icon(Icons.people_alt_outlined), label: l10n.tabCustomers),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l10n.tabJournal),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.tabTerminal),
        ],
      ),
    );
  }
}
