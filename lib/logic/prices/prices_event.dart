import 'package:equatable/equatable.dart';
import '../../data/models/price_model.dart';

abstract class PricesEvent extends Equatable {
  const PricesEvent();

  @override
  List<Object?> get props => [];
}

class PricesLoadEvent extends PricesEvent {
  final String fieldId;
  final bool forceRefresh;

  const PricesLoadEvent({
    required this.fieldId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [fieldId, forceRefresh];
}

class PricesCreateEvent extends PricesEvent {
  final Price price;

  const PricesCreateEvent({required this.price});

  @override
  List<Object?> get props => [price];
}

class PricesUpdateEvent extends PricesEvent {
  final Price price;

  const PricesUpdateEvent({required this.price});

  @override
  List<Object?> get props => [price];
}

class PricesDeleteEvent extends PricesEvent {
  final String priceId;

  const PricesDeleteEvent({required this.priceId});

  @override
  List<Object?> get props => [priceId];
}
