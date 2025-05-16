import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/migration_helper.dart';
import 'translation_service.dart';

class LocalizationService {
  // Singleton instance
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  // Locale and translations
  Locale _locale = const Locale('en');
  Map<String, dynamic> _localizedValues = {};

  bool _isInitialized = false;

  // Getters
  Locale get currentLocale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  // Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Get saved language or use device language
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(AppConstants.languageKey);

    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
    }

    // Notify the translation service about the current locale
    translationService.setCurrentLocale(_locale);
  }

  // Change language
  Future<bool> changeLanguage(String languageCode) async {
    try {
      _locale = Locale(languageCode);

      // Save the selected language
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.languageKey, languageCode);

      // Notify the translation service about the locale change
      translationService.setCurrentLocale(_locale);

      return true;
    } catch (e) {
      debugPrint('Error changing language: $e');
      return false;
    }
  }

  // Load translations from JSON files
  Future<void> _loadTranslations(String languageCode) async {
    try {
      String jsonStringValues = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      _localizedValues = json.decode(jsonStringValues);
    } catch (e) {
      // If file not found or parsing error, use empty map
      _localizedValues = {};
      debugPrint('Error loading translations: $e');
    }
  }

  // Get a translation by key
  String translate(String key, [Map<String, dynamic>? args]) {
    // Delegate to the translation service with the current locale
    return translationService.translate(key, args);
  }

  // Get current application locale - useful for the app's localization
  Locale getCurrentLocale() {
    // Default to English if not initialized yet
    return const Locale('en');
  }
}

// Extension to get translations easily from BuildContext
extension TranslationExtension on BuildContext {
  String tr(String key, [Map<String, dynamic>? args]) {
    // Show a warning in debug mode to help with migration
    assert(() {
      MigrationHelper.warnContextUsage(key, this);
      return true;
    }());

    // Use our global translation service now
    return translationService.tr(key, args, this);
  }
}
