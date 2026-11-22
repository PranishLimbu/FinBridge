import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide settings.
///
/// The API address can be changed at build time:
///   flutter run --dart-define=API_URL=http://192.168.1.20:4000/api
/// Without it, the browser uses localhost and everything else uses 10.0.2.2,
/// which is how the Android emulator reaches the computer it runs on.
class AppConfig {
  static const String _apiUrlOverride = String.fromEnvironment('API_URL');

  static String get apiUrl => _apiUrlOverride.isNotEmpty
      ? _apiUrlOverride
      : (kIsWeb ? 'http://localhost:4000/api' : 'http://10.0.2.2:4000/api');

  /// Logs the agent out after this long without any touch (NFR-6).
  static const Duration idleTimeout = Duration(minutes: 5);

  // Display-only copies of the server rules. The server always re-checks them.
  static const double minAmount = 100;
  static const double maxAmount = 25000;
  static const double withdrawalFee = 10;
  static const double depositFee = 0;
}
