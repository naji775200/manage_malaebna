import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../core/utils/auth_utils.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;

  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(const PaymentState()) {
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<RefreshPaymentHistory>(_onRefreshPaymentHistory);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<SearchPayments>(_onSearchPayments);
    on<ExportPaymentData>(_onExportPaymentData);
  }

  void _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      selectedPeriod: event.period,
    ));

    try {
      // Get stadium ID from authenticated user
      final stadiumId = await AuthUtils.getStadiumIdFromAuth();

      if (stadiumId != null) {
        print('🏟️ PaymentBloc: Got stadium ID: $stadiumId');

        // Fetch payments for this stadium
        final List<Payment> payments = await _paymentRepository
            .getPaymentsByStadiumId(stadiumId, forceRefresh: true);

        // Convert payments to transactions format needed by UI
        final transactions = _convertPaymentsToTransactions(payments);

        // Filter by period if needed
        final filteredTransactions = _filterTransactionsByPeriod(
          transactions,
          event.period,
        );

        emit(state.copyWith(
          isLoading: false,
          transactions: filteredTransactions,
          totalRevenue: _calculateTotalRevenue(filteredTransactions),
          transactionCount: filteredTransactions.length,
        ));
      } else {
        print(
            '🏟️ PaymentBloc: No stadium ID found, showing empty payment list');

        // Show empty payments list when no stadium ID found - for security
        emit(state.copyWith(
            isLoading: false,
            transactions: const [],
            totalRevenue: 0.0,
            transactionCount: 0,
            errorMessage:
                'No stadium ID found. Please log in as a stadium owner.'));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load payment history: $e',
      ));
    }
  }

  void _onRefreshPaymentHistory(
    RefreshPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Get stadium ID from authenticated user
      final stadiumId = await AuthUtils.getStadiumIdFromAuth();

      if (stadiumId != null) {
        print('🏟️ PaymentBloc: Got stadium ID for refresh: $stadiumId');

        // Fetch payments for this stadium
        final List<Payment> payments = await _paymentRepository
            .getPaymentsByStadiumId(stadiumId, forceRefresh: true);

        // Convert payments to transactions format needed by UI
        final transactions = _convertPaymentsToTransactions(payments);

        // Filter by current period
        final filteredTransactions = _filterTransactionsByPeriod(
          transactions,
          state.selectedPeriod,
        );

        emit(state.copyWith(
          isLoading: false,
          transactions: filteredTransactions,
          totalRevenue: _calculateTotalRevenue(filteredTransactions),
          transactionCount: filteredTransactions.length,
        ));
      } else {
        print(
            '🏟️ PaymentBloc: No stadium ID found for refresh, showing empty payment list');

        // Show empty payments list when no stadium ID found - for security
        emit(state.copyWith(
            isLoading: false,
            transactions: const [],
            totalRevenue: 0.0,
            transactionCount: 0,
            errorMessage:
                'No stadium ID found. Please log in as a stadium owner.'));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh payment history: $e',
      ));
    }
  }

  void _onFilterByDateRange(
    FilterByDateRange event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      selectedPeriod: 'custom',
      startDate: event.startDate,
      endDate: event.endDate,
    ));

    try {
      // Get stadium ID from authenticated user
      final stadiumId = await AuthUtils.getStadiumIdFromAuth();

      if (stadiumId != null) {
        // Fetch payments for this stadium
        final payments =
            await _paymentRepository.getPaymentsByStadiumId(stadiumId);

        // Convert payments to transactions format needed by UI
        final transactions = _convertPaymentsToTransactions(payments);

        // Filter by date range
        final filteredTransactions = _filterTransactionsByDateRange(
          transactions,
          event.startDate,
          event.endDate,
        );

        emit(state.copyWith(
          isLoading: false,
          transactions: filteredTransactions,
          totalRevenue: _calculateTotalRevenue(filteredTransactions),
          transactionCount: filteredTransactions.length,
        ));
      } else {
        // Security: If no stadium ID, show empty list
        emit(state.copyWith(
            isLoading: false,
            transactions: const [],
            totalRevenue: 0.0,
            transactionCount: 0,
            errorMessage:
                'No stadium ID found. Please log in as a stadium owner.'));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to filter by date range: $e',
      ));
    }
  }

  void _onSearchPayments(
    SearchPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      searchQuery: event.query,
    ));

    try {
      // Get stadium ID from authenticated user
      final stadiumId = await AuthUtils.getStadiumIdFromAuth();

      if (stadiumId != null) {
        // Fetch payments for this stadium
        final payments =
            await _paymentRepository.getPaymentsByStadiumId(stadiumId);

        // Convert payments to transactions format needed by UI
        var transactions = _convertPaymentsToTransactions(payments);

        // First filter by period or date range
        if (state.selectedPeriod == 'custom' &&
            state.startDate != null &&
            state.endDate != null) {
          transactions = _filterTransactionsByDateRange(
            transactions,
            state.startDate!,
            state.endDate!,
          );
        } else {
          transactions = _filterTransactionsByPeriod(
            transactions,
            state.selectedPeriod,
          );
        }

        // Then apply search query if provided
        if (event.query.isNotEmpty) {
          transactions = _filterTransactionsByQuery(
            transactions,
            event.query,
          );
        }

        emit(state.copyWith(
          isLoading: false,
          transactions: transactions,
          totalRevenue: _calculateTotalRevenue(transactions),
          transactionCount: transactions.length,
        ));
      } else {
        // Security: If no stadium ID, show empty list
        emit(state.copyWith(
            isLoading: false,
            transactions: const [],
            totalRevenue: 0.0,
            transactionCount: 0,
            errorMessage:
                'No stadium ID found. Please log in as a stadium owner.'));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to search payments: $e',
      ));
    }
  }

  void _onExportPaymentData(
    ExportPaymentData event,
    Emitter<PaymentState> emit,
  ) async {
    // In a real app, this would export the data to the specified format
    // Here we just handle the event without changing state
    try {
      // Implementation would depend on platform-specific export capabilities
      print('Exporting payment data to ${event.format} format');
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to export payment data: $e',
      ));
    }
  }

  // Helper methods
  List<Map<String, dynamic>> _convertPaymentsToTransactions(
      List<Payment> payments) {
    return payments.map((payment) {
      // Create a transaction object that matches the format expected by the UI
      return {
        'id': payment.id,
        'date': DateTime
            .now(), // TODO: Extract date from createdAt if available in Payment model
        'amount': payment.amount,
        'playerName': 'Player', // TODO: Get from user repository if needed
        'playerId': 'P-${payment.id.substring(0, 5)}',
        'fieldName': 'Field', // TODO: Get from field repository if needed
        'paymentMethod': payment.paymentMethod,
        'status': payment.paymentStatus,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _filterTransactionsByPeriod(
    List<Map<String, dynamic>> transactions,
    String period,
  ) {
    if (period == 'all') {
      return List.from(transactions);
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1); // Default to month
    }

    return transactions.where((transaction) {
      final transactionDate = transaction['date'] as DateTime;
      return transactionDate.isAfter(startDate) ||
          transactionDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  List<Map<String, dynamic>> _filterTransactionsByDateRange(
    List<Map<String, dynamic>> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    // End date is inclusive (end of day)
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return transactions.where((transaction) {
      final date = transaction['date'] as DateTime;
      return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end));
    }).toList();
  }

  List<Map<String, dynamic>> _filterTransactionsByQuery(
    List<Map<String, dynamic>> transactions,
    String query,
  ) {
    final lowercaseQuery = query.toLowerCase();

    return transactions.where((transaction) {
      final playerName = (transaction['playerName'] as String).toLowerCase();
      final fieldName = (transaction['fieldName'] as String).toLowerCase();
      final amount = transaction['amount'] as double;
      final amountString = amount.toString();
      final paymentMethod =
          (transaction['paymentMethod'] as String).toLowerCase();

      return playerName.contains(lowercaseQuery) ||
          fieldName.contains(lowercaseQuery) ||
          amountString.contains(lowercaseQuery) ||
          paymentMethod.contains(lowercaseQuery);
    }).toList();
  }

  double _calculateTotalRevenue(List<Map<String, dynamic>> transactions) {
    return transactions.fold(0.0, (total, transaction) {
      return total + (transaction['amount'] as double);
    });
  }
}
