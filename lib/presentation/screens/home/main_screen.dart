import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/navigation/navigation_bloc.dart';
import '../../../logic/navigation/navigation_state.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../routes/app_routes.dart';
import 'home_screen.dart';
import '../profile/profile_stadium_screen.dart';
import '../fields/fields_screen.dart';
import '../match_requests/match_requests_screen.dart';
import '../payment/payment_screen.dart';
import '../notifications/notification_screen.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../core/services/translation_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => NavigationBloc(),
        ),
        BlocProvider(
          create: (context) => AuthBloc()..add(const AuthInitialEvent()),
        ),
      ],
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(_getAppBarTitle(context, navState.selectedIndex)),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // Navigate to notification screen using our routes system with slide animation
                        AppRoutes.slideInRoute(
                          context,
                          const NotificationScreen(),
                        );
                      },
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // Main content area with screens
                    Expanded(
                      child: _buildSelectedScreen(navState.selectedIndex),
                    ),
                  ],
                ),
                bottomNavigationBar: const CustomBottomNavigation(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FieldsScreen();
      case 2:
        return const MatchRequestsScreen();
      case 3:
        return const PaymentScreen(amount: 0.0);
      case 4:
        return const ProfileStadiumScreen();
      default:
        return const HomeScreen();
    }
  }

  String _getAppBarTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return translationService.tr('app.name', {}, context);
      case 1:
        return translationService.tr('navigation.fields', {}, context);
      case 2:
        return translationService.tr('navigation.requests', {}, context);
      case 3:
        return translationService.tr('navigation.payment', {}, context);
      case 4:
        return translationService.tr('navigation.profile', {}, context);
      default:
        return translationService.tr('app.name', {}, context);
    }
  }
}
