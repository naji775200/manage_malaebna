import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/coupon_repository.dart';
import 'coupons_event.dart';
import 'coupons_state.dart';

class CouponsBloc extends Bloc<CouponsEvent, CouponsState> {
  final CouponRepository _couponRepository;

  CouponsBloc({required CouponRepository couponRepository})
      : _couponRepository = couponRepository,
        super(CouponsInitial()) {
    on<CouponsLoadEvent>(_onCouponsLoad);
    on<CouponsCreateEvent>(_onCouponsCreate);
    on<CouponsUpdateEvent>(_onCouponsUpdate);
    on<CouponsDeleteEvent>(_onCouponsDelete);
    on<CouponsVerifyCodeEvent>(_onCouponsVerifyCode);
  }

  Future<void> _onCouponsLoad(
    CouponsLoadEvent event,
    Emitter<CouponsState> emit,
  ) async {
    emit(CouponsLoading());
    try {
      final coupons = await _couponRepository.getCouponsByStadiumId(
        event.stadiumId,
        forceRefresh: event.forceRefresh,
      );
      emit(CouponsLoaded(coupons: coupons));
    } catch (e) {
      emit(CouponsError(message: e.toString()));
    }
  }

  Future<void> _onCouponsCreate(
    CouponsCreateEvent event,
    Emitter<CouponsState> emit,
  ) async {
    emit(CouponsLoading());
    try {
      final createdCoupon = await _couponRepository.createCoupon(event.coupon);
      emit(CouponCreated(coupon: createdCoupon));
    } catch (e) {
      emit(CouponsError(message: e.toString()));
    }
  }

  Future<void> _onCouponsUpdate(
    CouponsUpdateEvent event,
    Emitter<CouponsState> emit,
  ) async {
    emit(CouponsLoading());
    try {
      final updatedCoupon = await _couponRepository.updateCoupon(event.coupon);
      emit(CouponUpdated(coupon: updatedCoupon));
    } catch (e) {
      emit(CouponsError(message: e.toString()));
    }
  }

  Future<void> _onCouponsDelete(
    CouponsDeleteEvent event,
    Emitter<CouponsState> emit,
  ) async {
    emit(CouponsLoading());
    try {
      await _couponRepository.deleteCoupon(event.couponId);
      emit(CouponDeleted(couponId: event.couponId));
    } catch (e) {
      emit(CouponsError(message: e.toString()));
    }
  }

  Future<void> _onCouponsVerifyCode(
    CouponsVerifyCodeEvent event,
    Emitter<CouponsState> emit,
  ) async {
    emit(CouponsLoading());
    try {
      final coupon = await _couponRepository.getCouponByCode(event.code);
      final bool isValid = coupon != null &&
          coupon.expirationDate.isAfter(DateTime.now()) &&
          coupon.status == 'active';

      emit(CouponVerified(coupon: coupon, isValid: isValid));
    } catch (e) {
      emit(CouponsError(message: e.toString()));
    }
  }
}
