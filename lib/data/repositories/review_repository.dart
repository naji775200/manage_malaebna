import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/review_local_data_source.dart';
import '../models/review_model.dart';
import '../remote/review_remote_data_source.dart';

class ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;
  final ReviewLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  ReviewRepository({
    required ReviewRemoteDataSource remoteDataSource,
    required ReviewLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Review> getReviewById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteReview = await _remoteDataSource.getReviewById(id);
        await _localDataSource.insertReview(remoteReview);
        return remoteReview;
      } catch (e) {
        final localReview = await _localDataSource.getReviewById(id);
        if (localReview != null) {
          return localReview;
        }
        rethrow;
      }
    } else {
      final localReview = await _localDataSource.getReviewById(id);
      if (localReview != null) {
        return localReview;
      }
      throw Exception('No internet connection and review not found locally');
    }
  }

  Future<List<Review>> getAllReviews({bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteReviews = await _remoteDataSource.getAllReviews();
        for (var review in remoteReviews) {
          await _localDataSource.insertReview(review);
        }
        return remoteReviews;
      } catch (e) {
        return await _localDataSource.getAllReviews();
      }
    } else {
      return await _localDataSource.getAllReviews();
    }
  }

  Future<List<Review>> getReviewsByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteReviews =
            await _remoteDataSource.getReviewsByStadiumId(stadiumId);
        for (var review in remoteReviews) {
          await _localDataSource.insertReview(review);
        }
        return remoteReviews;
      } catch (e) {
        return await _localDataSource.getReviewsByStadiumId(stadiumId);
      }
    } else {
      return await _localDataSource.getReviewsByStadiumId(stadiumId);
    }
  }

  Future<List<Review>> getReviewsByPlayerId(String playerId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteReviews =
            await _remoteDataSource.getReviewsByPlayerId(playerId);
        for (var review in remoteReviews) {
          await _localDataSource.insertReview(review);
        }
        return remoteReviews;
      } catch (e) {
        return await _localDataSource.getReviewsByPlayerId(playerId);
      }
    } else {
      return await _localDataSource.getReviewsByPlayerId(playerId);
    }
  }

  Future<List<Review>> getReviewsByRating(int rating,
      {bool forceRefresh = false}) async {
    if (forceRefresh || await _hasInternetConnection()) {
      try {
        final remoteReviews =
            await _remoteDataSource.getReviewsByRating(rating);
        for (var review in remoteReviews) {
          await _localDataSource.insertReview(review);
        }
        return remoteReviews;
      } catch (e) {
        return await _localDataSource.getReviewsByRating(rating);
      }
    } else {
      return await _localDataSource.getReviewsByRating(rating);
    }
  }

  Future<Review> createReview(Review review) async {
    if (await _hasInternetConnection()) {
      final createdReview = await _remoteDataSource.createReview(review);
      await _localDataSource.insertReview(createdReview);
      return createdReview;
    } else {
      throw Exception('No internet connection. Cannot create review.');
    }
  }

  Future<Review> updateReview(Review review) async {
    if (await _hasInternetConnection()) {
      final updatedReview = await _remoteDataSource.updateReview(review);
      await _localDataSource.updateReview(updatedReview);
      return updatedReview;
    } else {
      throw Exception('No internet connection. Cannot update review.');
    }
  }

  Future<void> deleteReview(String id) async {
    if (await _hasInternetConnection()) {
      await _remoteDataSource.deleteReview(id);
      await _localDataSource.deleteReview(id);
    } else {
      throw Exception('No internet connection. Cannot delete review.');
    }
  }
}
