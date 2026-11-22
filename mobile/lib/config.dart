/// App-wide settings. The app talks straight to Firebase (see firebase_options.dart), so
/// there is no server address to configure.
class AppConfig {
  /// Logs the agent out after this long without any touch (NFR-6).
  static const Duration idleTimeout = Duration(minutes: 5);

  // Display-only copies of the rules in api/api_client.dart; Firestore security rules re-check them.
  static const double minAmount = 100;
  static const double maxAmount = 25000;
  static const double withdrawalFee = 10;
  static const double depositFee = 0;
}
