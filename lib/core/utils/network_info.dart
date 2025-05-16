import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility class to check network connectivity
class NetworkInfo {
  final Connectivity connectivity;

  NetworkInfo(this.connectivity);

  /// Checks if the device is currently connected to the internet
  Future<bool> get isConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
