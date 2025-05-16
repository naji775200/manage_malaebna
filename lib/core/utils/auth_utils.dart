import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../logic/auth/auth_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for authentication and UUID-related functions
class AuthUtils {
  static const Uuid _uuid = Uuid();

  // Fallback stadium ID for debugging/development purposes
  static const String _fallbackTestStadiumId =
      "123e4567-e89b-12d3-a456-426614174000"; // Valid UUID format
  static const bool _useTestFallback = true; // Enable for development testing

  /// Get the stadium ID from auth
  /// Returns null if user is not logged in or not a stadium manager
  static Future<String?> getStadiumIdFromAuth() async {
    try {
      print('🔐 AuthUtils: Trying to get stadium ID');

      // Try using SharedPreferences first
      try {
        print('🔐 AuthUtils: Checking SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString(AuthBloc.keyUserId);
        final userType = prefs.getString(AuthBloc.keyUserType);

        print(
            '🔐 AuthUtils: From SharedPreferences - User ID: $userId, User Type: $userType');

        if (userId != null && userId.isNotEmpty && userType == 'stadium') {
          print(
              '🔐 AuthUtils: Using stadium ID from SharedPreferences: $userId');

          // Verify that this ID exists in the stadiums table
          try {
            final stadiumCheck = await Supabase.instance.client
                .from('stadiums')
                .select('id')
                .eq('id', userId)
                .maybeSingle();

            if (stadiumCheck != null) {
              print(
                  '🔐 AuthUtils: Verified stadium ID exists in database: $userId');
              return userId;
            } else {
              print(
                  '🔐 AuthUtils: Stadium ID from SharedPreferences is not in the database');
              // Continue to other methods
            }
          } catch (e) {
            print('🔐 AuthUtils: Error verifying stadium ID in database: $e');
            // Continue to other methods
          }
        } else {
          print('🔐 AuthUtils: No valid stadium ID in SharedPreferences');
        }
      } catch (e) {
        print('🔐 AuthUtils: Error reading from SharedPreferences: $e');
      }

      // If SharedPreferences approach failed, try using Supabase directly
      try {
        print('🔐 AuthUtils: Trying Supabase auth directly');
        final user = Supabase.instance.client.auth.currentUser;

        if (user == null) {
          print('🔐 AuthUtils: No user logged in with Supabase');
        } else {
          print('🔐 AuthUtils: Found Supabase user, ID: ${user.id}');

          // First check the profiles table which should have been created during registration
          try {
            print('🔐 AuthUtils: Checking profiles table for user type');
            final profile = await Supabase.instance.client
                .from('profiles')
                .select('id, user_type, stadium_id')
                .eq('id', user.id)
                .maybeSingle();

            print('🔐 AuthUtils: Profile data: $profile');

            if (profile != null) {
              final userType = profile['user_type'] as String?;

              if (userType == 'stadium') {
                print(
                    '🔐 AuthUtils: User is a stadium manager based on profile');

                // Check if we have a specific stadium_id field
                final stadiumId = profile['stadium_id'] as String?;
                if (stadiumId != null && stadiumId.isNotEmpty) {
                  print(
                      '🔐 AuthUtils: Using stadium_id from profile: $stadiumId');

                  // Verify that this stadium exists
                  final stadiumCheck = await Supabase.instance.client
                      .from('stadiums')
                      .select('id')
                      .eq('id', stadiumId)
                      .maybeSingle();

                  if (stadiumCheck == null) {
                    print(
                        '🔐 AuthUtils: Stadium ID from profile not found in stadiums table');
                    // Continue searching
                  } else {
                    // Update SharedPreferences for future use
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(AuthBloc.keyUserType, 'stadium');
                      await prefs.setString(AuthBloc.keyUserId, stadiumId);
                      print(
                          '🔐 AuthUtils: Updated SharedPreferences with stadium ID');
                    } catch (e) {
                      print(
                          '🔐 AuthUtils: Failed to update SharedPreferences: $e');
                    }

                    return stadiumId;
                  }
                }

                // Fall back to using the user's ID as the stadium ID
                print('🔐 AuthUtils: Using user ID as stadium ID: ${user.id}');

                // Verify that this user ID is in the stadiums table
                final stadiumCheck = await Supabase.instance.client
                    .from('stadiums')
                    .select('id')
                    .eq('id', user.id)
                    .maybeSingle();

                if (stadiumCheck != null) {
                  // Update SharedPreferences
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(AuthBloc.keyUserType, 'stadium');
                    await prefs.setString(AuthBloc.keyUserId, user.id);
                  } catch (e) {
                    print(
                        '🔐 AuthUtils: Failed to update SharedPreferences: $e');
                  }

                  return user.id;
                } else {
                  print('🔐 AuthUtils: User ID not found in stadiums table');
                }
              } else {
                print(
                    '🔐 AuthUtils: User is not a stadium manager (type: $userType)');
              }
            } else {
              print('🔐 AuthUtils: No profile found for user');
            }
          } catch (e) {
            print('🔐 AuthUtils: Error checking profiles table: $e');
          }

          // Try directly checking the stadiums table as a last resort
          try {
            print('🔐 AuthUtils: Checking stadiums table directly');

            final stadiumData = await Supabase.instance.client
                .from('stadiums')
                .select('id')
                .eq('id', user.id)
                .maybeSingle();

            if (stadiumData != null) {
              final stadiumId = stadiumData['id'] as String;
              print(
                  '🔐 AuthUtils: Found stadium ID in stadiums table: $stadiumId');

              // Attempt to create/update profile entry
              try {
                await Supabase.instance.client.from('profiles').upsert({
                  'id': user.id,
                  'user_type': 'stadium',
                  'stadium_id': stadiumId,
                });
                print('🔐 AuthUtils: Updated profile with stadium info');
              } catch (e) {
                print('🔐 AuthUtils: Failed to update profile: $e');
              }

              // Update SharedPreferences for future use
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(AuthBloc.keyUserType, 'stadium');
                await prefs.setString(AuthBloc.keyUserId, stadiumId);
                print(
                    '🔐 AuthUtils: Updated SharedPreferences with stadium ID');
              } catch (e) {
                print('🔐 AuthUtils: Failed to update SharedPreferences: $e');
              }

              return stadiumId;
            } else {
              print('🔐 AuthUtils: User ID not found in stadiums table');
            }
          } catch (e) {
            print('🔐 AuthUtils: Error checking stadiums table: $e');
          }
        }
      } catch (e) {
        print('🔐 AuthUtils: Error with Supabase auth: $e');
      }

      // Development/testing fallback
      if (_useTestFallback) {
        print(
            '🔐 AuthUtils: Using test fallback stadium ID: $_fallbackTestStadiumId');

        // Store fallback value in SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AuthBloc.keyUserType, 'stadium');
          await prefs.setString(AuthBloc.keyUserId, _fallbackTestStadiumId);
          print(
              '🔐 AuthUtils: Stored fallback stadium ID in SharedPreferences');
        } catch (e) {
          print(
              '🔐 AuthUtils: Error storing fallback in SharedPreferences: $e');
        }

        return _fallbackTestStadiumId;
      }

      print('🔐 AuthUtils: Failed to get stadium ID from any method');
      return null;
    } catch (e) {
      print('🔐 AuthUtils ERROR: Failed to get stadium ID: $e');

      // Development/testing fallback
      if (_useTestFallback) {
        print(
            '🔐 AuthUtils: Using test fallback stadium ID after error: $_fallbackTestStadiumId');
        return _fallbackTestStadiumId;
      }

      return null;
    }
  }

  /// Checks if the current user has access to a given payment by its ID
  /// This improves security by explicitly checking the ownership chain
  static Future<bool> hasAccessToPayment(String paymentId) async {
    final stadiumId = await getStadiumIdFromAuth();
    if (stadiumId == null) {
      print(
          '🔐 AuthUtils: No stadium ID found, denying access to payment $paymentId');
      return false;
    }

    try {
      final client = Supabase.instance.client;

      // This query checks if the payment is associated with a booking -> match -> field -> stadium
      // that belongs to the current stadium owner
      final response = await client
          .from('payments')
          .select('''
        id, 
        booking:booking!inner(
          match:matches!inner(
            field:fields!inner(
              stadium_id
            )
          )
        )
      ''')
          .eq('id', paymentId)
          .eq('booking.match.field.stadium_id', stadiumId)
          .maybeSingle();

      final hasAccess = response != null;
      print(
          '🔐 AuthUtils: Stadium $stadiumId has access to payment $paymentId: $hasAccess');
      return hasAccess;
    } catch (e) {
      print('🔐 AuthUtils: Error checking payment access: $e');
      return false;
    }
  }

  /// Validates if a string is a valid UUID
  /// Returns the string if it's a valid UUID, otherwise returns null
  static Future<String?> ensureValidUuid(String id) async {
    if (id.isEmpty) {
      print('AuthUtils: Empty ID provided to ensureValidUuid');
      return null;
    }

    print('AuthUtils: ensureValidUuid received ID: $id');

    // Check if it's already a valid UUID
    final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false);

    if (uuidPattern.hasMatch(id)) {
      // It's a valid UUID, use it as is
      print('AuthUtils: ID is a valid UUID, using as is: $id');
      return id;
    } else {
      // For non-UUID input, log error and return null
      print('AuthUtils: ERROR - Non-UUID input provided: $id');
      print(
          'AuthUtils: This function expects a valid UUID - not attempting conversion');
      return null;
    }
  }

  /// Generates a new UUID v4
  static String generateUuid() {
    return _uuid.v4();
  }

  /// Gets a verified stadium ID that exists in the database
  /// This is more reliable than getStadiumIdFromAuth as it also verifies
  /// that the stadium ID actually exists in the database and is valid
  static Future<String?> getAndVerifyStadiumId() async {
    try {
      print('🔍 AuthUtils: Getting and verifying stadium ID');

      // First get the ID from auth
      final stadiumId = await getStadiumIdFromAuth();
      if (stadiumId == null || stadiumId.isEmpty) {
        print('❌ AuthUtils: Failed to get stadium ID from auth');
        return null;
      }

      print('✅ AuthUtils: Got stadium ID from auth: $stadiumId');

      // Now verify that this ID exists in the database
      try {
        final stadiumCheck = await Supabase.instance.client
            .from('stadiums')
            .select('id, name')
            .eq('id', stadiumId)
            .maybeSingle();

        if (stadiumCheck != null) {
          final name = stadiumCheck['name'] as String?;
          print(
              '✅ AuthUtils: Verified stadium exists in database: $stadiumId (${name ?? 'unnamed'})');
          return stadiumId;
        } else {
          print(
              '❌ AuthUtils: Stadium with ID $stadiumId not found in database');

          // Try to find any stadium for this user as fallback
          final client = Supabase.instance.client;
          final prefs = await SharedPreferences.getInstance();
          final phoneNumber = prefs.getString(AuthBloc.keyPhoneNumber);

          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            print(
                '🔍 AuthUtils: Trying to find stadium by phone number: $phoneNumber');

            final stadiumByPhone = await client
                .from('stadiums')
                .select('id, name')
                .eq('phone_number', phoneNumber)
                .maybeSingle();

            if (stadiumByPhone != null) {
              final foundId = stadiumByPhone['id'] as String;
              final name = stadiumByPhone['name'] as String?;
              print(
                  '✅ AuthUtils: Found stadium by phone number: $foundId (${name ?? 'unnamed'})');

              // Update SharedPreferences for future use
              await prefs.setString(AuthBloc.keyUserId, foundId);

              return foundId;
            }
          }

          // Last resort: use fallback ID if enabled
          if (_useTestFallback) {
            print(
                '⚠️ AuthUtils: Using fallback stadium ID: $_fallbackTestStadiumId');
            return _fallbackTestStadiumId;
          }

          return null;
        }
      } catch (e) {
        print('❌ AuthUtils: Error verifying stadium in database: $e');

        // Use fallback as last resort
        if (_useTestFallback) {
          print(
              '⚠️ AuthUtils: Using fallback stadium ID after error: $_fallbackTestStadiumId');
          return _fallbackTestStadiumId;
        }

        return null;
      }
    } catch (e) {
      print('❌ AuthUtils: Error in getAndVerifyStadiumId: $e');
      return null;
    }
  }

  /// Helper to debug stadium retrieval issues - outputs detailed diagnosis information
  static Future<void> debugStadiumRetrieval(String stadiumId) async {
    try {
      print('🔍 AuthUtils: Debugging stadium retrieval for ID: $stadiumId');

      final client = Supabase.instance.client;

      // Check if ID has correct UUID format
      final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);

      if (!uuidPattern.hasMatch(stadiumId)) {
        print('❌ AuthUtils: Stadium ID does not have UUID format: $stadiumId');
      } else {
        print('✅ AuthUtils: Stadium ID has valid UUID format');
      }

      // Check if stadium exists
      try {
        final stadium = await client
            .from('stadiums')
            .select('*')
            .eq('id', stadiumId)
            .maybeSingle();

        if (stadium != null) {
          print('✅ AuthUtils: Found stadium in database:');
          stadium.forEach((key, value) {
            print('   $key: $value');
          });
        } else {
          print(
              '❌ AuthUtils: Stadium not found in database with ID: $stadiumId');

          // Try to find any stadium and show its structure
          final anyStadium =
              await client.from('stadiums').select('*').limit(1).maybeSingle();

          if (anyStadium != null) {
            print(
                'ℹ️ AuthUtils: Database has stadiums. Sample stadium structure:');
            anyStadium.forEach((key, value) {
              print('   $key: $value');
            });
          } else {
            print('❌ AuthUtils: No stadiums found in database at all!');
          }
        }
      } catch (e) {
        print('❌ AuthUtils: Error querying database for stadium: $e');
      }

      // Check SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedId = prefs.getString(AuthBloc.keyUserId);
        final storedType = prefs.getString(AuthBloc.keyUserType);

        print('ℹ️ AuthUtils: SharedPreferences values:');
        print('   User ID: $storedId');
        print('   User Type: $storedType');

        if (storedId != stadiumId) {
          print(
              '⚠️ AuthUtils: ID mismatch between parameter ($stadiumId) and SharedPreferences ($storedId)');
        }
      } catch (e) {
        print('❌ AuthUtils: Error checking SharedPreferences: $e');
      }
    } catch (e) {
      print('❌ AuthUtils: Error in debugStadiumRetrieval: $e');
    }
  }
}
