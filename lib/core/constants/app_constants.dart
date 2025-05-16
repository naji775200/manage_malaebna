enum AppLanguage {
  english,
  arabic,
}

enum AppThemeMode {
  light,
  dark,
  system,
}

class AppConstants {
  // Shared Preferences keys
  static const String selectedLanguage = 'selected_language';
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String onboardingCompleted = 'onboarding_completed';

  // API related
  static const int apiConnectTimeout = 10000; // milliseconds
  static const int apiReceiveTimeout = 10000; // milliseconds

  // Supabase configuration
  static const String supabaseUrl = 'https://dqnwsfweewqaizcszyof.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxbndzZndlZXdxYWl6Y3N6eW9mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NjE4NDAsImV4cCI6MjA1OTQzNzg0MH0.t-FscfesjBqPcsYuHqNjZL9_3FAedwcQPZbTW58elZE';

  // Map related
  static const String mapAPIKey = 'AIzaSyBg0iEXruxElErZVP-vE-uVQNuBKrfWlrs';

  // File paths
  static const String translationsPath = 'assets/translations';
  static const String imagesPath = 'assets/images';

  // Feature flags
  static const bool enableMapFeatures = true;
  static const bool enableNotifications = true;

  // App information
  static const String appName = 'Managae Malaebna';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Stadium carousel auto-advance interval
  static const int carouselAdvanceInterval = 3000; // milliseconds

  static const String defaultLanguage =
      'ar'; // This will be used as fallback only
  static const String defaultTheme = 'system'; // Default to system theme

  static const Map<AppLanguage, String> languageCodes = {
    AppLanguage.english: 'en',
    AppLanguage.arabic: 'ar',
  };

  static const Map<String, AppLanguage> languageFromCode = {
    'en': AppLanguage.english,
    'ar': AppLanguage.arabic,
  };

  // Add the language key
  static const String languageKey = 'selected_language';
}
