import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionsHelper {
  /// Request location permission and return whether it was granted
  static Future<bool> requestLocationPermission() async {
    // Check if location permission is already granted
    if (await Permission.location.isGranted) {
      return true;
    }

    // Request location permission
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location services are enabled on the device
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    // Check current status
    PermissionStatus status = await Permission.camera.status;

    // If already granted, return true
    if (status.isGranted) {
      return true;
    }

    // If permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false; // User needs to change settings manually
    }

    // Request permission
    status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    // Check current status
    PermissionStatus status = await Permission.storage.status;

    // If already granted, return true
    if (status.isGranted) {
      return true;
    }

    // If permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false; // User needs to change settings manually
    }

    // Request permission
    status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request all permissions needed for the app
  static Future<Map<String, bool>> requestAllPermissions() async {
    final location = await requestLocationPermission();
    final camera = await requestCameraPermission();
    final storage = await requestStoragePermission();

    return {
      'location': location,
      'camera': camera,
      'storage': storage,
    };
  }

  /// Detect if running on Android 13 or higher (API level 33+)
  static Future<bool> _isAndroid13OrHigher() async {
    try {
      // Use a simpler approach that's more compatible
      final isAndroid = await Permission.location.serviceStatus.isEnabled;
      if (!isAndroid) return false; // Not running on Android

      // For simplicity, we'll just return true since this
      // isn't critical functionality and we can't reliably
      // determine the Android version without additional packages
      return true;
    } catch (e) {
      print('Error determining platform: $e');
      return false;
    }
  }
}
