import 'package:equatable/equatable.dart';
import '../../data/models/coupon_model.dart';

abstract class CouponsEvent extends Equatable {
  const CouponsEvent();

  @override
  List<Object?> get props => [];
}

class CouponsLoadEvent extends CouponsEvent {
  final String stadiumId;
  final bool forceRefresh;

  const CouponsLoadEvent({
    required this.stadiumId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [stadiumId, forceRefresh];
}

class CouponsCreateEvent extends CouponsEvent {
  final Coupon coupon;

  const CouponsCreateEvent({required this.coupon});

  @override
  List<Object?> get props => [coupon];
}

class CouponsUpdateEvent extends CouponsEvent {
  final Coupon coupon;

  const CouponsUpdateEvent({required this.coupon});

  @override
  List<Object?> get props => [coupon];
}

class CouponsDeleteEvent extends CouponsEvent {
  final String couponId;

  const CouponsDeleteEvent({required this.couponId});

  @override
  List<Object?> get props => [couponId];
}

class CouponsVerifyCodeEvent extends CouponsEvent {
  final String code;

  const CouponsVerifyCodeEvent({required this.code});

  @override
  List<Object?> get props => [code];
}
