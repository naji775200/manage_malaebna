import '../models/review_model.dart';
import 'base_local_data_source.dart';

class ReviewLocalDataSource extends BaseLocalDataSource<Review> {
  ReviewLocalDataSource() : super('reviews');

  Future<Review?> getReviewById(String id) async {
    final map = await getById(id);
    if (map != null) {
      return Review.fromJson(map);
    }
    return null;
  }

  Future<List<Review>> getAllReviews() async {
    final maps = await getAll();
    return maps.map((map) => Review.fromJson(map)).toList();
  }

  Future<String> insertReview(Review review) async {
    return await insert(review.toJson());
  }

  Future<int> updateReview(Review review) async {
    return await update(review.toJson());
  }

  Future<int> deleteReview(String id) async {
    return await delete(id);
  }

  Future<List<Review>> getReviewsByStadiumId(String stadiumId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => Review.fromJson(map)).toList();
  }

  Future<List<Review>> getReviewsByPlayerId(String playerId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'player_id = ?',
      whereArgs: [playerId],
    );

    return maps.map((map) => Review.fromJson(map)).toList();
  }

  Future<List<Review>> getReviewsByRating(int rating) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'rating = ?',
      whereArgs: [rating],
    );

    return maps.map((map) => Review.fromJson(map)).toList();
  }
}
