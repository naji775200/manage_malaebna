import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import '../../routes/app_routes.dart';
import '../../../logic/auth/auth_bloc.dart';

class CheckBusinessScreen extends StatelessWidget {
  const CheckBusinessScreen({Key? key}) : super(key: key);

  void _onContinue(BuildContext context) {
    // Navigate to login or main screen based on authentication status
    final authState = context.read<AuthBloc>().state;
    if (authState.isAuthenticated) {
      AppRoutes.navigateToMain(context);
    } else {
      AppRoutes.navigateToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Settings row (language and theme)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings area (language and theme)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Language switcher
                        const LanguageSwitcher(showText: false),

                        // Divider
                        Container(
                          height: 24,
                          width: 1,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),

                        // Theme switcher
                        const ThemeSwitcher(),
                      ],
                    ),
                  ),

                  // Empty container to balance the row
                  Container(),
                ],
              ),
            ),

            // Main content area
            Expanded(
              flex: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image
                    Image.asset(
                      'assets/images/check_business.png',
                      height: size.height * 0.3,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      translationService.tr(
                          'auth.check_business.title', {}, context),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      translationService.tr(
                          'auth.check_business.description', {}, context),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onBackground.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onContinue(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(
                    translationService.tr('common.continue', {}, context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
