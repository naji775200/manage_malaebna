import '../models/cancellation_model.dart';
import '../local/cancellation_local_data_source.dart';
import '../remote/cancellation_remote_data_source.dart';

class CancellationRepository {
  final CancellationRemoteDataSource _remoteDataSource;
  final CancellationLocalDataSource _localDataSource;

  CancellationRepository({
    required CancellationRemoteDataSource remoteDataSource,
    required CancellationLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  Future<Cancellation?> getCancellationById(String id,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final cancellation = await _remoteDataSource.getCancellationById(id);
      if (cancellation != null) {
        await _localDataSource.updateCancellation(cancellation);
      }
      return cancellation;
    }

    final localCancellation = await _localDataSource.getCancellationById(id);
    if (localCancellation != null) {
      return localCancellation;
    }

    final remoteCancellation = await _remoteDataSource.getCancellationById(id);
    if (remoteCancellation != null) {
      await _localDataSource.insertCancellation(remoteCancellation);
    }
    return remoteCancellation;
  }

  Future<List<Cancellation>> getAllCancellations(
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final cancellations = await _remoteDataSource.getAllCancellations();
      // Update local cache
      for (final cancellation in cancellations) {
        await _localDataSource.updateCancellation(cancellation);
      }
      return cancellations;
    }

    final localCancellations = await _localDataSource.getAllCancellations();
    if (localCancellations.isNotEmpty) {
      return localCancellations;
    }

    final remoteCancellations = await _remoteDataSource.getAllCancellations();
    // Cache the cancellations locally
    for (final cancellation in remoteCancellations) {
      await _localDataSource.insertCancellation(cancellation);
    }
    return remoteCancellations;
  }

  Future<String> createCancellation(Cancellation cancellation) async {
    final id = await _remoteDataSource.createCancellation(cancellation);
    if (id == null) {
      throw Exception('Failed to create cancellation');
    }
    final cancellationWithId = cancellation.copyWith(id: id);
    await _localDataSource.insertCancellation(cancellationWithId);
    return id;
  }

  Future<bool> updateCancellation(Cancellation cancellation) async {
    final updated = await _remoteDataSource.updateCancellation(cancellation);
    if (updated) {
      await _localDataSource.updateCancellation(cancellation);
      return true;
    }
    return false;
  }

  Future<bool> deleteCancellation(String id) async {
    final deleted = await _remoteDataSource.deleteCancellation(id);
    if (deleted) {
      await _localDataSource.deleteCancellation(id);
      return true;
    }
    return false;
  }

  Future<Cancellation?> getCancellationByBookingId(String bookingId,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final cancellation =
          await _remoteDataSource.getCancellationByBookingId(bookingId);
      if (cancellation != null) {
        await _localDataSource.updateCancellation(cancellation);
      }
      return cancellation;
    }

    final localCancellation =
        await _localDataSource.getCancellationByBookingId(bookingId);
    if (localCancellation != null) {
      return localCancellation;
    }

    final remoteCancellation =
        await _remoteDataSource.getCancellationByBookingId(bookingId);
    if (remoteCancellation != null) {
      await _localDataSource.insertCancellation(remoteCancellation);
    }
    return remoteCancellation;
  }
}
