import 'package:connectivity_plus/connectivity_plus.dart';

/// Centralized internet connectivity check for auth and critical flows.
/// Throws [Exception] with a user-friendly message if there is no connectivity.
class ConnectivityHelper {
  ConnectivityHelper._();

  static const String noInternetMessage =
      'No internet connection. Please check your network and try again.';

  /// Throws [Exception] if device has no internet connectivity.
  /// Call this before auth API calls (login, signup, verify OTP, etc.) to avoid
  /// proceeding with no network and ensure we never show stale/previous account.
  static Future<void> ensureConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.isNotEmpty &&
        results.any((r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet);
    if (!hasConnection) {
      throw Exception(noInternetMessage);
    }
  }
}
