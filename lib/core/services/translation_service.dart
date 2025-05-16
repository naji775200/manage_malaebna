import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;

  TranslationService._internal();

  Map<String, dynamic> _enTranslations = {};
  Map<String, dynamic> _arTranslations = {};
  bool _isInitialized = false;
  Locale _currentLocale = const Locale('en');

  Future<void> init() async {
    if (_isInitialized) return;

    final enJson = await rootBundle.loadString('assets/translations/en.json');
    final arJson = await rootBundle.loadString('assets/translations/ar.json');

    _enTranslations = json.decode(enJson);
    _arTranslations = json.decode(arJson);
    _isInitialized = true;
  }

  // Set the current locale
  void setCurrentLocale(Locale locale) {
    _currentLocale = locale;
  }

  String translate(String key,
      [Map<String, dynamic>? args, BuildContext? context]) {
    if (!_isInitialized) {
      return key;
    }

    // Determine language based on context or default to current locale
    final locale =
        context != null ? Localizations.localeOf(context) : _currentLocale;

    final isArabic = locale.languageCode == 'ar';
    final translations = isArabic ? _arTranslations : _enTranslations;

    // Split the key by dots to navigate through nested maps
    final parts = key.split('.');
    dynamic value = translations;

    for (final part in parts) {
      if (value is Map && value.containsKey(part)) {
        value = value[part];
      } else {
        return key; // Key not found
      }
    }

    if (value is String) {
      // Replace placeholders with args if provided
      if (args != null) {
        String result = value;
        args.forEach((argKey, argValue) {
          result = result.replaceAll('{$argKey}', argValue.toString());
        });
        return result;
      }
      return value;
    }

    return key; // If value is not a string, return original key
  }

  // Short form for easier access
  String tr(String key, [Map<String, dynamic>? args, BuildContext? context]) {
    return translate(key, args, context);
  }

  // Get current locale
  Locale getCurrentLocale() {
    return _currentLocale;
  }

  // Check if current locale is RTL
  bool isRtl([BuildContext? context]) {
    final locale =
        context != null ? Localizations.localeOf(context) : _currentLocale;
    return locale.languageCode == 'ar';
  }
}

// Create a global instance for easy access
final translationService = TranslationService();
