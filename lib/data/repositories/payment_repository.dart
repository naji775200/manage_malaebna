import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/payment_local_data_source.dart';
import '../models/payment_model.dart';
import '../remote/payment_remote_data_source.dart';
import '../../core/utils/auth_utils.dart';

class PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;
  final PaymentLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  PaymentRepository({
    required PaymentRemoteDataSource remoteDataSource,
    required PaymentLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Helper method to verify a payment belongs to a stadium
  Future<bool> _verifyPaymentBelongsToStadium(
      String paymentId, String stadiumId) async {
    try {
      // Use Auth utils to check the payment access
      return await AuthUtils.hasAccessToPayment(paymentId);
    } catch (e) {
      print('❌ PaymentRepository: Error verifying payment access: $e');
      return false;
    }
  }

  Future<Payment> getPaymentById(String id, {bool forceRefresh = false}) async {
    // Get stadium ID from auth
    final stadiumId = await AuthUtils.getStadiumIdFromAuth();

    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePayment =
            await _remoteDataSource.getPaymentById(id, stadiumId: stadiumId);
        await _localDataSource.insertPayment(remotePayment);
        return remotePayment;
      } catch (e) {
        final localPayment =
            await _localDataSource.getPaymentById(id, stadiumId: stadiumId);
        if (localPayment != null) {
          return localPayment;
        }
        rethrow;
      }
    } else {
      final localPayment =
          await _localDataSource.getPaymentById(id, stadiumId: stadiumId);
      if (localPayment != null) {
        return localPayment;
      }
      throw Exception('No internet connection and payment not found locally');
    }
  }

  Future<List<Payment>> getAllPayments({bool forceRefresh = false}) async {
    // Get stadium ID from auth
    final stadiumId = await AuthUtils.getStadiumIdFromAuth();

    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePayments =
            await _remoteDataSource.getAllPayments(stadiumId: stadiumId);
        for (var payment in remotePayments) {
          await _localDataSource.insertPayment(payment);
        }
        return remotePayments;
      } catch (e) {
        return await _localDataSource.getAllPayments(stadiumId: stadiumId);
      }
    } else {
      return await _localDataSource.getAllPayments(stadiumId: stadiumId);
    }
  }

  Future<List<Payment>> getPaymentsByStatus(String status,
      {bool forceRefresh = false}) async {
    // Get stadium ID from auth
    final stadiumId = await AuthUtils.getStadiumIdFromAuth();

    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePayments = await _remoteDataSource
            .getPaymentsByStatus(status, stadiumId: stadiumId);
        for (var payment in remotePayments) {
          await _localDataSource.insertPayment(payment);
        }
        return remotePayments;
      } catch (e) {
        return await _localDataSource.getPaymentsByStatus(status,
            stadiumId: stadiumId);
      }
    } else {
      return await _localDataSource.getPaymentsByStatus(status,
          stadiumId: stadiumId);
    }
  }

  Future<List<Payment>> getPaymentsByPaymentStatus(String paymentStatus,
      {bool forceRefresh = false}) async {
    // Get stadium ID from auth
    final stadiumId = await AuthUtils.getStadiumIdFromAuth();

    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePayments = await _remoteDataSource
            .getPaymentsByPaymentStatus(paymentStatus, stadiumId: stadiumId);
        for (var payment in remotePayments) {
          await _localDataSource.insertPayment(payment);
        }
        return remotePayments;
      } catch (e) {
        return await _localDataSource.getPaymentsByPaymentStatus(paymentStatus,
            stadiumId: stadiumId);
      }
    } else {
      return await _localDataSource.getPaymentsByPaymentStatus(paymentStatus,
          stadiumId: stadiumId);
    }
  }

  Future<List<Payment>> getPaymentsByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    print('🔄 PaymentRepository: Getting payments for stadium ID: $stadiumId');

    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remotePayments =
            await _remoteDataSource.getPaymentsByStadiumId(stadiumId);

        if (remotePayments.isEmpty) {
          print(
              '⚠️ PaymentRepository: Remote source returned no payments for stadium $stadiumId. Checking local cache...');
          // Fall back to local data if remote is empty
          final localPayments = await _getVerifiedLocalPayments(stadiumId);
          if (localPayments.isNotEmpty) {
            print(
                '✅ PaymentRepository: Found ${localPayments.length} payments in local cache');
            return localPayments;
          }
          print(
              '⚠️ PaymentRepository: No payments found in local cache either');
          return [];
        }

        // Verify each payment belongs to this stadium
        final List<Payment> verifiedPayments = [];

        for (var payment in remotePayments) {
          final isValid =
              await _verifyPaymentBelongsToStadium(payment.id, stadiumId);
          if (isValid) {
            // Cache verified payments
            await _localDataSource.insertPayment(payment);
            verifiedPayments.add(payment);
            print(
                '✅ PaymentRepository: Verified payment ${payment.id} belongs to stadium $stadiumId');
          } else {
            print(
                '⚠️ PaymentRepository: Payment ${payment.id} does NOT belong to stadium $stadiumId - SKIPPING');
          }
        }

        print(
            '🔄 PaymentRepository: Returning ${verifiedPayments.length} verified payments');
        return verifiedPayments;
      } catch (e) {
        print(
            '❌ PaymentRepository: Error fetching payments from remote source: $e');
        // Fallback to local data
        return await _getVerifiedLocalPayments(stadiumId);
      }
    } else {
      // No internet, use local data
      return await _getVerifiedLocalPayments(stadiumId);
    }
  }

  // Helper to get verified local payments
  Future<List<Payment>> _getVerifiedLocalPayments(String stadiumId) async {
    try {
      final localPayments =
          await _localDataSource.getPaymentsByStadiumId(stadiumId);

      // Double-check each payment belongs to this stadium
      final List<Payment> verifiedPayments = [];

      for (var payment in localPayments) {
        final isValid =
            await _verifyPaymentBelongsToStadium(payment.id, stadiumId);
        if (isValid) {
          verifiedPayments.add(payment);
          print(
              '✅ PaymentRepository: Verified local payment ${payment.id} belongs to stadium $stadiumId');
        } else {
          print(
              '⚠️ PaymentRepository: Local payment ${payment.id} does NOT belong to stadium $stadiumId - SKIPPING');
        }
      }

      print(
          '🔄 PaymentRepository: Returning ${verifiedPayments.length} verified local payments');
      return verifiedPayments;
    } catch (e) {
      print('❌ PaymentRepository: Error fetching local payments: $e');
      return [];
    }
  }

  Future<Payment> createPayment(Payment payment) async {
    if (await _hasInternetConnection()) {
      final createdPayment = await _remoteDataSource.createPayment(payment);
      await _localDataSource.insertPayment(createdPayment);
      return createdPayment;
    } else {
      throw Exception('No internet connection. Cannot create payment.');
    }
  }

  Future<Payment> updatePayment(Payment payment) async {
    if (await _hasInternetConnection()) {
      final updatedPayment = await _remoteDataSource.updatePayment(payment);
      await _localDataSource.updatePayment(updatedPayment);
      return updatedPayment;
    } else {
      throw Exception('No internet connection. Cannot update payment.');
    }
  }

  Future<void> deletePayment(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deletePayment(id);
      await _localDataSource.deletePayment(id);
    } else {
      throw Exception('No internet connection. Cannot delete payment.');
    }
  }
}
