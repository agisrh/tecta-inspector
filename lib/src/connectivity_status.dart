import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class to check for internet connectivity.
class ConnectivityStatus {
  /// Checks if the device has a working network connection.
  ///
  /// This method performs a DNS lookup on 'google.com' to verify
  /// actual internet reachability (except on Flutter Web, where it assumes true).
  static Future<bool> hasNetwork() async {
    if (kIsWeb) {
      return true;
    }
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
