import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../config.dart';

/// Why the agent was logged out without pressing "Log out"; the login screen shows a message.
enum LogoutReason { sessionExpired, idle }

/// Holds the logged-in agent, the API client (which talks to Firebase) and the chosen
/// language. Logging out signs out of Firebase too, and the PIN is never stored.
class Session extends ChangeNotifier {
  Session() {
    api.onUnauthorised = () => logout(reason: LogoutReason.sessionExpired);
    _loadLocale();
  }

  static const _localeKey = 'locale';
  static const supportedLocales = [Locale('en'), Locale('ne')];

  final ApiClient api = ApiClient();
  Agent? agent;
  LogoutReason? logoutReason;
  Locale locale = const Locale('en');
  Timer? _idle;

  bool get isLoggedIn => agent != null;

  Future<void> _loadLocale() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_localeKey);
      if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
        locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {/* keep English */}
  }

  /// Switches the app language and remembers it on this device.
  Future<void> setLocale(Locale value) async {
    if (value == locale) return;
    locale = value;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_localeKey, value.languageCode);
    } catch (_) {/* the choice still applies until the app closes */}
  }

  Future<void> login(String agentId, String pin) async {
    final res = await api.post('/auth/login', {'agentId': agentId, 'pin': pin}) as Map<String, dynamic>;
    api.token = res['token'] as String;
    agent = Agent.fromJson(res['agent'] as Map<String, dynamic>);
    logoutReason = null;
    touch();
    notifyListeners();
  }

  /// Call on every user interaction; logs out after the idle timeout.
  void touch() {
    if (!isLoggedIn) return;
    _idle?.cancel();
    _idle = Timer(AppConfig.idleTimeout, () => logout(reason: LogoutReason.idle));
  }

  Future<void> logout({LogoutReason? reason}) async {
    if (api.token != null && reason == null) {
      try {
        await api.post('/auth/logout');
      } catch (_) {/* logging out locally is enough */}
    }
    _idle?.cancel();
    try {
      await api.signOut();
    } catch (_) {/* already signed out */}
    agent = null;
    logoutReason = reason;
    notifyListeners();
  }
}
