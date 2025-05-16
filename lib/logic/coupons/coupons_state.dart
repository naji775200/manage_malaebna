import 'package:equatable/equatable.dart';
import '../../data/models/coupon_model.dart';

abstract class CouponsState extends Equatable {
  const CouponsState();

  @override
  List<Object?> get props => [];
}

class CouponsInitial extends CouponsState {}

class CouponsLoading extends CouponsState {}

class CouponsLoaded extends CouponsState {
  final List<Coupon> coupons;

  const CouponsLoaded({required this.coupons});

  @override
  List<Object?> get props => [coupons];
}

class CouponsError extends CouponsState {
  final String message;

  const CouponsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CouponCreated extends CouponsState {
  final Coupon coupon;

  const CouponCreated({required this.coupon});

  @override
  List<Object?> get props => [coupon];
}

class CouponUpdated extends CouponsState {
  final Coupon coupon;

  const CouponUpdated({required this.coupon});

  @override
  List<Object?> get props => [coupon];
}

class CouponDeleted extends CouponsState {
  final String couponId;

  const CouponDeleted({required this.couponId});

  @override
  List<Object?> get props => [couponId];
}

class CouponVerified extends CouponsState {
  final Coupon? coupon;
  final bool isValid;

  const CouponVerified({
    this.coupon,
    required this.isValid,
  });

  @override
  List<Object?> get props => [coupon, isValid];
}
