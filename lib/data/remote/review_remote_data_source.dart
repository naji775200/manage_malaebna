import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ReviewRemoteDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<Review> getReviewById(String id) async {
    final response =
        await _supabaseClient.from('reviews').select().eq('id', id).single();
    return Review.fromJson(response);
  }

  Future<List<Review>> getAllReviews() async {
    final response = await _supabaseClient.from('reviews').select();
    return response.map<Review>((json) => Review.fromJson(json)).toList();
  }

  Future<List<Review>> getReviewsByStadiumId(String stadiumId) async {
    final response = await _supabaseClient
        .from('reviews')
        .select()
        .eq('stadium_id', stadiumId);
    return response.map<Review>((json) => Review.fromJson(json)).toList();
  }

  Future<List<Review>> getReviewsByPlayerId(String playerId) async {
    final response = await _supabaseClient
        .from('reviews')
        .select()
        .eq('player_id', playerId);
    return response.map<Review>((json) => Review.fromJson(json)).toList();
  }

  Future<List<Review>> getReviewsByRating(int rating) async {
    final response =
        await _supabaseClient.from('reviews').select().eq('rating', rating);
    return response.map<Review>((json) => Review.fromJson(json)).toList();
  }

  Future<Review> createReview(Review review) async {
    final response = await _supabaseClient
        .from('reviews')
        .insert(review.toJson())
        .select()
        .single();
    return Review.fromJson(response);
  }

  Future<Review> updateReview(Review review) async {
    final response = await _supabaseClient
        .from('reviews')
        .update(review.toJson())
        .eq('id', review.id)
        .select()
        .single();
    return Review.fromJson(response);
  }

  Future<void> deleteReview(String id) async {
    await _supabaseClient.from('reviews').delete().eq('id', id);
  }
}
