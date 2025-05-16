import 'package:sqflite/sqflite.dart';
import '../../data/local/database_helper.dart';
import 'dart:async';

/// A utility class that helps enforce security controls throughout the app
class SecurityHelper {
  static bool _initialized = false;

  /// Initialize security measures
  static Future<void> init() async {
    if (_initialized) return;

    print('🔒 SecurityHelper: Initializing security controls');

    try {
      // Check for and clean orphaned payments first
      await _cleanOrphanedPayments(removeOrphaned: true);

      // Then create the security view
      await _createStadiumPaymentsView();

      print('🔒 SecurityHelper: Security controls initialized successfully');
      _initialized = true;
    } catch (e) {
      print('❌ SecurityHelper: Failed to initialize security controls: $e');
    }
  }

  /// Clean up any orphaned payments that don't have proper relationships
  static Future<void> _cleanOrphanedPayments(
      {bool removeOrphaned = false}) async {
    try {
      print('🔒 SecurityHelper: Checking for orphaned payments');
      final db = await DatabaseHelper.instance.database;

      // Find payments that don't have associated bookings
      final orphanedPayments = await db.rawQuery('''
        SELECT p.id, p.amount, p.payment_method 
        FROM payments p
        LEFT JOIN booking b ON p.id = b.payment_id
        WHERE b.id IS NULL
      ''');

      print(
          '🔒 SecurityHelper: Found ${orphanedPayments.length} orphaned payments without bookings');

      // Log details of each orphaned payment
      for (var payment in orphanedPayments) {
        print(
            '🔒 Orphaned payment: ID=${payment['id']}, Amount=${payment['amount']}, Method=${payment['payment_method']}');
      }

      // Find payments with bookings but invalid match -> field -> stadium chain
      final orphanedWithBookings = await db.rawQuery('''
        SELECT p.id, p.amount, p.payment_method, b.id as booking_id, b.match_id
        FROM payments p
        JOIN booking b ON p.id = b.payment_id
        LEFT JOIN matches m ON b.match_id = m.id
        WHERE m.id IS NULL
      ''');

      print(
          '🔒 SecurityHelper: Found ${orphanedWithBookings.length} payments with bookings but invalid matches');

      // Log details of each orphaned payment with booking
      for (var payment in orphanedWithBookings) {
        print(
            '🔒 Orphaned payment with booking: ID=${payment['id']}, Booking ID=${payment['booking_id']}, Match ID=${payment['match_id']}');
      }

      // Find payments with valid booking and match but invalid field
      final orphanedWithMatches = await db.rawQuery('''
        SELECT p.id, p.amount, p.payment_method, m.id as match_id, m.field_id
        FROM payments p
        JOIN booking b ON p.id = b.payment_id
        JOIN matches m ON b.match_id = m.id
        LEFT JOIN fields f ON m.field_id = f.id
        WHERE f.id IS NULL
      ''');

      print(
          '🔒 SecurityHelper: Found ${orphanedWithMatches.length} payments with matches but invalid fields');

      // Log details of each orphaned payment with match
      for (var payment in orphanedWithMatches) {
        print(
            '🔒 Orphaned payment with match: ID=${payment['id']}, Match ID=${payment['match_id']}, Field ID=${payment['field_id']}');
      }

      // Clean up orphaned payments if enabled
      if (removeOrphaned) {
        int removedCount = 0;

        // Remove payments without bookings
        if (orphanedPayments.isNotEmpty) {
          for (var payment in orphanedPayments) {
            final paymentId = payment['id'] as String;
            print('🔒 Removing orphaned payment: $paymentId');
            final result = await db
                .delete('payments', where: 'id = ?', whereArgs: [paymentId]);
            if (result > 0) removedCount++;
          }
        }

        // Remove payments with invalid match links
        if (orphanedWithBookings.isNotEmpty) {
          for (var payment in orphanedWithBookings) {
            final paymentId = payment['id'] as String;
            print('🔒 Removing payment with invalid match link: $paymentId');
            final result = await db
                .delete('payments', where: 'id = ?', whereArgs: [paymentId]);
            if (result > 0) removedCount++;
          }
        }

        // Remove payments with invalid field links
        if (orphanedWithMatches.isNotEmpty) {
          for (var payment in orphanedWithMatches) {
            final paymentId = payment['id'] as String;
            print('🔒 Removing payment with invalid field link: $paymentId');
            final result = await db
                .delete('payments', where: 'id = ?', whereArgs: [paymentId]);
            if (result > 0) removedCount++;
          }
        }

        print('🔒 SecurityHelper: Removed $removedCount orphaned payments');
      }

      print('🔒 SecurityHelper: Orphaned payment check complete');
    } catch (e) {
      print('❌ SecurityHelper: Error checking for orphaned payments: $e');
    }
  }

  /// Create a database view that filters payments by stadium
  static Future<void> _createStadiumPaymentsView() async {
    try {
      print('🔒 SecurityHelper: Creating stadium payments view');
      final db = await DatabaseHelper.instance.database;

      // Drop existing view if it exists
      await db.execute('DROP VIEW IF EXISTS stadium_payments');

      // Create a view that joins payments to stadiums through the relationship chain
      // Use INNER JOINs to ensure that incomplete relationships are excluded
      await db.execute('''
        CREATE VIEW IF NOT EXISTS stadium_payments AS
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

      print('🔒 SecurityHelper: Stadium payments view created successfully');

      // Verify the view works correctly
      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM stadium_payments')) ??
          0;
      print(
          '🔒 SecurityHelper: Stadium payments view contains $count payments');
    } catch (e) {
      print('❌ SecurityHelper: Error creating stadium payments view: $e');
      rethrow;
    }
  }

  /// Run a full cleanup of inconsistent payment data
  static Future<bool> performFullDataCleanup() async {
    try {
      print('🔒 SecurityHelper: Performing full data cleanup');

      // Clean orphaned payments
      await _cleanOrphanedPayments(removeOrphaned: true);

      // Recreate stadium payments view
      await _createStadiumPaymentsView();

      print('🔒 SecurityHelper: Full data cleanup complete');
      return true;
    } catch (e) {
      print('❌ SecurityHelper: Error during full data cleanup: $e');
      return false;
    }
  }
}
