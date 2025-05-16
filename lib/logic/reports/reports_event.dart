import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadReports extends ReportsEvent {
  final String period;

  const LoadReports(this.period);

  @override
  List<Object> get props => [period];
}

class RefreshReports extends ReportsEvent {
  final String period;

  const RefreshReports(this.period);

  @override
  List<Object> get props => [period];
}

class ChangePeriod extends ReportsEvent {
  final String period;

  const ChangePeriod(this.period);

  @override
  List<Object> get props => [period];
}
