import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/user_type_selector.dart';
import '../../widgets/country_code_selector.dart';

// Define UserType enum
enum UserType { owner, stadium }

// Custom formatter to add spaces in phone number
class PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final newText = StringBuffer();
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < digits.length; i++) {
      // Add a space after 3rd and 6th digits for better readability
      if (i == 3 || i == 6) {
        newText.write(' ');
      }
      newText.write(digits[i]);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isSubmitting = false;
  UserType _selectedUserType = UserType.owner;
  String? _nameError;
  String? _phoneError;
  bool _isExistingAccount = false;

  // Default to Yemen
  CountryCode _selectedCountry =
      const CountryCode(code: '+967', countryName: 'Yemen', flagEmoji: '🇾🇪');

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError =
            translationService.tr('validation.name_required', {}, context);
      });
      isValid = false;
    } else {
      setState(() {
        _nameError = null;
      });
    }

    // Validate phone
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneError =
            translationService.tr('validation.phone_required', {}, context);
      });
      isValid = false;
    } else {
      // Get the phone number without spaces
      final phoneDigits = _phoneController.text.replaceAll(' ', '').trim();

      // Validate based on country
      if (_selectedCountry.code == '+966') {
        // Saudi Arabia validation
        // Pattern: (009665|9665|\+9665|05|5)(5|0|3|6|4|9|1|8|7)([0-9]{7})
        final RegExp saudiPattern =
            RegExp(r'^(5)(5|0|3|6|4|9|1|8|7)([0-9]{7})$');
        if (!saudiPattern.hasMatch(phoneDigits)) {
          setState(() {
            _phoneError = translationService.tr(
                'validation.invalid_saudi_number', {}, context);
          });
          isValid = false;
        } else {
          setState(() {
            _phoneError = null;
          });
        }
      } else if (_selectedCountry.code == '+967') {
        // Yemen validation
        // Numbers should start with 70, 71, 73, 77, or 78
        final RegExp yemenPattern = RegExp(r'^(7)(0|1|3|7|8)([0-9]{7})$');
        if (!yemenPattern.hasMatch(phoneDigits)) {
          setState(() {
            _phoneError = translationService.tr(
                'validation.invalid_yemen_number', {}, context);
          });
          isValid = false;
        } else {
          setState(() {
            _phoneError = null;
          });
        }
      } else {
        // Generic validation for other countries (at least 9 digits)
        if (phoneDigits.length < 9) {
          setState(() {
            _phoneError = translationService.tr(
                'validation.valid_phone_required', {}, context);
          });
          isValid = false;
        } else {
          setState(() {
            _phoneError = null;
          });
        }
      }
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the app is using RTL layout
    final isRtl = translationService.isRtl(context);
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Show error if any
        if (state.isError) {
          CustomSnackBar.showError(context, state.errorMessage);
          // Reset submission state
          setState(() {
            _isSubmitting = false;
          });
        }

        // If the phone number has been submitted and we detected an existing account
        if (state.isPhoneNumberSubmitted && state.isExistingAccount) {
          setState(() {
            _isExistingAccount = true;
            // Update the selected user type to match the existing account
            _selectedUserType = state.userType;
          });
        }

        // Handle successful phone number submission
        if (state.isPhoneVerificationSent) {
          // If this is an existing account, show a welcome back message
          if (state.isExistingAccount && state.userName.isNotEmpty) {
            String message = translationService.tr(
              'auth.welcome_back',
              {'name': state.userName},
              context,
            );

            // If user selected a different type than the existing account type
            UserType selectedType = _selectedUserType;
            if (selectedType != state.userType) {
              // Add a note about the account type
              String accountTypeMessage = state.userType == UserType.stadium
                  ? translationService.tr(
                      'auth.account_type_stadium', {}, context)
                  : translationService.tr(
                      'auth.account_type_owner', {}, context);

              message += " $accountTypeMessage";

              // Update local selected type to match server
              setState(() {
                _selectedUserType = state.userType;
              });
            }

            CustomSnackBar.showInfo(context, message);
          }

          // Reset submission state
          setState(() {
            _isSubmitting = false;
          });

          // Navigate to verification screen with the current bloc
          final authBloc = context.read<AuthBloc>();
          AppRoutes.slideToVerificationWithBloc(context, authBloc);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(translationService.tr('auth.login', {}, context)),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title and subtitle
                      Text(
                        translationService.tr('auth.welcome', {}, context),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // Welcome Text
                      Text(
                        translationService.tr(
                            'auth.enter_phone_prompt', {}, context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 32.0),
                      // User type selector with disabled state if existing account
                      UserTypeSelector(
                        initialValue: _selectedUserType == UserType.stadium
                            ? 'stadium'
                            : 'owner',
                        onChanged: (type) {
                          setState(() {
                            _selectedUserType = type == 'stadium'
                                ? UserType.stadium
                                : UserType.owner;
                          });
                        },
                        label: translationService.tr(
                            'auth.user_type.title', {}, context),
                        isRequired: true,
                        isDisabled: _isExistingAccount,
                      ),
                      const SizedBox(height: 20.0),
                      // Name field
                      CustomTextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        label: translationService.tr('auth.name', {}, context),
                        hint: translationService.tr(
                            'auth.enter_name', {}, context),
                        prefixIcon: Icons.person_outline,
                        errorText: _nameError,
                        isRequired: true,
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 20.0),

                      // Phone number field with modern design
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: _phoneError != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline.withOpacity(0.1),
                            width: _phoneError != null ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, left: 4.0, right: 4.0),
                              child: Row(
                                children: [
                                  Text(
                                    translationService.tr(
                                        'auth.phone', {}, context),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Directionality(
                              textDirection: TextDirection
                                  .ltr, // Always LTR for phone numbers
                              child: Row(
                                children: [
                                  // Country code selector
                                  CountryCodeSelector(
                                    selectedCountry: _selectedCountry,
                                    onCountrySelected: (country) {
                                      setState(() {
                                        _selectedCountry = country;
                                        // Clear error when country changes
                                        _phoneError = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12.0),

                                  // Phone number input field
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocusNode,
                                      keyboardType: TextInputType.phone,
                                      textAlign: TextAlign
                                          .left, // Ensure text alignment is left
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: translationService.tr(
                                            'auth.phone_number', {}, context),
                                        hintTextDirection: TextDirection
                                            .ltr, // Ensure hint text direction is also LTR
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                        icon: Icon(
                                          Icons.phone_android,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                            9), // Allow 9 digits after the country code
                                        PhoneNumberTextInputFormatter(), // Format phone number with spaces
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_phoneError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                          child: Text(
                            _phoneError!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12.0,
                            ),
                          ),
                        ),

                      const SizedBox(height: 36.0),

                      // Login button with modern, animated effect
                      ElevatedButton(
                        onPressed: _isSubmitting || state.isPhoneNumberSubmitted
                            ? null
                            : () {
                                if (_validateInputs()) {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  // Get the phone number with the country code
                                  final phoneNumber =
                                      '${_selectedCountry.code}${_phoneController.text.replaceAll(' ', '').trim()}';

                                  context.read<AuthBloc>().add(
                                        AuthPhoneNumberSubmitted(
                                          phoneNumber,
                                          name: _nameController.text.trim(),
                                          userType: _selectedUserType,
                                        ),
                                      );

                                  // The state changes will be handled by the BlocListener above
                                }
                              },
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
                        child: _isSubmitting || state.isPhoneNumberSubmitted
                            ? const SizedBox(
                                height: 24.0,
                                width: 24.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    translationService.tr(
                                        'common.continue', {}, context),
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isRtl
                                        ? Icons.arrow_back
                                        : Icons.arrow_forward,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 24.0),

                      // Terms and privacy note
                      Text(
                        translationService.tr(
                            'auth.terms_agreement', {}, context),
                        style: TextStyle(
                          fontSize: 13.0,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
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
