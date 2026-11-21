/// App-wide settings.
///
/// The API address can be changed at build time:
///   flutter run --dart-define=API_URL=http://192.168.1.20:4000/api
/// 10.0.2.2 is how the Android emulator reaches the computer it runs on.
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  /// Logs the agent out after this long without any touch (NFR-6).
  static const Duration idleTimeout = Duration(minutes: 5);

  // Display-only copies of the server rules. The server always re-checks them.
  static const double minAmount = 100;
  static const double maxAmount = 25000;
  static const double withdrawalFee = 10;
  static const double depositFee = 0;
}
