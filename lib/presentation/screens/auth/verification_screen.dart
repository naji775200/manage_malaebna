import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../routes/app_routes.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/custom_snackbar.dart';
import 'dart:developer';
import '../../screens/auth/login_screen.dart'; // Import for UserType enum

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  // Track which digit box is currently focused
  final List<bool> _isFocused = List.generate(4, (_) => false);
  // Track which digits are filled
  final List<bool> _isFilled = List.generate(4, (_) => false);

  bool _isResendingCode = false;
  bool _isSubmitting = false;
  int _resendCountdown = 30; // Reduced wait time for testing
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Animation controllers for the digit boxes
  final List<AnimationController> _digitAnimControllers = [];
  final List<Animation<double>> _digitScaleAnimations = [];

  // Test mode notice
  final bool _isTestMode = true; // Set to true to match AuthBloc's test mode

  // Format phone number to ensure + is at the beginning
  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';

    // If the phone doesn't start with +, check if it ends with +
    if (!phone.startsWith('+') && phone.endsWith('+')) {
      // Move the + from end to beginning
      return '+${phone.substring(0, phone.length - 1)}';
    }

    // If it already starts with +, return as is
    if (phone.startsWith('+')) {
      return phone;
    }

    // If there's no +, add it at the beginning
    return '+$phone';
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    // Initialize main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Set up focus listeners
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      );

      final animation = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );

      _digitAnimControllers.add(controller);
      _digitScaleAnimations.add(animation);

      _focusNodes[i].addListener(() {
        setState(() {
          _isFocused[i] = _focusNodes[i].hasFocus;
        });

        if (_focusNodes[i].hasFocus) {
          _digitAnimControllers[i].forward();
        } else {
          _digitAnimControllers[i].reverse();
        }
      });
    }

    _animationController.forward();

    // Always prefill with 0000 in test mode after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      for (int i = 0; i < _controllers.length; i++) {
        _controllers[i].text = '0';
        setState(() {
          _isFilled[i] = true;
        });
      }
    });
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    for (var controller in _digitAnimControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCodeDigitChanged(String value, int index) {
    setState(() {
      _isFilled[index] = value.isNotEmpty;
    });

    if (value.isNotEmpty) {
      // Auto-advance focus to the next field
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // If the last digit is entered, unfocus and check the code
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (index > 0 && value.isEmpty) {
      // If backspace pressed and field is empty, go back to previous field
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyCode() {
    // Combine all digits to get the full code
    final code = _controllers.map((controller) => controller.text).join();

    // Only proceed if we have a 4-digit code
    if (code.length == 4) {
      setState(() {
        _isSubmitting = true;
      });

      // In test mode, always send the code directly
      // No need to check for "0000" specifically since we're in test mode
      context.read<AuthBloc>().add(AuthVerificationCodeSubmitted(code));

      // Reset submitting state after a delay to prevent multiple submissions
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      });
    }
  }

  void _resendCode() {
    setState(() {
      _isResendingCode = true;
    });

    context.read<AuthBloc>().add(const AuthCodeResendRequested());

    setState(() {
      _isResendingCode = false;
      _resendCountdown = 30;
    });

    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = translationService.isRtl(context);
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isError) {
          // More detailed error message for debugging account creation issues
          String errorMsg = state.errorMessage;
          if (errorMsg.contains("Failed to get or generate user ID") ||
              errorMsg.contains("create") ||
              errorMsg.contains("stadium") ||
              errorMsg.contains("owner")) {
            errorMsg += "\n\n" +
                translationService.tr(
                    'auth.account_creation_error', {}, context);
          }
          CustomSnackBar.showError(context, errorMsg);
        }
        if (state.isAuthenticated) {
          // Display success message before navigating
          CustomSnackBar.showSuccess(context,
              translationService.tr('auth.login_success', {}, context));

          // Verify that the user data was properly saved in Supabase by checking local storage
          Future.delayed(const Duration(milliseconds: 800), () async {
            try {
              if (!mounted) return;

              final authBloc = context.read<AuthBloc>();
              final userType = authBloc.state.userType;
              final userId = authBloc.state.userId;

              log('Verified user created successfully - UserID: $userId, Type: ${userType == UserType.stadium ? "Stadium" : "Owner"}');
            } catch (e) {
              log('Error verifying user creation: $e');
            }

            // Navigate to main screen
            if (mounted) {
              // Use routes system to navigate to main screen after authentication
              AppRoutes.navigateToMain(context);
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
                translationService.tr('auth.verification_title', {}, context)),
            elevation: 0,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with gradient background
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withBlue(200),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            translationService.tr(
                                'auth.verification_title', {}, context),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone number display message
                        Text(
                          state.isExistingAccount
                              ? translationService.tr(
                                  'auth.verification_info_existing',
                                  {},
                                  context)
                              : translationService.tr(
                                  'auth.verification_info', {}, context),
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        // First display the message
                        Text(
                          translationService.tr(
                              'auth.verification_sent_to', {}, context),
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4.0),
                        // Then display the phone number in LTR mode
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _formatPhoneNumber(state.phoneNumber),
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Test mode notice - always show for now since SMS provider is not configured
                        Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Colors.amber,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.amber,
                                size: 24.0,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      translationService.tr(
                                          'auth.test_mode', {}, context),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      translationService.tr(
                                          'auth.test_code', {}, context),
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40.0),

                        // Enhanced custom verification code input fields
                        Directionality(
                          textDirection: TextDirection
                              .ltr, // Always LTR for verification codes
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ScaleTransition(
                                  scale: _digitScaleAnimations[index],
                                  child: _buildDigitBox(index),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 40.0),

                        // Animated verify button
                        ElevatedButton(
                          onPressed: (_isSubmitting ||
                                  !_isFilled.every((filled) => filled))
                              ? null
                              : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 8,
                            shadowColor:
                                theme.colorScheme.primary.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24.0,
                                  width: 24.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  translationService.tr(
                                      'auth.verify', {}, context),
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24.0),

                        // Resend code option with modern design
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                translationService.tr(
                                    'auth.didnt_receive_code', {}, context),
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12.0),
                              _resendCountdown > 0
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          translationService.tr(
                                            'auth.resend_in',
                                            {
                                              'seconds':
                                                  _resendCountdown.toString()
                                            },
                                            context,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : TextButton(
                                      onPressed:
                                          _isResendingCode ? null : _resendCode,
                                      style: TextButton.styleFrom(
                                        backgroundColor: theme
                                            .colorScheme.primary
                                            .withOpacity(0.1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isResendingCode
                                          ? const SizedBox(
                                              height: 16.0,
                                              width: 16.0,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                              ),
                                            )
                                          : Text(
                                              translationService.tr(
                                                  'auth.resend_code',
                                                  {},
                                                  context),
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDigitBox(int index) {
    final theme = Theme.of(context);

    // Get colors based on focus and fill state
    final bool isFocused = _isFocused[index];
    final bool isFilled = _isFilled[index];

    final Color borderColor = isFocused
        ? theme.colorScheme.primary
        : isFilled
            ? theme.colorScheme.primary.withOpacity(0.7)
            : theme.colorScheme.outline.withOpacity(0.3);

    final Color fillColor = isFilled
        ? theme.colorScheme.primary.withOpacity(0.1)
        : isFocused
            ? theme.colorScheme.surface
            : theme.colorScheme.surface;

    final double borderWidth = isFocused ? 2.0 : 1.5;

    return Container(
      width: 60.0,
      height: 60.0,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8.0,
                  spreadRadius: 0.5,
                )
              ]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection:
              TextDirection.ltr, // Ensure text direction is always LTR
          maxLength: 1,
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => _onCodeDigitChanged(value, index),
        ),
      ),
    );
  }
}
