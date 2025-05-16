import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/verification_screen.dart';
import '../screens/auth/check_business_screen.dart';
import '../screens/auth/check_update.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';

// Main app screens
import '../screens/home/main_screen.dart';
import '../screens/profile/profile_stadium_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/working_hours/working_hours_screen.dart';
import '../screens/match_requests/match_requests_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/profile/edit_profile_stadium_screen.dart';
import '../screens/prices_coupons/prices_coupons_screen.dart';

// Repositories

class AppRoutes {
  // Route names
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String verification = '/verification';
  static const String main = '/main';
  static const String home = '/home';
  static const String matches = '/matches';
  static const String matchRequests = '/match-requests';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String stadium = '/stadium';
  static const String stadiumProfile = '/stadium-profile';
  static const String workingHours = '/working-hours';
  static const String pricesCoupons = '/prices-coupons';
  static const String checkBusiness = '/check-business';
  static const String checkUpdate = '/check-update';

  // Route map for simple routes
  static Map<String, WidgetBuilder> get routes => {
        login: (context) => BlocProvider(
              create: (context) => AuthBloc()..add(const AuthInitialEvent()),
              child: const LoginScreen(),
            ),
        verification: (context) => BlocProvider(
              create: (context) => AuthBloc()..add(const AuthInitialEvent()),
              child: const VerificationScreen(),
            ),
        main: (context) => const MainScreen(),
        profile: (context) => const ProfileStadiumScreen(),
        onboarding: (context) => const OnboardingScreen(),
        checkBusiness: (context) => const CheckBusinessScreen(),
        checkUpdate: (context) => const CheckUpdateScreen(),
      };

  // For routes that need parameters
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case verification:
        // Example of passing arguments to a route
        // final args = settings.arguments as VerificationArguments;
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => AuthBloc()..add(const AuthInitialEvent()),
            child: const VerificationScreen(),
          ),
          fullscreenDialog: true,
        );

      default:
        // If no match is found, go to login
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => AuthBloc()..add(const AuthInitialEvent()),
            child: const LoginScreen(),
          ),
          fullscreenDialog: true,
        );
    }
  }

  // Helper methods for common navigation tasks
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      login,
      (route) => false, // Removes all previous routes
    );
  }

  static void navigateToMain(BuildContext context) {
    print('Navigating to main screen...');
    // Try named route navigation first
    try {
      Navigator.pushNamedAndRemoveUntil(
        context,
        main,
        (route) => false, // Removes all previous routes
      );
    } catch (e) {
      // If named route fails, try direct navigation
      print('Named route navigation failed, using direct navigation: $e');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  static void navigateToVerification(BuildContext context,
      {String? phoneNumber}) {
    Navigator.pushNamed(
      context,
      verification,
      arguments: phoneNumber != null ? {'phoneNumber': phoneNumber} : null,
    );
  }

  // Navigation helper to preserve existing auth bloc
  static void navigateToVerificationWithBloc(
      BuildContext context, AuthBloc authBloc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: authBloc,
          child: const VerificationScreen(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper to preserve existing auth bloc with slide animation
  static void slideToVerificationWithBloc(
      BuildContext context, AuthBloc authBloc) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BlocProvider.value(
          value: authBloc,
          child: const VerificationScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with transitions
  static Future<T?> slideInRoute<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Fade transition
  static Future<T?> fadeInRoute<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper for stadium profile
  static void navigateToStadiumProfile(BuildContext context,
      {String? stadiumId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileStadiumScreen(stadiumId: stadiumId),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with slide animation for stadium profile
  static void slideToStadiumProfile(BuildContext context, {String? stadiumId}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileStadiumScreen(stadiumId: stadiumId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper for prices and coupons
  static void navigateToPricesCoupons(
    BuildContext context, {
    required String stadiumId,
    required String stadiumName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricesCouponsScreen(
          stadiumId: stadiumId,
          stadiumName: stadiumName,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with slide animation for prices and coupons
  static void slideToPricesCoupons(
    BuildContext context, {
    required String stadiumId,
    required String stadiumName,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PricesCouponsScreen(
          stadiumId: stadiumId,
          stadiumName: stadiumName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper for working hours
  static Future<void> navigateToWorkingHours(BuildContext context,
      {String? stadiumId, required String stadiumName}) async {
    // If stadiumId is not provided, try to get it from shared preferences
    final String effectiveStadiumId =
        stadiumId ?? await WorkingHoursScreen.getStadiumIdFromPrefs() ?? '';

    if (effectiveStadiumId.isEmpty) {
      // Show error if stadium ID could not be retrieved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine stadium ID. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingHoursScreen(
          stadiumId: effectiveStadiumId,
          stadiumName: stadiumName,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with slide animation for working hours
  static Future<void> slideToWorkingHours(BuildContext context,
      {String? stadiumId, required String stadiumName}) async {
    // If stadiumId is not provided, try to get it from shared preferences
    final String effectiveStadiumId =
        stadiumId ?? await WorkingHoursScreen.getStadiumIdFromPrefs() ?? '';

    if (effectiveStadiumId.isEmpty) {
      // Show error if stadium ID could not be retrieved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine stadium ID. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkingHoursScreen(
          stadiumId: effectiveStadiumId,
          stadiumName: stadiumName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation to payment screen
  static void navigateToPayment(BuildContext context,
      {required double amount}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(amount: amount),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with slide animation for payment
  static void slideToPayment(BuildContext context, {required double amount}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PaymentScreen(amount: amount),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper for stadium profile edit
  static void navigateToStadiumProfileEdit(BuildContext context,
      {String? stadiumId}) {
    print("DEBUG: Navigating to profile edit with stadiumId: $stadiumId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileStadiumScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with slide animation for stadium profile edit
  static void slideToStadiumProfileEdit(BuildContext context,
      {String? stadiumId}) {
    print("DEBUG: Slide navigating to profile edit with stadiumId: $stadiumId");
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EditProfileStadiumScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        // Disable hero animations to prevent conflicts
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper for match requests
  static void navigateToMatchRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchRequestsScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation with slide animation for match requests
  static void slideToMatchRequests(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MatchRequestsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        fullscreenDialog: true,
      ),
    );
  }

  // Navigation helper for check update screen
  static void navigateToCheckUpdate(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      checkUpdate,
      (route) => false, // Removes all previous routes
    );
  }

  // Navigation with slide animation for check update screen
  static void slideToCheckUpdate(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CheckUpdateScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        fullscreenDialog: true,
      ),
    );
  }
}
