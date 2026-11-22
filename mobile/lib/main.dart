import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/supervisor_screen.dart';
import 'state/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Balances must always come from the server, never from an offline copy on the phone.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
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
        home: !session.isLoggedIn
            ? const LoginScreen()
            : session.agent!.role == 'supervisor'
                ? SupervisorScreen(key: ValueKey(session.agent!.id))
                : HomeShell(key: ValueKey(session.agent!.id)),
      ),
    );
  }
}
