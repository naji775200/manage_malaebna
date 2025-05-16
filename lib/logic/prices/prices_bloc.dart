import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/price_repository.dart';
import 'prices_event.dart';
import 'prices_state.dart';

class PricesBloc extends Bloc<PricesEvent, PricesState> {
  final PriceRepository _priceRepository;

  PricesBloc({required PriceRepository priceRepository})
      : _priceRepository = priceRepository,
        super(PricesInitial()) {
    on<PricesLoadEvent>(_onPricesLoad);
    on<PricesCreateEvent>(_onPricesCreate);
    on<PricesUpdateEvent>(_onPricesUpdate);
    on<PricesDeleteEvent>(_onPricesDelete);
  }

  Future<void> _onPricesLoad(
    PricesLoadEvent event,
    Emitter<PricesState> emit,
  ) async {
    emit(PricesLoading());
    try {
      final prices = await _priceRepository.getPricesByFieldId(
        event.fieldId,
        forceRefresh: event.forceRefresh,
      );
      emit(PricesLoaded(prices: prices));
    } catch (e) {
      emit(PricesError(message: e.toString()));
    }
  }

  Future<void> _onPricesCreate(
    PricesCreateEvent event,
    Emitter<PricesState> emit,
  ) async {
    emit(PricesLoading());
    try {
      final createdPrice = await _priceRepository.createPrice(event.price);
      emit(PriceCreated(price: createdPrice));
    } catch (e) {
      emit(PricesError(message: e.toString()));
    }
  }

  Future<void> _onPricesUpdate(
    PricesUpdateEvent event,
    Emitter<PricesState> emit,
  ) async {
    emit(PricesLoading());
    try {
      final updatedPrice = await _priceRepository.updatePrice(event.price);
      emit(PriceUpdated(price: updatedPrice));
    } catch (e) {
      emit(PricesError(message: e.toString()));
    }
  }

  Future<void> _onPricesDelete(
    PricesDeleteEvent event,
    Emitter<PricesState> emit,
  ) async {
    emit(PricesLoading());
    try {
      await _priceRepository.deletePrice(event.priceId);
      emit(PriceDeleted(priceId: event.priceId));
    } catch (e) {
      emit(PricesError(message: e.toString()));
    }
  }
}
