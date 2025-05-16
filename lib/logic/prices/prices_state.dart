import 'package:equatable/equatable.dart';
import '../../data/models/price_model.dart';

abstract class PricesState extends Equatable {
  const PricesState();

  @override
  List<Object?> get props => [];
}

class PricesInitial extends PricesState {}

class PricesLoading extends PricesState {}

class PricesLoaded extends PricesState {
  final List<Price> prices;

  const PricesLoaded({required this.prices});

  @override
  List<Object?> get props => [prices];
}

class PricesError extends PricesState {
  final String message;

  const PricesError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PriceCreated extends PricesState {
  final Price price;

  const PriceCreated({required this.price});

  @override
  List<Object?> get props => [price];
}

class PriceUpdated extends PricesState {
  final Price price;

  const PriceUpdated({required this.price});

  @override
  List<Object?> get props => [price];
}

class PriceDeleted extends PricesState {
  final String priceId;

  const PriceDeleted({required this.priceId});

  @override
  List<Object?> get props => [priceId];
}
