import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import '../../routes/app_routes.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../widgets/custom_button.dart';

class CheckUpdateScreen extends StatelessWidget {
  const CheckUpdateScreen({Key? key}) : super(key: key);

  void _onContinue(BuildContext context) {
    // Navigate to login or main screen based on authentication status
    final authState = context.read<AuthBloc>().state;
    if (authState.isAuthenticated) {
      AppRoutes.navigateToMain(context);
    } else {
      AppRoutes.navigateToLogin(context);
    }
  }

  void _onUpdate(BuildContext context) {
    // Handle update action
    // This would typically launch a URL or app store page
    // For now, just show a dialog to simulate the update process
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translationService.tr('auth.check_update.title', {}, context)),
        content: Text(translationService.tr('auth.check_update.description', {}, context)),
        actions: [
          TextButton(
            onPressed: () => null,
            child: Text(translationService.tr('common.got_it', {}, context)),
          ),
        ],
      ),
    );
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
                      'assets/images/check_update.png', // Assuming you have this image
                      height: size.height * 0.3,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      translationService.tr(
                          'auth.check_update.title', {}, context),
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
                          'auth.check_update.description', {}, context),
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

            // Bottom buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              child: Column(
                children: [
                  // Update button
                  CustomButton(
                    text: 'Update Now',
                    onPressed: () => _onUpdate(context),
                    variant: CustomButtonVariant.primary,
                    size: CustomButtonSize.large,
                    isFullWidth: true,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Continue button
                  CustomButton(
                    text: translationService.tr('common.continue', {}, context),
                    onPressed: () => _onContinue(context),
                    variant: CustomButtonVariant.outlined,
                    size: CustomButtonSize.large,
                    isFullWidth: true,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
