import 'package:flutter/material.dart';

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

  void _go(int i) {
    setState(() => _index = i);
    if (i == 0) _dashboardKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(key: _dashboardKey, onOpenTab: _go),
      const CustomerSearchScreen(),
      const JournalScreen(),
      const TerminalScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Counter'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Terminal'),
        ],
      ),
    );
  }
}
