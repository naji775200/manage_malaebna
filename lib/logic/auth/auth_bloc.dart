import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:manage_malaebna/logic/auth/auth_event.dart';
import 'package:manage_malaebna/logic/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../data/local/database_helper.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Keys for SharedPreferences
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserId = 'userId';
  static const String keyPhoneNumber = 'phoneNumber';
  static const String keyUserName = 'userName';
  static const String keyUserType = 'userType';
  static const String keyIsExistingAccount = 'isExistingAccount';

  final _supabase = Supabase.instance.client;
  final _random = math.Random.secure();

  // Generate a proper UUID v4 string that PostgreSQL will accept
  String _generateUuidV4() {
    // Generate 16 random bytes
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set the version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 1

    // Convert to hex and format properly
    const hexDigits = "0123456789abcdef";
    final buffer = StringBuffer();

    for (int i = 0; i < 16; i++) {
      buffer.write(hexDigits[(bytes[i] >> 4) & 0x0F]);
      buffer.write(hexDigits[bytes[i] & 0x0F]);
      // Add hyphens after positions 3, 5, 7, 9
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        buffer.write("-");
      }
    }

    return buffer.toString();
  }

  // Mock auth for testing
  static const bool _isTestMode = true;
  static const String _testOtpCode = '0000';

  AuthBloc() : super(const AuthState()) {
    on<AuthInitialEvent>(_onAuthInitial);
    on<AuthNavigateToLoginEvent>(_onNavigateToLogin);
    on<AuthPhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<AuthVerificationCodeSubmitted>(_onVerificationCodeSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckLoginStatusEvent>(_onCheckLoginStatus);
    on<AuthVerifyPhoneNumber>(_onVerifyPhoneNumber);
    on<AuthCodeResendRequested>(_onCodeResendRequested);

    // Check login status on initialization
    add(const AuthCheckLoginStatusEvent());
  }

  Future<void> _onCheckLoginStatus(
    AuthCheckLoginStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
      final userId = prefs.getString(keyUserId);
      final phoneNumber = prefs.getString(keyPhoneNumber);
      final userName = prefs.getString(keyUserName) ?? '';
      final userTypeString = prefs.getString(keyUserType) ?? '';
      final isExistingAccount = prefs.getBool(keyIsExistingAccount) ?? false;
      final userType =
          userTypeString == 'stadium' ? UserType.stadium : UserType.owner;

      if (isLoggedIn && userId != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          userId: userId,
          phoneNumber: phoneNumber ?? '',
          userName: userName,
          userType: userType,
          isExistingAccount: isExistingAccount,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
        ));
      }
    } catch (e) {
      log('Error checking login status: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthInitial(
    AuthInitialEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.initial));
  }

  Future<void> _onNavigateToLogin(
    AuthNavigateToLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  Future<void> _onPhoneNumberSubmitted(
    AuthPhoneNumberSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.phoneNumberSubmitted,
      phoneNumber: event.phoneNumber,
      userName: event.name,
      userType: event.userType,
    ));

    try {
      // Check if phone number already exists in the database
      String? existingUserId;
      String? displayName;
      UserType? existingUserType;

      // Check if phone number exists in stadiums table
      final stadiumData = await _supabase
          .from('stadiums')
          .select('id, name')
          .eq('phone_number', event.phoneNumber)
          .maybeSingle();

      if (stadiumData != null) {
        existingUserId = stadiumData['id'];
        displayName = stadiumData['name'];
        existingUserType = UserType.stadium;
        log('Found existing stadium with ID: $existingUserId, name: $displayName');
      } else {
        // Check if phone number exists in owners table
        final ownerData = await _supabase
            .from('owners')
            .select('id, name')
            .eq('phone_number', event.phoneNumber)
            .maybeSingle();

        if (ownerData != null) {
          existingUserId = ownerData['id'];
          displayName = ownerData['name'];
          existingUserType = UserType.owner;
          log('Found existing owner with ID: $existingUserId, name: $displayName');
        }
      }

      // Store the found user information in state
      if (existingUserId != null) {
        emit(state.copyWith(
          userId: existingUserId,
          userName: displayName ?? event.name, // Use existing name if available
          userType:
              existingUserType, // Use the existing user type from the database
          isExistingAccount: true, // Set flag to indicate existing account
        ));
      }

      // Always use test mode since SMS provider is not configured
      log('Using test mode: Simulating OTP sent to ${event.phoneNumber}');
      emit(state.copyWith(
        status: AuthStatus.phoneVerificationSent,
      ));

      // Comment out the actual Supabase OTP call since it's not configured
      /*
      if (!_isTestMode) {
        // Attempt to sign in with OTP using Supabase
        await _supabase.auth.signInWithOtp(
          phone: event.phoneNumber,
          shouldCreateUser: true,
        );
        emit(state.copyWith(
          status: AuthStatus.phoneVerificationSent,
        ));
      }
      */
    } catch (e) {
      log('Error sending OTP: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onVerificationCodeSubmitted(
    AuthVerificationCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.phoneNumber.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Phone number is missing. Please go back and try again.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.phoneNumberSubmitted));

    try {
      String? userId = state.userId; // Use existing userId if available
      final bool isExistingAccount = state.isExistingAccount;

      // Since we're in test mode, check if the code is correct
      if (event.verificationCode == _testOtpCode) {
        // For test mode, use existing user ID or generate a new one
        log('Valid test code provided: ${event.verificationCode}');

        // If we have an existing user ID from database lookup, use it
        if (userId != null && userId.isNotEmpty) {
          log('Using existing user with ID: $userId');
        } else {
          // Generate a new UUID for new users
          userId = _generateUuidV4();
          log('Generated new UUID for test mode: $userId');
        }
      } else {
        // Wrong code in test mode
        throw Exception(
            'Invalid verification code. Please use 0000 for testing.');
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('Failed to get or generate user ID');
      }

      // Create user profile in database regardless of whether it already exists
      // This ensures we have the correct data in Supabase
      try {
        log('Creating/updating account in database for user: $userId');
        log('User type: ${state.userType}');

        bool accountCreated = false;
        if (state.userType == UserType.owner) {
          final ownerResult = await _createOwnerInDatabase(userId);
          log('Owner creation/update result: $ownerResult');
          accountCreated = ownerResult;
        } else if (state.userType == UserType.stadium) {
          final stadiumResult = await _createStadiumManagerInDatabase(userId);
          log('Stadium creation/update result: $stadiumResult');
          accountCreated = stadiumResult;
        }

        if (!accountCreated) {
          log('WARNING: Failed to create account in database. Will try again later.');
        }
      } catch (e) {
        log('Error creating user profile in database: $e');
        // Continue anyway since the user is authenticated, but log the error
      }

      // Save login state and user ID in SharedPreferences
      await _saveUserData(
        userId,
        state.phoneNumber,
        state.userName,
        state.userType,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userId: userId,
      ));
    } catch (e) {
      log('Error verifying OTP: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.phoneNumberSubmitted));
    try {
      // Sign out from Supabase
      try {
        await _supabase.auth.signOut();
        log('Successfully signed out from Supabase');
      } catch (e) {
        log('Error signing out from Supabase: $e');
        // Continue with logout process even if Supabase sign out fails
      }

      // Clear SharedPreferences data
      try {
        await _clearUserData();
        log('Successfully cleared all SharedPreferences data');
      } catch (e) {
        log('Error clearing SharedPreferences data: $e');
        // Continue with logout even if clearing SharedPreferences fails
      }

      // Clear local database
      try {
        await DatabaseHelper.instance.clearAllData();
        log('Local database cleared successfully');
      } catch (e) {
        log('Error clearing local database: $e');
        // Continue with logout even if database clearing fails
      }

      emit(const AuthState().copyWith(status: AuthStatus.unauthenticated));
    } catch (e) {
      log('Error during logout: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Method to create stadium manager in Supabase database
  Future<bool> _createStadiumManagerInDatabase(String userId) async {
    try {
      log('Creating stadium in database with ID: $userId');

      // First check if the user ID is a valid UUID format
      final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);

      if (!uuidPattern.hasMatch(userId)) {
        log('ERROR: Invalid UUID format for stadium ID: $userId');
        log('Generating new UUID as fallback');
        userId = _generateUuidV4();
        log('New generated UUID: $userId');
      }

      // Check if stadium already exists
      final existingStadium = await _supabase
          .from('stadiums')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingStadium != null) {
        log('Stadium already exists, updating basic info');
        try {
          // Update the existing stadium with new information
          await _supabase.from('stadiums').update({
            'name': state.userName.isNotEmpty ? state.userName : 'New Stadium',
            'phone_number': state.phoneNumber,
          }).eq('id', userId);

          log('Stadium info updated for ID: $userId');
          return true;
        } catch (updateError) {
          log('ERROR updating existing stadium: $updateError');
          // Continue to try creation below
        }
      }

      log('Creating new stadium with ID: $userId');

      // Create a default address first (or use null for address_id)
      String? addressId;
      try {
        log('Attempting to create default address');
        // Check if addresses table exists and its structure
        try {
          // Simplified address data to avoid schema conflicts
          final addressData = {
            'id': _generateUuidV4(), // Generate a new UUID for the address
            'country': 'Yemen',
            'city': 'Unknown',
            'district': 'Unknown',
            'latitude': 0.0,
            'longitude': 0.0,
            // Exclude any timestamp fields
          };

          log('Address data: $addressData');

          // Try to insert with simplified approach
          final addressResponse = await _supabase
              .from('addresses')
              .insert(addressData)
              .select('id')
              .single();

          addressId = addressResponse['id'];
          log('Created default address with ID: $addressId');
        } catch (addressInsertError) {
          log('Error inserting address: $addressInsertError');

          // Try a more minimal insert as fallback
          try {
            final minimalAddressData = {
              'id': _generateUuidV4(),
              'country': 'Yemen',
              'latitude': 0.0,
              'longitude': 0.0,
            };

            final minimalResponse = await _supabase
                .from('addresses')
                .insert(minimalAddressData)
                .select('id')
                .single();

            addressId = minimalResponse['id'];
            log('Created minimal address with ID: $addressId');
          } catch (minimalAddressError) {
            log('Error with minimal address insert: $minimalAddressError');
            addressId = null;
          }
        }
      } catch (e) {
        log('Error creating default address: $e');
        log('Will continue without address_id');
        addressId = null;
        // Continue without address_id
      }

      // Skip profile creation as it seems the profiles table doesn't exist
      // or has a different structure

      // Create stadium record in Supabase with minimized fields to match actual schema
      final stadiumData = {
        'id': userId, // Keep ID consistent
        'name': state.userName.isNotEmpty ? state.userName : 'New Stadium',
        'phone_number': state.phoneNumber,
        'status': 'pending', // Default status for new stadiums
        'address_id': addressId, // Will be null if address creation failed
        'description': '',
        'bank_number': '',
        'average_review': 0.0, // Default value
        'booked_count': 0, // Default value
        'type': 'standard', // Default type
        // Remove created_at and updated_at fields as they seem to be handled by the database
      };

      log('Inserting stadium data to Supabase: $stadiumData');

      try {
        log('Attempting stadium insert...');

        // Try to determine the required fields for the stadiums table
        final stadiumsStructure =
            await _supabase.from('stadiums').select().limit(1);
        final hasExistingStadiums =
            stadiumsStructure != null && stadiumsStructure.isNotEmpty;

        if (hasExistingStadiums) {
          log('Got existing stadium to use as template');
          // Use the most minimal set of fields actually required by the database
          final minimalRequiredData = {
            'id': userId,
            'name': state.userName.isNotEmpty ? state.userName : 'New Stadium',
            'phone_number': state.phoneNumber,
          };

          // Only add address_id if we successfully created one
          if (addressId != null) {
            minimalRequiredData['address_id'] = addressId;
          }

          // Try inserting with just the minimal required fields
          final insertResponse = await _supabase
              .from('stadiums')
              .insert(minimalRequiredData)
              .select('id');

          log('Stadium insert response: $insertResponse');
          log('Successfully created stadium in database with ID: $userId');
          return true;
        } else {
          // If we couldn't get structure info, try with our best guess of the schema
          log('No existing stadiums found, using best guess of schema');
          final insertResponse = await _supabase.from('stadiums').insert({
            'id': userId,
            'name': state.userName.isNotEmpty ? state.userName : 'New Stadium',
            'phone_number': state.phoneNumber,
            'status': 'pending',
            'address_id': addressId,
          }).select('id');

          log('Stadium insert response: $insertResponse');
          log('Successfully created stadium in database with ID: $userId');
          return true;
        }
      } catch (e) {
        log('Error inserting stadium data: $e');

        // First fallback: try with absolute minimum fields
        try {
          log('Fallback 1: Trying with absolute minimum fields');
          await _supabase.from('stadiums').insert({
            'id': userId,
            'name': state.userName.isNotEmpty ? state.userName : 'New Stadium',
            'phone_number': state.phoneNumber,
          });

          log('Minimal stadium insert successful');
          return true;
        } catch (fallback1Error) {
          log('Fallback 1 failed: $fallback1Error');

          // Second fallback: try upsert instead of insert
          try {
            log('Fallback 2: Trying upsert');
            await _supabase.from('stadiums').upsert({
              'id': userId,
              'name':
                  state.userName.isNotEmpty ? state.userName : 'New Stadium',
              'phone_number': state.phoneNumber,
            });

            log('Stadium upsert successful');
            return true;
          } catch (fallback2Error) {
            log('Fallback 2 failed: $fallback2Error');

            // Final fallback: direct SQL-like approach or give up
            log('All stadium creation attempts failed');
            return false;
          }
        }
      }
    } catch (e) {
      log('CRITICAL ERROR creating stadium in database: $e');
      // Return false to indicate failure
      return false;
    }
  }

  // Method to create owner in Supabase database
  Future<bool> _createOwnerInDatabase(String userId) async {
    try {
      log('Creating owner in database with ID: $userId');

      // First check if the user ID is a valid UUID format
      final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);

      if (!uuidPattern.hasMatch(userId)) {
        log('ERROR: Invalid UUID format for owner ID: $userId');
        log('Generating new UUID as fallback');
        userId = _generateUuidV4();
        log('New generated UUID: $userId');
      }

      // Check if owner already exists
      final existingOwner = await _supabase
          .from('owners')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingOwner != null) {
        log('Owner already exists, updating basic info');
        try {
          // Update the existing owner with new information
          await _supabase.from('owners').update({
            'name': state.userName.isNotEmpty ? state.userName : 'New Owner',
            'phone_number': state.phoneNumber,
          }).eq('id', userId);

          log('Owner info updated for ID: $userId');
          return true;
        } catch (updateError) {
          log('ERROR updating existing owner: $updateError');
          // Continue to try creation below
        }
      }

      log('Creating new owner with ID: $userId');

      // Skip profile creation as it seems the profiles table doesn't exist
      // or has a different structure

      // Create owner record in Supabase with minimized fields
      final ownerData = {
        'id': userId,
        'name': state.userName.isNotEmpty ? state.userName : 'New Owner',
        'phone_number': state.phoneNumber,
        'status': 'active', // Default status
        // Remove timestamps as they seem to be handled by the database
      };

      log('Inserting owner data to Supabase: $ownerData');

      try {
        log('Attempting owner insert...');

        // Try to determine the required fields for the owners table
        final ownersStructure =
            await _supabase.from('owners').select().limit(1);
        final hasExistingOwners =
            ownersStructure != null && ownersStructure.isNotEmpty;

        if (hasExistingOwners) {
          log('Got existing owner to use as template');
          // Use the most minimal set of fields actually required by the database
          final minimalRequiredData = {
            'id': userId,
            'name': state.userName.isNotEmpty ? state.userName : 'New Owner',
            'phone_number': state.phoneNumber,
          };

          // Try inserting with just the minimal required fields
          final insertResponse = await _supabase
              .from('owners')
              .insert(minimalRequiredData)
              .select('id');

          log('Owner insert response: $insertResponse');
          log('Successfully created owner in database with ID: $userId');
          return true;
        } else {
          // If we couldn't get structure info, try with our best guess of the schema
          log('No existing owners found, using best guess of schema');
          final insertResponse = await _supabase.from('owners').insert({
            'id': userId,
            'name': state.userName.isNotEmpty ? state.userName : 'New Owner',
            'phone_number': state.phoneNumber,
            'status': 'active',
          }).select('id');

          log('Owner insert response: $insertResponse');
          log('Successfully created owner in database with ID: $userId');
          return true;
        }
      } catch (e) {
        log('Error inserting owner data: $e');

        // First fallback: try with absolute minimum fields
        try {
          log('Fallback 1: Trying with absolute minimum fields');
          await _supabase.from('owners').insert({
            'id': userId,
            'name': state.userName.isNotEmpty ? state.userName : 'New Owner',
            'phone_number': state.phoneNumber,
          });

          log('Minimal owner insert successful');
          return true;
        } catch (fallback1Error) {
          log('Fallback 1 failed: $fallback1Error');

          // Second fallback: try upsert instead of insert
          try {
            log('Fallback 2: Trying upsert');
            await _supabase.from('owners').upsert({
              'id': userId,
              'name': state.userName.isNotEmpty ? state.userName : 'New Owner',
              'phone_number': state.phoneNumber,
            });

            log('Owner upsert successful');
            return true;
          } catch (fallback2Error) {
            log('Fallback 2 failed: $fallback2Error');

            // Final fallback: direct SQL-like approach or give up
            log('All owner creation attempts failed');
            return false;
          }
        }
      }
    } catch (e) {
      log('CRITICAL ERROR creating owner in database: $e');
      // Return false to indicate failure
      return false;
    }
  }

  // Helper methods for SharedPreferences

  Future<void> _saveUserData(
    String userId,
    String phoneNumber,
    String userName,
    UserType userType,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyIsLoggedIn, true);
      await prefs.setString(keyUserId, userId);
      await prefs.setString(keyPhoneNumber, phoneNumber);
      await prefs.setString(keyUserName, userName);
      await prefs.setString(keyUserType, userType.toString().split('.').last);
      await prefs.setBool(keyIsExistingAccount, state.isExistingAccount);
    } catch (e) {
      log('Error saving user data: $e');
    }
  }

  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all SharedPreferences data completely
      await prefs.clear();
      log('All SharedPreferences data cleared successfully');

      // For backward compatibility, explicitly set these values
      await prefs.setBool(keyIsLoggedIn, false);
    } catch (e) {
      log('Error clearing user data: $e');
    }
  }

  Future<void> _onVerifyPhoneNumber(
    AuthVerifyPhoneNumber event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.phoneVerificationSent,
    ));
  }

  Future<void> _onCodeResendRequested(
    AuthCodeResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // In test mode, just simulate OTP resending
      log('Test mode: Simulating OTP resent to ${state.phoneNumber}');
      emit(state.copyWith(
        status: AuthStatus.phoneVerificationSent,
      ));

      // No need to actually call Supabase since we're in test mode
      /*
      if (!_isTestMode) {
        // In production mode, resend OTP
        await _supabase.auth.signInWithOtp(
          phone: state.phoneNumber,
          shouldCreateUser: true,
        );
        emit(state.copyWith(
          status: AuthStatus.phoneVerificationSent,
        ));
      }
      */
    } catch (e) {
      log('Error resending OTP: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to resend verification code: ${e.toString()}',
      ));
    }
  }
}
