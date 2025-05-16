import '../models/owner_model.dart';
import '../local/owner_local_data_source.dart';
import '../remote/owner_remote_data_source.dart';

class OwnerRepository {
  final OwnerRemoteDataSource _remoteDataSource;
  final OwnerLocalDataSource _localDataSource;

  OwnerRepository({
    required OwnerRemoteDataSource remoteDataSource,
    required OwnerLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  Future<Owner?> getOwnerById(String id, {bool forceRemote = false}) async {
    if (forceRemote) {
      final owner = await _remoteDataSource.getOwnerById(id);
      if (owner != null) {
        await _localDataSource.updateOwner(owner);
      }
      return owner;
    }

    final localOwner = await _localDataSource.getOwnerById(id);
    if (localOwner != null) {
      return localOwner;
    }

    final remoteOwner = await _remoteDataSource.getOwnerById(id);
    if (remoteOwner != null) {
      await _localDataSource.insertOwner(remoteOwner);
    }
    return remoteOwner;
  }

  Future<List<Owner>> getAllOwners({bool forceRemote = false}) async {
    if (forceRemote) {
      final owners = await _remoteDataSource.getAllOwners();
      // Update local cache
      for (final owner in owners) {
        await _localDataSource.updateOwner(owner);
      }
      return owners;
    }

    final localOwners = await _localDataSource.getAllOwners();
    if (localOwners.isNotEmpty) {
      return localOwners;
    }

    final remoteOwners = await _remoteDataSource.getAllOwners();
    // Cache the owners locally
    for (final owner in remoteOwners) {
      await _localDataSource.insertOwner(owner);
    }
    return remoteOwners;
  }

  Future<String> createOwner(Owner owner) async {
    final id = await _remoteDataSource.createOwner(owner);
    if (id == null) {
      throw Exception('Failed to create owner');
    }
    final ownerWithId = owner.copyWith(id: id);
    await _localDataSource.insertOwner(ownerWithId);
    return id;
  }

  Future<bool> updateOwner(Owner owner) async {
    final updated = await _remoteDataSource.updateOwner(owner);
    if (updated) {
      await _localDataSource.updateOwner(owner);
      return true;
    }
    return false;
  }

  Future<bool> deleteOwner(String id) async {
    final deleted = await _remoteDataSource.deleteOwner(id);
    if (deleted) {
      await _localDataSource.deleteOwner(id);
      return true;
    }
    return false;
  }

  Future<List<Owner>> getOwnersByStatus(String status,
      {bool forceRemote = false}) async {
    if (forceRemote) {
      final owners = await _remoteDataSource.getOwnersByStatus(status);
      // Update local cache
      for (final owner in owners) {
        await _localDataSource.updateOwner(owner);
      }
      return owners;
    }

    final localOwners = await _localDataSource.getOwnersByStatus(status);
    if (localOwners.isNotEmpty) {
      return localOwners;
    }

    final remoteOwners = await _remoteDataSource.getOwnersByStatus(status);
    // Cache the owners locally
    for (final owner in remoteOwners) {
      await _localDataSource.insertOwner(owner);
    }
    return remoteOwners;
  }
}
