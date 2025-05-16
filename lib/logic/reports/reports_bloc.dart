import 'package:flutter_bloc/flutter_bloc.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc() : super(const ReportsState()) {
    on<LoadReports>(_onLoadReports);
    on<RefreshReports>(_onRefreshReports);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoadReports(
    LoadReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.loading));

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock reports based on the period
      final reports = _generateMockReports(event.period);

      emit(state.copyWith(
        status: ReportsStatus.success,
        reports: reports,
        currentPeriod: event.period,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshReports(
    RefreshReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      // Generate mock reports based on the period
      final reports = _generateMockReports(event.period);

      emit(state.copyWith(
        status: ReportsStatus.success,
        reports: reports,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  void _onChangePeriod(
    ChangePeriod event,
    Emitter<ReportsState> emit,
  ) {
    emit(state.copyWith(currentPeriod: event.period));
    add(LoadReports(event.period));
  }

  List<Map<String, dynamic>> _generateMockReports(String period) {
    final reports = <Map<String, dynamic>>[];

    switch (period) {
      case 'day':
        // For day, show hourly reports
        for (int i = 8; i < 22; i++) {
          reports.add({
            'date': '${i < 10 ? '0$i' : i}:00',
            'bookings': (i % 3 + 1) * 2,
            'revenue': (i % 5 + 1) * 150,
          });
        }
        break;
      case 'week':
        // For week, show daily reports
        final days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        for (int i = 0; i < days.length; i++) {
          reports.add({
            'date': days[i],
            'bookings': (i % 3 + 1) * 5,
            'revenue': (i % 5 + 2) * 350,
          });
        }
        break;
      case 'month':
        // For month, show weekly reports
        for (int i = 1; i <= 4; i++) {
          reports.add({
            'week': 'Week $i',
            'bookings': (i % 3 + 2) * 12,
            'revenue': (i % 4 + 3) * 800,
          });
        }
        break;
      case 'year':
        // For year, show monthly reports
        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        for (int i = 0; i < months.length; i++) {
          reports.add({
            'month': months[i],
            'bookings': (i % 5 + 3) * 20,
            'revenue': (i % 6 + 4) * 1500,
          });
        }
        break;
    }

    return reports;
  }
}
