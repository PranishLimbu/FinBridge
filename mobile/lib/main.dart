import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/session.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Session(),
      child: const FinBridgeApp(),
    ),
  );
}

class FinBridgeApp extends StatelessWidget {
  const FinBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return Listener(
      // Any touch resets the 5-minute idle timer.
      onPointerDown: (_) => session.touch(),
      child: MaterialApp(
        title: 'FinBridge Agent',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Rebuilding with a new key on login/logout clears every pushed screen.
        home: session.isLoggedIn
            ? HomeShell(key: ValueKey(session.agent!.id))
            : const LoginScreen(),
      ),
    );
  }
}
