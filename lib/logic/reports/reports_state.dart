import 'package:equatable/equatable.dart';

enum ReportsStatus { initial, loading, success, failure }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final List<Map<String, dynamic>> reports;
  final String currentPeriod;
  final String? errorMessage;
  final bool isRefreshing;

  const ReportsState({
    this.status = ReportsStatus.initial,
    this.reports = const [],
    this.currentPeriod = 'week',
    this.errorMessage,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
        status,
        reports,
        currentPeriod,
        errorMessage,
        isRefreshing,
      ];

  ReportsState copyWith({
    ReportsStatus? status,
    List<Map<String, dynamic>>? reports,
    String? currentPeriod,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return ReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Helper getters
  bool get isInitial => status == ReportsStatus.initial;
  bool get isLoading => status == ReportsStatus.loading;
  bool get isSuccess => status == ReportsStatus.success;
  bool get isError => status == ReportsStatus.failure;
  bool get hasReports => reports.isNotEmpty;

  // Calculate summary data
  int get totalBookings {
    return reports.fold(
        0, (sum, report) => sum + (report['bookings'] as int? ?? 0));
  }

  int get totalRevenue {
    return reports.fold(
        0, (sum, report) => sum + (report['revenue'] as int? ?? 0));
  }
}
