import '../../logic/map/map_event.dart'; // For LatLng class
import '../../core/utils/permissions_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/services/localization_service.dart';

class MapRepository {
  final LocalizationService _localizationService = LocalizationService();

  // Check if location permission is granted
  Future<bool> checkLocationPermission() async {
    return await PermissionsHelper.requestLocationPermission();
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    return await PermissionsHelper.requestLocationPermission();
  }

  // Get current device location
  Future<LatLng> getCurrentLocation() async {
    try {
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting current location: $e");
      // Fall back to a default location in Riyadh if there's an error
      return const LatLng(24.774265, 46.738586);
    }
  }

  // Get address details from latitude and longitude
  Future<Map<String, String?>> getAddressFromLocation(LatLng location) async {
    try {
      // Get current app locale for proper localization
      final String languageCode =
          _localizationService.currentLocale.languageCode;

      // Get placemarks - unfortunately, geocoding package doesn't directly support
      // locale specification in the API, so we'll handle the language at display time
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print("DEBUG Placemark ($languageCode): ${place.toString()}");

        // Extract address fields
        Map<String, String?> addressFields = {
          'country': place.country,
          // Use locality as city, fallback to administrativeArea
          'city': place.locality?.isNotEmpty == true
              ? place.locality
              : place.administrativeArea,
          // Use subLocality as district, fallback to subAdministrativeArea
          'district': place.subLocality?.isNotEmpty == true
              ? place.subLocality
              : place.subAdministrativeArea,
        };

        // Attempt to translate fields if needed
        return _translateAddressFields(addressFields, languageCode);
      }

      // Default values if no placemark found
      return _getDefaultAddressValues(languageCode);
    } catch (e) {
      print("Error getting address from location: $e");
      // Get the language code again inside the catch block to avoid undefined reference
      final String languageCode =
          _localizationService.currentLocale.languageCode;
      return _getErrorAddressValues(languageCode);
    }
  }

  // Translate address fields based on language
  Map<String, String?> _translateAddressFields(
      Map<String, String?> fields, String languageCode) {
    // We'll attempt to translate common location names
    if (languageCode == 'ar') {
      // Translate to Arabic for common known values
      Map<String, String> commonTranslations = {
        // Countries
        'Saudi Arabia': 'المملكة العربية السعودية',
        'United Arab Emirates': 'الإمارات العربية المتحدة',
        'Qatar': 'قطر',
        'Kuwait': 'الكويت',
        'Bahrain': 'البحرين',
        'Oman': 'عمان',
        // Cities
        'Riyadh': 'الرياض',
        'Jeddah': 'جدة',
        'Dammam': 'الدمام',
        'Mecca': 'مكة المكرمة',
        'Medina': 'المدينة المنورة',
        'Dubai': 'دبي',
        'Abu Dhabi': 'أبوظبي',
        'Doha': 'الدوحة',
        'Kuwait City': 'مدينة الكويت',
        'Manama': 'المنامة',
        'Muscat': 'مسقط',
      };

      // Try to translate each field if it exists in our translation map
      fields.forEach((key, value) {
        if (value != null && commonTranslations.containsKey(value)) {
          fields[key] = commonTranslations[value];
        }
      });
    } else if (languageCode != 'en') {
      // For other languages, we could potentially translate to English
      // This would require a more comprehensive translation map
      // For now, we just keep the original values
    }

    return fields;
  }

  // Get default address values for when no placemark is found
  Map<String, String?> _getDefaultAddressValues(String languageCode) {
    return {
      'country': languageCode == 'ar' ? 'غير معروف' : 'Unknown',
      'city': languageCode == 'ar' ? 'غير معروف' : 'Unknown',
      'district': languageCode == 'ar' ? 'غير معروف' : 'Unknown',
    };
  }

  // Get error address values for when geocoding fails
  Map<String, String?> _getErrorAddressValues(String languageCode) {
    final String errorText = languageCode == 'ar' ? 'خطأ' : 'Error';

    return {
      'country': errorText,
      'city': errorText,
      'district': errorText,
    };
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await PermissionsHelper.isLocationServiceEnabled();
  }

  // Get last known location as a fallback
  Future<LatLng?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
      return null;
    } catch (e) {
      print("Error getting last known location: $e");
      return null;
    }
  }
}
