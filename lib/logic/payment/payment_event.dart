import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentHistory extends PaymentEvent {
  final String period;

  const LoadPaymentHistory({this.period = 'month'});

  @override
  List<Object?> get props => [period];
}

class RefreshPaymentHistory extends PaymentEvent {}

class FilterByDateRange extends PaymentEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FilterByDateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class SearchPayments extends PaymentEvent {
  final String query;

  const SearchPayments({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

class SortPayments extends PaymentEvent {
  final String sortBy; // 'date', 'amount', 'player'
  final bool ascending;

  const SortPayments({
    required this.sortBy,
    required this.ascending,
  });

  @override
  List<Object?> get props => [sortBy, ascending];
}

class ExportPaymentData extends PaymentEvent {
  final String format; // 'pdf', 'csv', 'excel'

  const ExportPaymentData({
    required this.format,
  });

  @override
  List<Object?> get props => [format];
}

class ViewTransactionDetails extends PaymentEvent {
  final String transactionId;

  const ViewTransactionDetails({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}
