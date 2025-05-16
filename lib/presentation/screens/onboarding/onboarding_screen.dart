import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../logic/onboarding/onboarding_bloc.dart';
import '../../../data/models/onboarding_page_model.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import 'onboarding_page.dart';
import '../../../core/services/translation_service.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of onboarding pages
  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'onboarding.welcome.title',
      description: 'onboarding.welcome.description',
      imagePath: 'assets/images/onboarding/onboarding1.png',
    ),
    OnboardingPageModel(
      title: 'onboarding.search.title',
      description: 'onboarding.search.description',
      imagePath: 'assets/images/onboarding/onboarding2.png',
    ),
    OnboardingPageModel(
      title: 'onboarding.book.title',
      description: 'onboarding.book.description',
      imagePath: 'assets/images/onboarding/onboarding3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    print('Completing onboarding and navigating to next screen...');
    // Mark onboarding as complete
    context.read<OnboardingBloc>().add(OnboardingCompleteEvent());

    // As a fallback, also handle navigation directly
    // This provides redundancy in case the BlocListener doesn't trigger
    Future.delayed(const Duration(milliseconds: 100), () {
      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;
      print(
          'Auth state for navigation: ${authState.isAuthenticated ? "Authenticated" : "Not authenticated"}');
      if (authState.isAuthenticated) {
        AppRoutes.navigateToMain(context);
      } else {
        AppRoutes.navigateToLogin(context);
      }
    });
  }

  void _onSkip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        // When onboarding is completed, navigate to main screen if authenticated, otherwise to login
        if (state.isCompleted) {
          print('Onboarding completed. Navigating to next screen...');
          // Use Future.microtask to ensure we're not in the middle of a build cycle
          Future.microtask(() {
            if (!mounted) return;

            final authState = context.read<AuthBloc>().state;
            if (authState.isAuthenticated) {
              print('User is authenticated. Navigating to main screen.');
              AppRoutes.navigateToMain(context);
            } else {
              print('User is not authenticated. Navigating to login screen.');
              AppRoutes.navigateToLogin(context);
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Settings and Skip row
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
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.2),
                            ),

                            // Theme switcher
                            const ThemeSwitcher(),
                          ],
                        ),
                      ),

                      // Skip button
                      TextButton(
                        onPressed: _onSkip,
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? translationService.tr(
                                  'common.skip', {}, context)
                              : '',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page view - make it larger by giving it more vertical space
                Expanded(
                  flex: 80, // Adjusted flex for better spacing
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        page: _pages[index],
                      );
                    },
                  ),
                ),

                // Bottom navigation - make it more compact
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          spacing: 8,
                          activeDotColor: theme.colorScheme.primary,
                          dotColor: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),

                      // Next/Get Started button
                      ElevatedButton(
                        onPressed: _onNextPage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.06,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? translationService.tr(
                                  'common.next', {}, context)
                              : translationService.tr(
                                  'common.get_started', {}, context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
