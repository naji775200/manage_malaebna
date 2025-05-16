import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';

class PaymentRemoteDataSource {
  final SupabaseClient _supabaseClient;

  PaymentRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // DEBUG UTILITY: Print payment details to help diagnose phantom payments
  void _debugPayment(dynamic item, String stadiumId) {
    try {
      // Safe way to print values without type assumptions
      void safePrint(String label, dynamic value) {
        print('   > $label: ${value ?? "null"}');
      }

      // Extract ID safely
      String safeId = 'unknown';
      if (item.containsKey('id') && item['id'] != null) {
        safeId = item['id'].toString();
      }
      print('🔍 DEBUG PAYMENT: ID=$safeId');

      // Print basic payment info
      if (item.containsKey('amount')) safePrint('Amount', item['amount']);
      if (item.containsKey('payment_method')) {
        safePrint('Payment Method', item['payment_method']);
      }
      if (item.containsKey('status')) safePrint('Status', item['status']);

      // Handle booking relationship safely
      if (item.containsKey('booking') && item['booking'] != null) {
        final booking = item['booking'];

        print('   > Booking Raw Value: $booking');
        print('   > Booking Type: ${booking.runtimeType}');

        // NEW: Handle case where booking is a List
        if (booking is List) {
          print('   > Booking is a List with ${booking.length} item(s)');

          if (booking.isEmpty) {
            safePrint('Booking List', 'Empty');
            safePrint('Booking ID', 'unknown (empty list)');
          } else {
            // Process first booking in the list
            final firstBooking = booking[0];
            print('   > First Booking in List: $firstBooking');

            if (firstBooking is Map) {
              print('   > First Booking Keys: ${firstBooking.keys.join(', ')}');

              // Extract booking ID from the first booking
              String firstBookingId = 'unknown';
              if (firstBooking.containsKey('id') &&
                  firstBooking['id'] != null) {
                firstBookingId = firstBooking['id'].toString();
                print('   > Found booking ID in first booking["id"]');
              }
              safePrint('Booking ID', firstBookingId);

              // Handle match relationship for the first booking
              if (firstBooking.containsKey('match') &&
                  firstBooking['match'] != null) {
                final match = firstBooking['match'];
                print('   > Match Raw Value: $match');
                print('   > Match Type: ${match.runtimeType}');

                if (match is Map) {
                  print('   > Match Keys: ${match.keys.join(', ')}');

                  // Extract match ID
                  String matchId = 'unknown';
                  if (match.containsKey('id') && match['id'] != null) {
                    matchId = match['id'].toString();
                  }
                  safePrint('Match ID', matchId);

                  // Handle field relationship
                  if (match.containsKey('field') && match['field'] != null) {
                    final field = match['field'];
                    print('   > Field Raw Value: $field');
                    print('   > Field Type: ${field.runtimeType}');

                    if (field is Map) {
                      print('   > Field Keys: ${field.keys.join(', ')}');

                      // Extract field ID
                      String fieldId = 'unknown';
                      if (field.containsKey('id') && field['id'] != null) {
                        fieldId = field['id'].toString();
                      }
                      safePrint('Field ID', fieldId);

                      // Extract stadium ID
                      String actualStadiumId = 'unknown';
                      if (field.containsKey('stadium_id') &&
                          field['stadium_id'] != null) {
                        actualStadiumId = field['stadium_id'].toString();
                      }
                      safePrint('Actual Stadium ID', actualStadiumId);
                      safePrint('Expected Stadium ID', stadiumId);
                      safePrint('MATCH?',
                          actualStadiumId == stadiumId ? 'Yes' : 'No');
                    } else {
                      safePrint('Field', 'Not a Map');
                    }
                  } else {
                    safePrint('Field', 'null or missing');
                  }
                } else if (match is String) {
                  safePrint('Match ID', match);
                  safePrint('Match', 'Direct ID string');
                } else {
                  safePrint('Match', 'Invalid type');
                }
              } else {
                safePrint('Match', 'null or missing');
              }
            } else if (firstBooking is String) {
              safePrint('Booking ID', firstBooking);
              safePrint('Booking', 'Direct ID string');
            } else {
              safePrint('First Booking', 'Invalid type');
            }
          }
        } else if (booking is Map) {
          print('   > Booking Keys: ${booking.keys.join(', ')}');

          // Extract booking ID safely - more detailed checking
          String bookingId = 'unknown';
          if (booking.containsKey('id') && booking['id'] != null) {
            bookingId = booking['id'].toString();
            print('   > Found booking ID in booking["id"]');
          } else {
            print('   > booking["id"] is null or missing');

            // Try to find other possible id fields
            for (var key in booking.keys) {
              if (key.toLowerCase().contains('id')) {
                print('   > Found possible ID field: $key = ${booking[key]}');
              }
            }
          }

          safePrint('Booking ID', bookingId);

          // Handle match relationship safely
          if (booking.containsKey('match') && booking['match'] != null) {
            final match = booking['match'];
            print('   > Match Raw Value: $match');
            print('   > Match Type: ${match.runtimeType}');

            if (match is Map) {
              print('   > Match Keys: ${match.keys.join(', ')}');
            }

            // Extract match ID safely
            String matchId = 'unknown';
            if (match is Map &&
                match.containsKey('id') &&
                match['id'] != null) {
              matchId = match['id'].toString();
            } else if (match is String) {
              matchId = match;
            }
            safePrint('Match ID', matchId);

            // Handle field relationship safely
            if (match is Map &&
                match.containsKey('field') &&
                match['field'] != null) {
              final field = match['field'];
              print('   > Field Raw Value: $field');
              print('   > Field Type: ${field.runtimeType}');

              if (field is Map) {
                print('   > Field Keys: ${field.keys.join(', ')}');
              }

              // Extract field ID safely
              String fieldId = 'unknown';
              if (field is Map &&
                  field.containsKey('id') &&
                  field['id'] != null) {
                fieldId = field['id'].toString();
              } else if (field is String) {
                fieldId = field;
              }
              safePrint('Field ID', fieldId);

              // Extract stadium ID safely
              String actualStadiumId = 'unknown';
              if (field is Map &&
                  field.containsKey('stadium_id') &&
                  field['stadium_id'] != null) {
                actualStadiumId = field['stadium_id'].toString();
              }
              safePrint('Actual Stadium ID', actualStadiumId);
              safePrint('Expected Stadium ID', stadiumId);
              safePrint('MATCH?', actualStadiumId == stadiumId ? 'Yes' : 'No');
            } else {
              safePrint('Field', 'null');
            }
          } else {
            safePrint('Match', 'null');
          }
        } else if (booking is String) {
          // Handle case where booking might be a direct ID string
          String strBookingId = booking;
          print('   > Booking is a string value, using directly as ID');
          safePrint('Booking ID', strBookingId);
        } else {
          safePrint('Booking', 'Invalid type');
        }
      } else {
        safePrint('Booking', 'null');
      }
      print('-------------------------------------------');
    } catch (e) {
      print('🔍 DEBUG PAYMENT ERROR: $e');
      print('🔍 DEBUG PAYMENT ERROR DETAILS: item type = ${item.runtimeType}');
      if (item is Map) {
        print('🔍 DEBUG PAYMENT MAP KEYS: ${item.keys.join(', ')}');
      }
    }
  }

  Future<Payment> getPaymentById(String id, {String? stadiumId}) async {
    if (stadiumId != null) {
      print(
          '🔄 PaymentRemoteDataSource: Getting payment by ID: $id for stadium: $stadiumId');

      try {
        // Get payment with stadium verification
        final response = await _supabaseClient
            .from('payments')
            .select('''
              *,
              booking:booking(
                *,
                match:matches(
                  *,
                  field:fields(*)
                )
              )
            ''')
            .eq('id', id)
            .eq('booking.match.field.stadium_id', stadiumId)
            .single();

        // Remove nested booking data before creating Payment object
        final Map<String, dynamic> paymentData =
            Map<String, dynamic>.from(response);
        paymentData.remove('booking');

        print(
            '✅ PaymentRemoteDataSource: Found payment $id for stadium $stadiumId');
        return Payment.fromJson(paymentData);
      } catch (e) {
        print(
            '❌ PaymentRemoteDataSource: Failed to get payment $id for stadium $stadiumId: $e');
        throw Exception('Payment not found or not authorized for this stadium');
      }
    } else {
      print(
          '🚫 PaymentRemoteDataSource: Security - blocked access to payment without stadium ID');
      throw Exception('Stadium ID required for security reasons');
    }
  }

  Future<List<Payment>> getAllPayments({String? stadiumId}) async {
    if (stadiumId != null) {
      print(
          '🔄 PaymentRemoteDataSource: Getting all payments for stadium: $stadiumId');

      try {
        // Get payments for specific stadium
        final response = await _supabaseClient.from('payments').select('''
              *,
              booking:booking(
                *,
                match:matches(
                  *,
                  field:fields(*)
                )
              )
            ''').eq('booking.match.field.stadium_id', stadiumId);

        // Filter out null responses and map to Payment objects
        final List<Payment> payments = [];

        print(
            '🔄 PaymentRemoteDataSource: Processing ${response.length} payments');

        for (final item in response) {
          try {
            // Verify the payment has complete relationships
            if (!_validatePaymentRelationships(item, stadiumId)) {
              continue;
            }

            // Extract payment data
            final Map<String, dynamic> paymentData =
                Map<String, dynamic>.from(item);

            // Remove nested booking data before creating Payment object
            paymentData.remove('booking');

            // Create payment object with safe error handling
            try {
              final payment = Payment.fromJson(paymentData);
              payments.add(payment);
            } catch (e) {
              print(
                  '❌ PaymentRemoteDataSource: Error creating payment from JSON: $e');
              print('❌ Problematic JSON: $paymentData');
            }
          } catch (e) {
            print(
                '❌ PaymentRemoteDataSource: Error processing payment in getAllPayments: $e');
          }
        }

        print(
            '✅ PaymentRemoteDataSource: Found ${payments.length} payments for stadium $stadiumId');
        return payments;
      } catch (e) {
        print(
            '❌ PaymentRemoteDataSource: Failed to get payments for stadium $stadiumId: $e');
        return [];
      }
    } else {
      print(
          '🚫 PaymentRemoteDataSource: Security - blocked access to all payments without stadium ID');
      return [];
    }
  }

  // Helper method to validate payment relationships
  bool _validatePaymentRelationships(
      Map<String, dynamic> payment, String targetStadiumId) {
    try {
      // Extract booking data (could be a List or a Map)
      final dynamic booking = payment['booking'];
      print(
          '🔍 Validating payment ${payment['id']}, booking type: ${booking?.runtimeType}');

      // Handle booking as a List
      if (booking is List) {
        if (booking.isEmpty) {
          print('⚠️ Payment ${payment['id']} has empty booking list');
          return false;
        }

        // Check each booking in the list to see if any match the stadium
        for (final bookingItem in booking) {
          if (bookingItem is Map) {
            // Extract match from booking
            final dynamic match = bookingItem['match'];

            if (match is Map) {
              // Extract field from match
              final dynamic field = match['field'];

              if (field is Map) {
                // Check if field's stadium_id matches target
                final String? fieldStadiumId = field['stadium_id']?.toString();
                if (fieldStadiumId == targetStadiumId) {
                  print(
                      '✅ Found valid booking→match→field→stadium path in booking list: Match ${match['id']}, Field ${field['id']}, Stadium $fieldStadiumId');
                  return true;
                }
              } else if (field is List && field.isNotEmpty) {
                // Handle field as a list - check first item
                final firstField = field.first;
                if (firstField is Map) {
                  final String? fieldStadiumId =
                      firstField['stadium_id']?.toString();
                  if (fieldStadiumId == targetStadiumId) {
                    print(
                        '✅ Found valid booking→match→field(list)→stadium path: Stadium $fieldStadiumId');
                    return true;
                  }
                }
              }
            } else if (match is List && match.isNotEmpty) {
              // Handle match as a list - check first item
              final firstMatch = match.first;
              if (firstMatch is Map) {
                final dynamic field = firstMatch['field'];

                if (field is Map) {
                  final String? fieldStadiumId =
                      field['stadium_id']?.toString();
                  if (fieldStadiumId == targetStadiumId) {
                    print(
                        '✅ Found valid booking→match(list)→field→stadium path: Stadium $fieldStadiumId');
                    return true;
                  }
                }
              }
            }
          }
        }

        print(
            '⚠️ No matching stadium found in booking list for payment ${payment['id']}');
        return false;
      }
      // Handle booking as a Map
      else if (booking is Map) {
        // Extract match from booking
        final dynamic match = booking['match'];

        if (match is Map) {
          // Extract field from match
          final dynamic field = match['field'];

          if (field is Map) {
            // Check if field's stadium_id matches target
            final String? fieldStadiumId = field['stadium_id']?.toString();
            if (fieldStadiumId == targetStadiumId) {
              print(
                  '✅ Found valid booking→match→field→stadium path: Stadium $fieldStadiumId');
              return true;
            }
          }
        } else if (match is List && match.isNotEmpty) {
          // Handle match as a list - check first item
          final firstMatch = match.first;
          if (firstMatch is Map) {
            final dynamic field = firstMatch['field'];

            if (field is Map) {
              final String? fieldStadiumId = field['stadium_id']?.toString();
              if (fieldStadiumId == targetStadiumId) {
                print(
                    '✅ Found valid booking→match(list)→field→stadium path: Stadium $fieldStadiumId');
                return true;
              }
            }
          }
        }

        // If we reach here, try checking for direct stadium_id in booking
        final String? bookingStadiumId = booking['stadium_id']?.toString();
        if (bookingStadiumId == targetStadiumId) {
          print('✅ Found direct stadium_id in booking: $bookingStadiumId');
          return true;
        }

        print(
            '⚠️ No matching stadium found in booking for payment ${payment['id']}');
        return false;
      }

      print(
          '⚠️ Payment ${payment['id']} has missing or invalid booking (${booking?.runtimeType})');
      return false;
    } catch (e) {
      print('❌ Error validating payment relationships: $e');
      return false;
    }
  }

  Future<List<Payment>> getPaymentsByStatus(String status,
      {String? stadiumId}) async {
    if (stadiumId != null) {
      print(
          '🔄 PaymentRemoteDataSource: Getting payments by status: $status for stadium: $stadiumId');

      try {
        // Get payments by status for specific stadium
        final response = await _supabaseClient
            .from('payments')
            .select('''
              *,
              booking:booking(
                *,
                match:matches(
                  *,
                  field:fields(*)
                )
              )
            ''')
            .eq('status', status)
            .eq('booking.match.field.stadium_id', stadiumId);

        final List<Payment> payments = [];
        for (final item in response) {
          try {
            // Verify the payment has complete relationships
            if (!_validatePaymentRelationships(item, stadiumId)) {
              continue;
            }

            // Extract payment data
            final Map<String, dynamic> paymentData =
                Map<String, dynamic>.from(item);

            // Remove nested booking data before creating Payment object
            paymentData.remove('booking');

            // Create payment object with safe error handling
            try {
              final payment = Payment.fromJson(paymentData);
              payments.add(payment);
            } catch (e) {
              print(
                  '❌ PaymentRemoteDataSource: Error creating payment from JSON: $e');
              print('❌ Problematic JSON: $paymentData');
            }
          } catch (e) {
            print('❌ PaymentRemoteDataSource: Error processing payment: $e');
          }
        }
        print(
            '✅ PaymentRemoteDataSource: Found ${payments.length} payments with status $status for stadium $stadiumId');
        return payments;
      } catch (e) {
        print(
            '❌ PaymentRemoteDataSource: Failed to get payments with status $status for stadium $stadiumId: $e');
        return [];
      }
    } else {
      print(
          '🚫 PaymentRemoteDataSource: Security - blocked access to payments by status without stadium ID');
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByPaymentStatus(String paymentStatus,
      {String? stadiumId}) async {
    if (stadiumId != null) {
      print(
          '🔄 PaymentRemoteDataSource: Getting payments by payment status: $paymentStatus for stadium: $stadiumId');

      try {
        // Get payments by payment status for specific stadium
        final response = await _supabaseClient
            .from('payments')
            .select('''
              *,
              booking:booking(
                *,
                match:matches(
                  *,
                  field:fields(*)
                )
              )
            ''')
            .eq('payment_status', paymentStatus)
            .eq('booking.match.field.stadium_id', stadiumId);

        final List<Payment> payments = [];
        for (final item in response) {
          try {
            // Verify the payment has complete relationships
            if (!_validatePaymentRelationships(item, stadiumId)) {
              continue;
            }

            // Extract payment data
            final Map<String, dynamic> paymentData =
                Map<String, dynamic>.from(item);

            // Remove nested booking data before creating Payment object
            paymentData.remove('booking');

            // Create payment object with safe error handling
            try {
              final payment = Payment.fromJson(paymentData);
              payments.add(payment);
            } catch (e) {
              print(
                  '❌ PaymentRemoteDataSource: Error creating payment from JSON: $e');
              print('❌ Problematic JSON: $paymentData');
            }
          } catch (e) {
            print('❌ PaymentRemoteDataSource: Error processing payment: $e');
          }
        }
        print(
            '✅ PaymentRemoteDataSource: Found ${payments.length} payments with payment status $paymentStatus for stadium $stadiumId');
        return payments;
      } catch (e) {
        print(
            '❌ PaymentRemoteDataSource: Failed to get payments with payment status $paymentStatus for stadium $stadiumId: $e');
        return [];
      }
    } else {
      print(
          '🚫 PaymentRemoteDataSource: Security - blocked access to payments by payment status without stadium ID');
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByStadiumId(String stadiumId) async {
    try {
      print(
          '🔄 PaymentRemoteDataSource: Getting payments for stadium ID: $stadiumId');

      // First, run a diagnostic query to debug the relationship chain
      try {
        final diagnosticResponse =
            await _supabaseClient.from('payments').select('''
              id, amount, payment_method, status,
              booking:booking(
                id,
                match:matches(
                  id,
                  field:fields(
                    id, stadium_id
                  )
                )
              )
            ''');

        print(
            '🔄 PaymentRemoteDataSource: Running diagnostic check on ${diagnosticResponse.length} payments');

        // Analyze the results to see which payments are being improperly associated
        for (final item in diagnosticResponse) {
          _debugPayment(item, stadiumId);
                }
      } catch (e) {
        print('❌ PaymentRemoteDataSource: Error running diagnostic query: $e');
        // Continue with main query even if diagnostic fails
      }

      // As specifically requested, run the query through booking→match→field→stadium path
      print(
          '🔄 PaymentRemoteDataSource: Running relationship query (booking → match → field → stadium)');

      // First try with the booking array format - select all payments with a booking array that contains
      // at least one booking with a match that has a field with the specified stadium_id
      final List<Payment> payments = [];

      try {
        // Query using array index access for bookings - trying to find payments where booking[0] matches the stadium
        final response = await _supabaseClient.from('payments').select('''
          *,
          booking:booking(
            id,
            match:matches(
              id,
              field:fields(
                id, stadium_id
              )
            )
          )
        ''');

        print(
            '🔄 PaymentRemoteDataSource: Found ${response.length} payments to check');

        // Manual filtering since we need complex relationship checking
        for (final item in response) {
          if (_validatePaymentRelationships(item, stadiumId)) {
            try {
              final paymentData = Map<String, dynamic>.from(item);
              paymentData.remove('booking'); // Remove nested booking data

              final payment = Payment.fromJson(paymentData);
              payments.add(payment);
              print(
                  '✅ PaymentRemoteDataSource: Added valid payment: ${payment.id}');
            } catch (e) {
              print(
                  '❌ PaymentRemoteDataSource: Error creating payment from JSON: $e');
            }
          }
                }

        print(
            '🔄 PaymentRemoteDataSource: Found ${payments.length} valid payments for stadium after validation');

        // If we have payments, return them - otherwise continue with fallback approaches
        if (payments.isNotEmpty) {
          return payments;
        }
      } catch (e) {
        print('❌ PaymentRemoteDataSource: Error with booking array query: $e');
        // Continue with fallback approaches
      }

      // Only try direct stadium ID approach if the primary approach failed
      try {
        print(
            '🔄 PaymentRemoteDataSource: Trying alternative direct stadium ID query');
        final directResponse = await _supabaseClient
            .from('payments')
            .select('*')
            .eq('stadium_id', stadiumId);

        if (directResponse.isNotEmpty) {
          print(
              '🔄 PaymentRemoteDataSource: Found ${directResponse.length} payments with direct stadium ID');

          // Process these payments directly - no relationship validation needed
          for (final item in directResponse) {
            try {
              final payment =
                  Payment.fromJson(Map<String, dynamic>.from(item));
              payments.add(payment);
              print(
                  '✅ PaymentRemoteDataSource: Added payment (direct): ${payment.id}');
            } catch (e) {
              print(
                  '❌ PaymentRemoteDataSource: Error creating payment from direct JSON: $e');
            }
                    }

          if (payments.isNotEmpty) {
            print(
                '🔄 PaymentRemoteDataSource: Returning ${payments.length} direct payments');
            return payments;
          } else {
            print(
                '⚠️ PaymentRemoteDataSource: No valid direct payments found, trying final fallback approach');
          }
        } else {
          print(
              '⚠️ PaymentRemoteDataSource: No direct stadium ID payments found, trying final fallback approach');
        }
      } catch (e) {
        print('⚠️ PaymentRemoteDataSource: Direct stadium ID query failed: $e');
        // Continue with final fallback approach
      }

      // One final try with a simple booking.stadium_id approach
      try {
        print(
            '⚠️ PaymentRemoteDataSource: Trying final fallback approach with booking.stadium_id');

        final fallbackResponse = await _supabaseClient
            .from('payments')
            .select('*, booking(*)')
            .eq('booking.stadium_id', stadiumId);

        print(
            '🔄 PaymentRemoteDataSource: Fallback query found ${fallbackResponse.length} results');

        for (final item in fallbackResponse) {
          try {
            final paymentData = Map<String, dynamic>.from(item);
            paymentData.remove('booking'); // Remove booking data

            final payment = Payment.fromJson(paymentData);
            payments.add(payment);
            print(
                '✅ PaymentRemoteDataSource: Added payment (fallback): ${payment.id}');
          } catch (e) {
            print(
                '❌ PaymentRemoteDataSource: Error processing fallback payment: $e');
          }
                }
      } catch (e) {
        print('⚠️ PaymentRemoteDataSource: Fallback query failed: $e');
      }

      print(
          '🔄 PaymentRemoteDataSource: Returning ${payments.length} payments for stadium ID: $stadiumId');
      return payments;
    } catch (e) {
      print(
          '❌ PaymentRemoteDataSource: Error getting payments for stadium: $e');
      return [];
    }
  }

  Future<Payment> createPayment(Payment payment) async {
    final response = await _supabaseClient
        .from('payments')
        .insert(payment.toJson())
        .select()
        .single();
    return Payment.fromJson(response);
  }

  Future<Payment> updatePayment(Payment payment) async {
    final response = await _supabaseClient
        .from('payments')
        .update(payment.toJson())
        .eq('id', payment.id)
        .select()
        .single();
    return Payment.fromJson(response);
  }

  Future<void> deletePayment(String id) async {
    await _supabaseClient.from('payments').delete().eq('id', id);
  }
}
