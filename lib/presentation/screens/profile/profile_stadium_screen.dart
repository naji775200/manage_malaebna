import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/stadium_profile/stadium_profile_bloc.dart';
import '../../../logic/stadium_profile/stadium_profile_event.dart';
import '../../../logic/stadium_profile/stadium_profile_state.dart';
import '../../../logic/localization_bloc.dart';
import '../../../logic/theme/theme_bloc.dart';
import '../../../core/services/translation_service.dart';
import '../../routes/app_routes.dart';
import 'edit_profile_stadium_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/stadium_repository.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../data/repositories/stadium_services_repository.dart';
import 'dart:convert';
import '../../../data/repositories/entity_images_repository.dart';
import 'package:sentry/sentry.dart';

class ProfileStadiumScreen extends StatefulWidget {
  final String? stadiumId;

  const ProfileStadiumScreen({super.key, this.stadiumId});

  @override
  State<ProfileStadiumScreen> createState() => _ProfileStadiumScreenState();
}

class _ProfileStadiumScreenState extends State<ProfileStadiumScreen> {
  String? loadedStadiumId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStadiumId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set up a focus listener to refresh the profile when coming back from edit screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null) {
        route.addScopedWillPopCallback(() async {
          if (!isLoading && mounted && loadedStadiumId != null) {
            // Refresh profile data when returning to this screen
            final bloc = context.read<StadiumProfileBloc>();
            bloc.add(const RefreshStadiumProfile());
          }
          return false; // Allow the pop to happen
        });
      }
    });
  }

  Future<void> _initializeStadiumId() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First try using the stadiumId passed as parameter
      if (widget.stadiumId != null && widget.stadiumId!.isNotEmpty) {
        print("Using stadium ID passed as parameter: ${widget.stadiumId}");

        // Debug the stadium ID to check if it exists
        await AuthUtils.debugStadiumRetrieval(widget.stadiumId!);

        setState(() {
          loadedStadiumId = widget.stadiumId;
          isLoading = false;
        });
        return;
      }

      // If no ID was passed, try to get a verified stadium ID
      final id = await AuthUtils.getAndVerifyStadiumId();
      print("Retrieved verified Stadium ID: $id");

      if (id == null || id.isEmpty) {
        print("No valid stadium ID found, using fallback");
        // For testing/fallback, you can use a known valid stadium ID from your database
        const fallbackId = "123e4567-e89b-12d3-a456-426614174000";

        setState(() {
          loadedStadiumId = fallbackId;
          isLoading = false;
        });
        return;
      }

      print("Using stadium ID: $id");

      // Debug the stadium ID to check if it exists
      await AuthUtils.debugStadiumRetrieval(id);

      setState(() {
        loadedStadiumId = id;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading stadium ID: $e");
      // Still use a fallback ID for testing
      setState(() {
        loadedStadiumId = "123e4567-e89b-12d3-a456-426614174000";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Safety check for null stadium ID
    if (loadedStadiumId == null || loadedStadiumId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Stadium Profile"),
        ),
        body: const Center(
          child: Text("Could not find stadium information. Please try again."),
        ),
      );
    }

    print("Building ProfileStadiumScreen with stadiumId: $loadedStadiumId");

    return BlocProvider(
      create: (context) {
        print("Creating StadiumProfileBloc with stadiumId: $loadedStadiumId");

        return StadiumProfileBloc(
          stadiumRepository: context.read<StadiumRepository>(),
          addressRepository: context.read<AddressRepository>(),
          serviceRepository: context.read<ServiceRepository>(),
          stadiumServicesRepository: context.read<StadiumServicesRepository>(),
          entityImagesRepository: context.read<EntityImagesRepository>(),
        )..add(LoadStadiumProfile(stadiumId: loadedStadiumId));
      },
      child: BlocConsumer<StadiumProfileBloc, StadiumProfileState>(
        listener: (context, state) {
          if (state.isError) {
            // Log error details
            print('StadiumProfileScreen error: ${state.errorMessage}');

            // Show more detailed error message to help with debugging
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error loading stadium profile: ${state.errorMessage ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    context
                        .read<StadiumProfileBloc>()
                        .add(LoadStadiumProfile(stadiumId: loadedStadiumId));
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isInitial || (state.isLoading && !state.hasStadium)) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Add a fallback if there's an error but we show the screen anyway
          if (state.isError && !state.hasStadium) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Stadium Profile'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                        'Error loading profile: ${state.errorMessage ?? 'Unknown error'}'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<StadiumProfileBloc>().add(
                            LoadStadiumProfile(stadiumId: loadedStadiumId));
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildProfileContent(context, state);
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, StadiumProfileState state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<StadiumProfileBloc>().add(const RefreshStadiumProfile());
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Stadium Image and Rating
              _buildProfileHeader(context, state),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Edit Profile Button
                    _buildEditProfileButton(context),

                    const SizedBox(height: 24),
                    // Settings section
                    Text(
                      translationService.translate('profile.settings'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Language setting
                    _buildSettingItem(
                      context,
                      Icons.language,
                      translationService.translate('profile.language'),
                      _getLanguageName(context),
                      showArrow: true,
                      onTap: () {
                        _showLanguageBottomSheet(context);
                      },
                    ),

                    // Theme setting
                    _buildSettingItem(
                      context,
                      Icons.brightness_6,
                      translationService.translate('profile.theme'),
                      _buildThemeText(context),
                      showArrow: true,
                      onTap: () {
                        _showThemeSelector(context);
                      },
                    ),

                    // Working Hours setting
                    _buildSettingItem(
                      context,
                      Icons.access_time,
                      translationService.translate('working_hours.title'),
                      '',
                      showArrow: true,
                      onTap: () {
                        final String stId = state.stadium?.id ?? '123';
                        final String stadiumName = state.stadium?.name ?? '';
                        AppRoutes.slideToWorkingHours(
                          context,
                          stadiumId: stId,
                          stadiumName: stadiumName,
                        );
                      },
                    ),

                    // Prices and Coupons setting
                    _buildSettingItem(
                      context,
                      Icons.attach_money,
                      translationService.translate('prices_coupons.title'),
                      '',
                      showArrow: true,
                      onTap: () {
                        final String stId = state.stadium?.id ?? '123';
                        final String stadiumName = state.stadium?.name ?? '';
                        AppRoutes.slideToPricesCoupons(
                          context,
                          stadiumId: stId,
                          stadiumName: stadiumName,
                        );
                      },
                    ),

                    // Reports Management
                    // _buildSettingItem(
                    //   context,
                    //   Icons.bar_chart,
                    //   translationService.tr('profile.reports', {}, context),
                    //   translationService.tr(
                    //       'profile.reports_desc', {}, context),
                    //   showArrow: true,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const ReportsScreen(),
                    //         fullscreenDialog: true,
                    //       ),
                    //     );
                    //   },
                    // ),

                    // Support setting
                    _buildSettingItem(
                      context,
                      Icons.help_outline,
                      translationService.translate('profile.support'),
                      '',
                      showArrow: true,
                      onTap: () {
                        _showSupportBottomSheet(context);
                      },
                    ),

                    // Terms of service setting
                    _buildSettingItem(
                      context,
                      Icons.description_outlined,
                      translationService.translate('profile.terms'),
                      '',
                      showArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsScreen(),
                          ),
                        );
                      },
                    ),

                    // Privacy policy setting
                    _buildSettingItem(
                      context,
                      Icons.privacy_tip_outlined,
                      translationService.translate('profile.privacy'),
                      '',
                      showArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),

                    // Add Sentry Test Button
                    // ListTile(
                    //   leading:
                    //       const Icon(Icons.bug_report, color: Colors.orange),
                    //   title: Text(isRtl ? 'اختبار Sentry' : 'Test Sentry'),
                    //   subtitle: Text(
                    //     isRtl
                    //         ? 'إرسال خطأ تجريبي إلى Sentry لاختبار التكامل'
                    //         : 'Send a test error to Sentry to verify integration',
                    //     style: TextStyle(fontSize: 12),
                    //   ),
                    //   onTap: () {
                    //     _testSentryIntegration();
                    //   },
                    // ),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showLogoutConfirmation(context);
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(
                            translationService.translate('profile.logout')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App version at the bottom
                    Center(
                      child: Text(
                        translationService.translate('profile.version_number'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, StadiumProfileState state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 250,
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Stack(
        children: [
          // Stadium info centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Avatar
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        key: ValueKey<String>(
                            '${state.profileImageUrl ?? 'default_avatar'}_${DateTime.now().millisecondsSinceEpoch}'),
                        backgroundImage:
                            _getProfileImageProvider(state.profileImageUrl),
                      ),
                    ),
                    // Add a small indicator to show when image is being refreshed
                    if (state.isRefreshing)
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stadium name
                Text(
                  state.stadium?.name ?? 'Stadium Name',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Stadium location
                Text(
                  state.address != null
                      ? '${state.address?.city ?? ''}, ${state.address?.district ?? ''}'
                      : 'Location not available',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Open/Closed status pill (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                translationService.translate('stadium_profile.open_now'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Rating pill (top left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.6)
                    : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${state.stadium?.averageReview ?? 0.0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Navigate to the edit screen and wait for it to return
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileStadiumScreen(),
            ),
          );

          // When the edit screen returns, force a refresh of the profile
          if (mounted) {
            print("Returned from edit screen, forcing profile refresh...");

            // Force a refresh of the entity images by clearing the current state
            // and refreshing the stadium profile with a new bloc event
            final bloc = context.read<StadiumProfileBloc>();

            // Add a small delay to ensure any database operations complete
            await Future.delayed(const Duration(milliseconds: 300));

            bloc.add(const RefreshStadiumProfile());

            // Show a temporary message to the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(translationService
                    .translate('stadium_profile.update_success')),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        icon: const Icon(Icons.edit),
        label:
            Text(translationService.translate('stadium_profile.edit_profile')),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    dynamic subtitle, {
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: subtitle is String
            ? (subtitle.isNotEmpty ? Text(subtitle) : null)
            : subtitle,
        trailing: showArrow
            ? Icon(
                isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                size: 16,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showSupportBottomSheet(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'خيارات الدعم' : 'Support Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(isArabic ? 'المحادثة المباشرة' : 'Live Chat'),
                onTap: () {
                  Navigator.pop(context);
                  // Show a mock live chat dialog
                  _showLiveChatDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(
                    isArabic ? 'الدعم عبر البريد الإلكتروني' : 'Email Support'),
                onTap: () {
                  Navigator.pop(context);
                  // Show a confirmation that email will be sent
                  _launchEmailSupport(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(isArabic ? 'الاتصال بالدعم' : 'Call Support'),
                onTap: () {
                  Navigator.pop(context);
                  // Show dialog with support phone number
                  _showCallSupportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(isArabic ? 'الأسئلة الشائعة' : 'FAQ'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to a simple FAQ screen
                  _showFaqScreen(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Mock live chat dialog
  void _showLiveChatDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'المحادثة المباشرة' : 'Live Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isArabic
                ? 'سيتم توصيلك بممثل دعم في الدقائق القليلة القادمة.'
                : 'You will be connected to a support representative in the next few minutes.'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isArabic
                    ? 'تم إلغاء طلب المحادثة المباشرة'
                    : 'Live chat request canceled'),
              ));
            },
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  // Mock email support
  void _launchEmailSupport(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isArabic
          ? 'جاري فتح تطبيق البريد الإلكتروني...'
          : 'Opening email application...'),
      duration: const Duration(seconds: 2),
    ));

    // Simulate a slight delay before showing success message
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic
              ? 'تم إعداد رسالة بريد إلكتروني إلى mo.na.ali.alameri@gmail.com'
              : 'Email prepared to mo.na.ali.alameri@gmail.com'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ));
      }
    });
  }

  // Mock call support dialog
  void _showCallSupportDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'الاتصال بالدعم' : 'Call Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isArabic ? 'رقم الدعم:' : 'Support number:'),
            const SizedBox(height: 8),
            Text(
              '+967775200846',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(isArabic
                ? 'متاح من السبت إلى الخميس، 9 صباحًا - 5 مساءً'
                : 'Available Staurday-Thursday, 9AM - 5PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isArabic
                    ? '00جاري الاتصال بالرقم 967 775200846...'
                    : 'Calling +967 775200846...'),
                backgroundColor: Colors.green,
              ));
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.call),
                const SizedBox(width: 8),
                Text(isArabic ? 'اتصال' : 'Call'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show FAQ screen
  void _showFaqScreen(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(isArabic ? 'الأسئلة الشائعة' : 'FAQ'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFaqItem(
                context,
                isArabic
                    ? 'ما هي سياسة الإلغاء؟'
                    : 'What is the cancellation policy?',
                isArabic
                    ? 'يمكنك إلغاء الحجز قبل 24 ساعة من الموعد للحصول على استرداد كامل.'
                    : 'You can cancel a booking 24 hours before the scheduled time for a full refund.',
              ),
              _buildFaqItem(
                context,
                isArabic
                    ? 'كيف يمكنني تغيير كلمة المرور الخاصة بي؟'
                    : 'How do I change my password?',
                isArabic
                    ? 'يمكنك تغيير كلمة المرور من خلال الانتقال إلى إعدادات الحساب واختيار "تغيير كلمة المرور".'
                    : 'You can change your password by going to Account Settings and selecting "Change Password".',
              ),
              _buildFaqItem(
                context,
                isArabic
                    ? 'هل يمكنني تحديث معلومات الملعب؟'
                    : 'Can I update my stadium information?',
                isArabic
                    ? 'نعم، يمكنك تحديث معلومات الملعب من خلال الضغط على "تعديل الملف" في صفحة الملف الشخصي.'
                    : 'Yes, you can update your stadium information by clicking "Edit Profile" on the profile page.',
              ),
              _buildFaqItem(
                context,
                isArabic
                    ? 'كيف يمكنني إضافة صور جديدة للملعب؟'
                    : 'How do I add new stadium photos?',
                isArabic
                    ? 'يمكنك إضافة صور جديدة من خلال تعديل الملف الشخصي والنقر على "تغيير الصورة".'
                    : 'You can add new photos by editing your profile and clicking on "Change Image".',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build FAQ items
  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
        content: Text(isArabic
            ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Dismiss the confirmation dialog
              Navigator.of(dialogContext).pop();

              // Show loading indicator in a new dialog
              BuildContext? loadingContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingContext = ctx;
                  return WillPopScope(
                    onWillPop: () async =>
                        false, // Prevent back button from closing dialog
                    child: Dialog(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              isArabic
                                  ? 'جاري تسجيل الخروج...'
                                  : 'Logging out...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );

              // Use a BlocListener to handle navigation after logout
              // We'll listen for state changes here but dispatch the event right away
              final authBloc = context.read<AuthBloc>();

              // Dispatch logout event to AuthBloc
              authBloc.add(const AuthLogoutRequested());

              // Listen for auth state changes to know when logout is complete
              Future.delayed(const Duration(milliseconds: 500), () {
                if (loadingContext != null &&
                    Navigator.canPop(loadingContext!)) {
                  Navigator.of(loadingContext!).pop(); // Close loading dialog
                }
                AppRoutes.navigateToLogin(context);
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(BuildContext context) {
    // Get current language from LocalizationBloc
    final localizationBloc = context.read<LocalizationBloc>();
    final currentLanguage = localizationBloc.state.locale.languageCode;

    switch (currentLanguage) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return currentLanguage.toUpperCase();
    }
  }

  Widget _buildThemeText(BuildContext context) {
    return Consumer<ThemeBloc>(
      builder: (context, themeBloc, child) {
        final currentTheme = themeBloc.state.themeMode;
        return Text(
          _getThemeModeName(currentTheme, context),
          style: const TextStyle(
            fontSize: 16.0,
          ),
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.light:
        return translationService.translate('theme.light');
      case ThemeMode.dark:
        return translationService.translate('theme.dark');
      case ThemeMode.system:
        return translationService.translate('theme.system');
      default:
        return translationService.translate('theme.system');
    }
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    translationService.translate('profile.select_language'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text('🇺🇸'),
                  ),
                  title: const Text('English'),
                  onTap: () {
                    // Use LocalizationBloc to change language
                    context
                        .read<LocalizationBloc>()
                        .add(LocalizationChangedEvent('en'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text('🇸🇦'),
                  ),
                  title: const Text('العربية'),
                  onTap: () {
                    // Use LocalizationBloc to change language
                    context
                        .read<LocalizationBloc>()
                        .add(LocalizationChangedEvent('ar'));
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translationService.translate('profile.select_theme'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: Text(translationService.translate('theme.light')),
                onTap: () {
                  // Use ThemeBloc to change theme
                  context
                      .read<ThemeBloc>()
                      .add(ThemeChangedEvent(ThemeMode.light));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay),
                title: Text(translationService.translate('theme.dark')),
                onTap: () {
                  // Use ThemeBloc to change theme
                  context
                      .read<ThemeBloc>()
                      .add(ThemeChangedEvent(ThemeMode.dark));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_suggest),
                title: Text(translationService.translate('theme.system')),
                onTap: () {
                  // Use ThemeBloc to change theme
                  context
                      .read<ThemeBloc>()
                      .add(ThemeChangedEvent(ThemeMode.system));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _getProfileImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/images/stadium/stadium1.jpg');
    }

    // Print the first part of the image URL for debugging
    print(
        'Loading profile image with URL starting with: ${imageUrl.substring(0, imageUrl.length > 30 ? 30 : imageUrl.length)}...');

    // Handle data URIs
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract the base64 data from the data URI
        final dataIndex = imageUrl.indexOf(',') + 1;
        if (dataIndex > 0 && dataIndex < imageUrl.length) {
          final base64Data = imageUrl.substring(dataIndex);
          // Add a timestamp to force refresh of the image
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          return MemoryImage(
            base64Decode(base64Data),
            // Add a scale parameter to force the image to be reloaded
            scale: 1.0 + (timestamp % 10) / 1000,
          );
        }
      } catch (e) {
        print('Error decoding base64 image: $e');
        // Fallback to default image if decoding fails
        return const AssetImage('assets/images/stadium/stadium1.jpg');
      }
    }

    // Regular network image for http/https URLs
    // Add parameters to disable caching and force refresh
    return NetworkImage(
      imageUrl,
      // Add a scale parameter to force the image to be reloaded
      scale: 1.0 + (DateTime.now().millisecondsSinceEpoch % 10) / 1000,
    );
  }

  // Add a method to test Sentry integration
  void _testSentryIntegration() {
    try {
      // Intentionally throw an error to test Sentry
      throw Exception('This is a test error for Sentry integration');
    } catch (exception, stackTrace) {
      // Show a snackbar to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test error sent to Sentry'),
          backgroundColor: Colors.green,
        ),
      );

      // Forward the exception to Sentry
      Sentry.captureException(exception, stackTrace: stackTrace);

      print('Test error sent to Sentry: $exception');
    }
  }
}
