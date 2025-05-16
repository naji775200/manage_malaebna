import 'package:equatable/equatable.dart';

class PaymentState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> transactions;
  final double totalRevenue;
  final int transactionCount;
  final String? errorMessage;
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  const PaymentState({
    this.isLoading = false,
    this.transactions = const [],
    this.totalRevenue = 0.0,
    this.transactionCount = 0,
    this.errorMessage,
    this.selectedPeriod = 'month',
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        isLoading,
        transactions,
        totalRevenue,
        transactionCount,
        errorMessage,
        selectedPeriod,
        startDate,
        endDate,
        searchQuery,
      ];

  PaymentState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? transactions,
    double? totalRevenue,
    int? transactionCount,
    String? errorMessage,
    String? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      transactionCount: transactionCount ?? this.transactionCount,
      errorMessage: errorMessage,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
