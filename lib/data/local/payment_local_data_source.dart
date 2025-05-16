import '../models/payment_model.dart';
import 'base_local_data_source.dart';
import 'package:sqflite/sqflite.dart';

class PaymentLocalDataSource extends BaseLocalDataSource<Payment> {
  PaymentLocalDataSource() : super('payments') {
    // Initialize the stadium filter view
    _createStadiumPaymentsView();
  }

  // Query to join payments to stadium through relationship chain with INNER JOINS
  // to ensure only payments with proper relationships are included
  String get _paymentsStadiumJoinQuery => '''
    SELECT DISTINCT p.* FROM payments p
    INNER JOIN booking b ON p.id = b.payment_id
    INNER JOIN matches m ON b.match_id = m.id
    INNER JOIN fields f ON m.field_id = f.id
  ''';

  // Create a view that filters payments by stadium
  Future<void> _createStadiumPaymentsView() async {
    try {
      print('📊 PaymentLocalDataSource: Creating stadium payments view');
      final db = await database;

      // Drop the existing view if it exists
      await db.execute('DROP VIEW IF EXISTS stadium_payments');

      // First analyze all payment relationships to debug issues
      _analyzePaymentsWithStadiums();

      // Create a view that joins payments to stadiums through the relationship chain
      // with INNER JOINs to ensure only complete relationships are included
      await db.execute('''
        CREATE VIEW stadium_payments AS
        SELECT 
          p.*,
          f.stadium_id
        FROM 
          payments p
        INNER JOIN 
          booking b ON p.id = b.payment_id
        INNER JOIN 
          matches m ON b.match_id = m.id
        INNER JOIN 
          fields f ON m.field_id = f.id
      ''');

      print(
          '📊 PaymentLocalDataSource: Stadium payments view created successfully');

      // Verify the view has correct data
      await _verifyStadiumPaymentsView();
    } catch (e) {
      print(
          '❌ PaymentLocalDataSource: Error creating stadium payments view: $e');
    }
  }

  // Analyze payment relationships for debugging
  Future<void> _analyzePaymentsWithStadiums() async {
    try {
      final db = await database;
      print('🔍 PaymentLocalDataSource: Analyzing all payment relationships');

      // Get all payments
      final payments = await db.query('payments');
      print('🔍 Found ${payments.length} total payments in database');

      // Check booking relationships
      for (var payment in payments) {
        final paymentId = payment['id'] as String;
        print('🔍 Payment ID: $paymentId');

        // Find booking
        final bookings = await db.query(
          'booking',
          where: 'payment_id = ?',
          whereArgs: [paymentId],
        );

        if (bookings.isEmpty) {
          print('⚠️ Payment $paymentId has no associated booking');
          continue;
        }

        final booking = bookings.first;
        final bookingId = booking['id'] as String;
        final matchId = booking['match_id'] as String?;
        print('🔍   Booking ID: $bookingId, Match ID: $matchId');

        if (matchId == null) {
          print('⚠️ Booking $bookingId has no match_id');
          continue;
        }

        // Find match
        final matches = await db.query(
          'matches',
          where: 'id = ?',
          whereArgs: [matchId],
        );

        if (matches.isEmpty) {
          print('⚠️ Match $matchId not found for payment $paymentId');
          continue;
        }

        final match = matches.first;
        final fieldId = match['field_id'] as String?;
        print('🔍   Field ID: $fieldId');

        if (fieldId == null) {
          print('⚠️ Match $matchId has no field_id');
          continue;
        }

        // Find field
        final fields = await db.query(
          'fields',
          where: 'id = ?',
          whereArgs: [fieldId],
        );

        if (fields.isEmpty) {
          print('⚠️ Field $fieldId not found for match $matchId');
          continue;
        }

        final field = fields.first;
        final stadiumId = field['stadium_id'] as String?;
        print('🔍   Stadium ID: $stadiumId');

        if (stadiumId == null) {
          print('⚠️ Field $fieldId has no stadium_id');
          continue;
        }

        print(
            '✅ Payment $paymentId has valid relationship to stadium $stadiumId');
      }
    } catch (e) {
      print('❌ Error analyzing payment relationships: $e');
    }
  }

  // Verify stadium payments view has correct data
  Future<void> _verifyStadiumPaymentsView() async {
    try {
      final db = await database;

      // Check if view exists and has correct data
      final stadiums =
          await db.rawQuery('SELECT DISTINCT stadium_id FROM stadium_payments');
      print('🔍 Stadium payments view has ${stadiums.length} unique stadiums');

      for (var stadium in stadiums) {
        final stadiumId = stadium['stadium_id'] as String?;
        final count = Sqflite.firstIntValue(await db.rawQuery(
                'SELECT COUNT(*) FROM stadium_payments WHERE stadium_id = ?',
                [stadiumId])) ??
            0;

        print('🔍 Stadium $stadiumId has $count payments in view');
      }
    } catch (e) {
      print('❌ Error verifying stadium payments view: $e');
    }
  }

  Future<Payment?> getPaymentById(String id, {String? stadiumId}) async {
    final db = await database;

    if (stadiumId != null) {
      print(
          '📊 PaymentLocalDataSource: Getting payment by ID $id for stadium $stadiumId');

      // Use the view for better performance
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT * FROM stadium_payments 
        WHERE id = ? AND stadium_id = ?
      ''', [id, stadiumId]);

      if (results.isEmpty) {
        print(
            '📊 PaymentLocalDataSource: No payment found with ID $id for stadium $stadiumId');
        return null;
      }

      print(
          '📊 PaymentLocalDataSource: Found payment with ID $id for stadium $stadiumId');
      return Payment.fromJson(results.first);
    } else {
      print(
          '⚠️ PaymentLocalDataSource: Getting payment by ID without stadium filter - RESTRICTED');
      // For security, don't return any payment if no stadium ID provided
      return null;
    }
  }

  Future<List<Payment>> getAllPayments({String? stadiumId}) async {
    final db = await database;

    if (stadiumId != null) {
      print(
          '📊 PaymentLocalDataSource: Getting all payments for stadium $stadiumId');

      // Use the view for better performance
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT * FROM stadium_payments 
        WHERE stadium_id = ?
      ''', [stadiumId]);

      print(
          '📊 PaymentLocalDataSource: Found ${results.length} payments for stadium $stadiumId');
      return results.map((map) => Payment.fromJson(map)).toList();
    } else {
      print(
          '⚠️ PaymentLocalDataSource: Getting all payments without stadium filter - RESTRICTED');
      // For security, return empty list if no stadium ID provided
      return [];
    }
  }

  Future<String> insertPayment(Payment payment) async {
    return await insert(payment.toJson());
  }

  Future<int> updatePayment(Payment payment) async {
    return await update(payment.toJson());
  }

  Future<int> deletePayment(String id) async {
    return await delete(id);
  }

  Future<List<Payment>> getPaymentsByStatus(String status,
      {String? stadiumId}) async {
    final db = await database;

    if (stadiumId != null) {
      print(
          '📊 PaymentLocalDataSource: Getting payments with status $status for stadium $stadiumId');

      // Use the view for better performance
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT * FROM stadium_payments 
        WHERE status = ? AND stadium_id = ?
      ''', [status, stadiumId]);

      print(
          '📊 PaymentLocalDataSource: Found ${results.length} payments with status $status for stadium $stadiumId');
      return results.map((map) => Payment.fromJson(map)).toList();
    } else {
      print(
          '⚠️ PaymentLocalDataSource: Getting payments by status without stadium filter - RESTRICTED');
      // For security, return empty list if no stadium ID provided
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByPaymentStatus(String paymentStatus,
      {String? stadiumId}) async {
    final db = await database;

    if (stadiumId != null) {
      print(
          '📊 PaymentLocalDataSource: Getting payments with payment status $paymentStatus for stadium $stadiumId');

      // Use the view for better performance
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT * FROM stadium_payments 
        WHERE payment_status = ? AND stadium_id = ?
      ''', [paymentStatus, stadiumId]);

      print(
          '📊 PaymentLocalDataSource: Found ${results.length} payments with payment status $paymentStatus for stadium $stadiumId');
      return results.map((map) => Payment.fromJson(map)).toList();
    } else {
      print(
          '⚠️ PaymentLocalDataSource: Getting payments by payment status without stadium filter - RESTRICTED');
      // For security, return empty list if no stadium ID provided
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByStadiumId(String stadiumId) async {
    try {
      print(
          '📊 PaymentLocalDataSource: Getting payments for stadium $stadiumId');
      final db = await database;

      // First count how many should exist - for debugging only
      final countCheck = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM payments p
        INNER JOIN booking b ON p.id = b.payment_id
        INNER JOIN matches m ON b.match_id = m.id
        INNER JOIN fields f ON m.field_id = f.id
        WHERE f.stadium_id = ?
      ''', [stadiumId])) ?? 0;

      print(
          '📊 Direct count check shows $countCheck payments for stadium $stadiumId');

      try {
        // Use the view for better performance
        final List<Map<String, dynamic>> results = await db.rawQuery('''
          SELECT * FROM stadium_payments 
          WHERE stadium_id = ?
        ''', [stadiumId]);

        // Print detailed information about each payment for debugging
        for (var result in results) {
          print('📊 Found payment ${result['id']} for stadium $stadiumId');
          print(
              '    Amount: ${result['amount']}, Method: ${result['payment_method']}');

          // Verify this payment actually belongs to this stadium with direct query
          final directCheck = await db.rawQuery('''
            SELECT f.stadium_id FROM payments p
            INNER JOIN booking b ON p.id = b.payment_id
            INNER JOIN matches m ON b.match_id = m.id
            INNER JOIN fields f ON m.field_id = f.id
            WHERE p.id = ?
          ''', [result['id']]);

          if (directCheck.isEmpty) {
            print(
                '⚠️ Payment ${result['id']} has no valid stadium relationship!');
          } else {
            print(
                '    Direct check stadium_id: ${directCheck.first['stadium_id']}');
          }
        }

        print(
            '📊 PaymentLocalDataSource: Found ${results.length} payments for stadium $stadiumId');

        // Add additional error handling during conversion
        final List<Payment> payments = [];
        for (var map in results) {
          try {
            payments.add(Payment.fromJson(map));
          } catch (e) {
            print(
                '❌ PaymentLocalDataSource: Error converting payment data: $e');
            print('❌ Problematic payment data: $map');
          }
        }

        print(
            '📊 PaymentLocalDataSource: Successfully converted ${payments.length} payments');
        return payments;
      } catch (e) {
        print(
            '❌ PaymentLocalDataSource: Error using stadium_payments view: $e');

        // Fallback to direct query if view fails
        print('📊 PaymentLocalDataSource: Trying direct query fallback');
        final List<Map<String, dynamic>> fallbackResults = await db.rawQuery('''
          SELECT p.* FROM payments p
          INNER JOIN booking b ON p.id = b.payment_id
          INNER JOIN matches m ON b.match_id = m.id
          INNER JOIN fields f ON m.field_id = f.id
          WHERE f.stadium_id = ?
        ''', [stadiumId]);

        print(
            '📊 PaymentLocalDataSource: Fallback found ${fallbackResults.length} payments');

        // Add additional error handling during conversion for fallback
        final List<Payment> payments = [];
        for (var map in fallbackResults) {
          try {
            payments.add(Payment.fromJson(map));
          } catch (e) {
            print(
                '❌ PaymentLocalDataSource: Error converting payment data in fallback: $e');
            print('❌ Problematic payment data: $map');
          }
        }

        return payments;
      }
    } catch (e) {
      print('❌ PaymentLocalDataSource: Error getting payments for stadium: $e');
      return [];
    }
  }
}
