import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../config.dart';

/// Holds the logged-in agent and the API client (which talks to Firebase). Logging out signs
/// out of Firebase too, and the PIN is never stored.
class Session extends ChangeNotifier {
  Session() {
    api.onUnauthorised = () => logout(reason: 'Your session has expired. Please log in again.');
  }

  final ApiClient api = ApiClient();
  Agent? agent;
  String? logoutReason;
  Timer? _idle;

  bool get isLoggedIn => agent != null;

  Future<void> login(String agentId, String pin, String terminalId) async {
    final res = await api.post('/auth/login', {
      'agentId': agentId,
      'pin': pin,
      'terminalId': terminalId,
    }) as Map<String, dynamic>;
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
    _idle = Timer(AppConfig.idleTimeout, () => logout(reason: 'Logged out after 5 minutes without activity.'));
  }

  Future<void> logout({String? reason}) async {
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
