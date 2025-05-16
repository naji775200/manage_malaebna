import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coupon_model.dart';

class CouponRemoteDataSource {
  final SupabaseClient _supabaseClient;

  CouponRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<Coupon> getCouponById(String id) async {
    final response =
        await _supabaseClient.from('coupons').select().eq('id', id).single();
    return Coupon.fromJson(response);
  }

  Future<List<Coupon>> getAllCoupons() async {
    final response = await _supabaseClient.from('coupons').select();
    return response.map<Coupon>((json) => Coupon.fromJson(json)).toList();
  }

  Future<List<Coupon>> getCouponsByStadiumId(String stadiumId) async {
    final response = await _supabaseClient
        .from('coupons')
        .select()
        .eq('stadium_id', stadiumId);
    return response.map<Coupon>((json) => Coupon.fromJson(json)).toList();
  }

  Future<List<Coupon>> getCouponsByStatus(String status) async {
    final response =
        await _supabaseClient.from('coupons').select().eq('status', status);
    return response.map<Coupon>((json) => Coupon.fromJson(json)).toList();
  }

  Future<Coupon?> getCouponByCode(String code) async {
    final response = await _supabaseClient
        .from('coupons')
        .select()
        .eq('code', code)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Coupon.fromJson(response);
  }

  Future<Coupon> createCoupon(Coupon coupon) async {
    final response = await _supabaseClient
        .from('coupons')
        .insert(coupon.toJson())
        .select()
        .single();
    return Coupon.fromJson(response);
  }

  Future<Coupon> updateCoupon(Coupon coupon) async {
    final response = await _supabaseClient
        .from('coupons')
        .update(coupon.toJson())
        .eq('id', coupon.id)
        .select()
        .single();
    return Coupon.fromJson(response);
  }

  Future<void> deleteCoupon(String id) async {
    await _supabaseClient.from('coupons').delete().eq('id', id);
  }
}
