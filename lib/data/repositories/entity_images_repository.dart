import 'dart:io';
import 'dart:convert'; // For base64Encode
import 'dart:math' as math;
import '../models/entity_images_model.dart';
import '../local/entity_images_local_data_source.dart';
import '../remote/entity_images_remote_data_source.dart';
import 'base_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EntityImagesRepository implements BaseRepository<EntityImages> {
  final EntityImagesLocalDataSource _localDataSource;
  final EntityImagesRemoteDataSource _remoteDataSource;

  EntityImagesRepository({
    EntityImagesLocalDataSource? localDataSource,
    EntityImagesRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? EntityImagesLocalDataSource(),
        _remoteDataSource = remoteDataSource ??
            EntityImagesRemoteDataSource(
              supabaseClient: Supabase.instance.client,
              networkInfo: NetworkInfo(Connectivity()),
              tableName: 'entity_images',
            );

  // Upload and create a new entity image
  Future<EntityImages> uploadImage({
    required File imageFile,
    required String entityType,
    required String entityId,
    bool replaceExisting =
        false, // New parameter to control replacement behavior
  }) async {
    try {
      print('Starting image upload process for ${entityType}_${entityId}');

      // Handle replacement of existing images if requested
      if (replaceExisting) {
        try {
          print('Replacing existing images...');
          await _localDataSource.deleteEntityImagesByEntityTypeAndId(
              entityType, entityId);

          // Also remove from remote if possible
          try {
            await _remoteDataSource.deleteEntityImagesByEntityTypeAndId(
                entityType, entityId);
            print('Removed existing remote images');
          } catch (e) {
            print('Error removing remote images (continuing anyway): $e');
          }
        } catch (e) {
          print('Error removing existing images: $e');
        }
      } else {
        // Check how many images already exist - limit to 5 total
        try {
          print('Checking existing image count...');
          final existingImages = await _localDataSource
              .getImagesByEntityTypeAndId(entityType, entityId);

          if (existingImages.length >= 5) {
            print('Maximum image limit reached (5). Removing oldest image.');
            existingImages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final oldestImage = existingImages.first;

            // Remove oldest from both local and remote
            await _localDataSource.deleteEntityImage(oldestImage.id);
            try {
              await _remoteDataSource.deleteEntityImage(oldestImage);
              print('Removed oldest remote image');
            } catch (e) {
              print(
                  'Error removing oldest remote image (continuing anyway): $e');
            }
          }
        } catch (e) {
          print('Error checking existing image count: $e');
        }
      }

      // Upload image to Supabase storage
      print('Uploading image to Supabase...');
      EntityImages? remoteEntity;
      try {
        remoteEntity = await _remoteDataSource.uploadImage(
          entityType,
          entityId,
          imageFile.path,
          true, // Make the image public
        );
        print(
            'Successfully uploaded to Supabase: ${remoteEntity.imageUrl.substring(0, math.min(30, remoteEntity.imageUrl.length))}...');

        // Save the EntityImage with the Supabase URL to local database
        print('Saving remote entity to local database');
        await _localDataSource.createEntityImage(remoteEntity);
        print(
            'Successfully saved remote entity to local database with ID: ${remoteEntity.id}');

        return remoteEntity;
      } catch (e) {
        print('Remote upload failed: $e');
        // If remote upload fails, we'll fall through to local-only fallback below
      }

      // Fallback to local storage only if remote upload fails
      print('Falling back to local storage only');
      final String imageUrl = await _createDataUriFromFile(imageFile);

      final entityImage = EntityImages(
        id: const Uuid().v4(),
        entityType: entityType,
        entityId: entityId,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _localDataSource.createEntityImage(entityImage);
      print('Successfully saved local-only image with ID: ${entityImage.id}');
      return entityImage;
    } catch (e) {
      print('Error in uploadImage repository method: $e');
      rethrow;
    }
  }

  // Helper method to create a data URI from a file
  Future<String> _createDataUriFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);

      // Determine MIME type based on file extension
      final extension = path.extension(file.path).toLowerCase();
      String mimeType;

      switch (extension) {
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.png':
          mimeType = 'image/png';
          break;
        case '.gif':
          mimeType = 'image/gif';
          break;
        case '.webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/png'; // Default to PNG
      }

      return 'data:$mimeType;base64,$base64';
    } catch (e) {
      print('Error creating data URI: $e');
      // Fallback to a simple green pixel in case of error
      return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    }
  }

  // Get images by entity type and id with Supabase sync
  Future<List<EntityImages>> getImagesByEntityTypeAndId(
      String entityType, String entityId,
      {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        print('Force refreshing images for ${entityType}_${entityId}');

        // Sync with Supabase to ensure we have all remote images
        await syncImagesWithSupabase(entityType, entityId);
      }

      // Get from local database
      final localImages = await _localDataSource.getImagesByEntityTypeAndId(
          entityType, entityId);

      print(
          'Retrieved ${localImages.length} images from local storage for ${entityType}_${entityId}');
      return localImages;
    } catch (e) {
      print('Error getting images from local storage: $e');
      return []; // Return empty list on error
    }
  }

  // Sync images between Supabase and local storage
  Future<int> syncImagesWithSupabase(String entityType, String entityId) async {
    try {
      print('Starting image sync for ${entityType}_${entityId}');
      int syncedCount = 0;

      // Get local images first
      final localImages = await _localDataSource.getImagesByEntityTypeAndId(
          entityType, entityId);
      print('Found ${localImages.length} local images');

      // Get all images from Supabase database
      final remoteImages =
          await _remoteDataSource.syncImagesFromSupabase(entityType, entityId);
      print('Found ${remoteImages.length} remote images in Supabase database');

      // Find images in remote that aren't in local
      final localImageUrls = localImages.map((img) => img.imageUrl).toList();
      final newRemoteImages = remoteImages
          .where((remote) => !localImageUrls.contains(remote.imageUrl))
          .toList();

      // Add new remote images to local database
      for (var image in newRemoteImages) {
        await _localDataSource.createEntityImage(image);
        syncedCount++;
      }

      // If no images were found in database, check storage directly
      if (remoteImages.isEmpty) {
        final storageImageUrls =
            await _remoteDataSource.listStorageImages(entityType, entityId);
        print(
            'Found ${storageImageUrls.length} images directly in Supabase storage');

        // Filter out URLs that already exist locally
        final newStorageUrls = storageImageUrls
            .where((url) => !localImageUrls.contains(url))
            .toList();

        // Create local records for storage images
        for (var imageUrl in newStorageUrls) {
          final entityImage = EntityImages(
            id: const Uuid().v4(),
            entityType: entityType,
            entityId: entityId,
            imageUrl: imageUrl,
            createdAt: DateTime.now(),
          );

          await _localDataSource.createEntityImage(entityImage);
          syncedCount++;

          // Also try to create the record in Supabase
          try {
            await _remoteDataSource.insert(entityImage.toJson());
          } catch (e) {
            print('Error creating Supabase record for storage image: $e');
          }
        }
      }

      print('Synced $syncedCount new images');
      return syncedCount;
    } catch (e) {
      print('Error during image sync: $e');
      return 0;
    }
  }

  // New method to preserve entity images during stadium update process
  Future<List<String>> preserveEntityImages(
      String entityType, String entityId) async {
    try {
      print(
          'Preserving images for ${entityType}_${entityId} before stadium update');
      final images = await getImagesByEntityTypeAndId(entityType, entityId);

      if (images.isEmpty) {
        print('No images to preserve for ${entityType}_${entityId}');
        return [];
      }

      print('Found ${images.length} images to preserve');

      // Return just the image URLs as that's what the Stadium model uses
      return images.map((image) => image.imageUrl).toList();
    } catch (e) {
      print('Error preserving entity images: $e');
      return [];
    }
  }

  // Helper method to restore preserved images
  Future<void> restoreEntityImages(
      String entityType, String entityId, List<String> imageUrls) async {
    if (imageUrls.isEmpty) {
      print('No images to restore for ${entityType}_${entityId}');
      return;
    }

    print(
        'Restoring ${imageUrls.length} preserved images for ${entityType}_${entityId}');

    // First delete any existing images to avoid duplicates
    await _localDataSource.deleteEntityImagesByEntityTypeAndId(
        entityType, entityId);

    // Try to delete from remote too, just to be safe
    try {
      await _remoteDataSource.deleteEntityImagesByEntityTypeAndId(
          entityType, entityId);
    } catch (e) {
      print('Error deleting remote images during restoration: $e');
      // Continue with restoration regardless of remote deletion errors
    }

    // Create new entity image records for each preserved URL
    for (final imageUrl in imageUrls) {
      final id = const Uuid().v4();
      final entityImage = EntityImages(
        id: id,
        entityType: entityType,
        entityId: entityId,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // Save to local database
      await _localDataSource.createEntityImage(entityImage);

      // Also save to remote database
      try {
        await _remoteDataSource.insert(entityImage.toJson());
        print('Restored image in Supabase database: $id');
      } catch (e) {
        print('Error restoring image in Supabase database: $e');
        // Continue with next image even if this one fails remotely
      }
    }

    print('Successfully restored ${imageUrls.length} images');
  }

  // Delete an image by its id
  Future<void> deleteImage(String id) async {
    try {
      // Get the image first
      final image = await getById(id);
      if (image != null) {
        // Delete from remote
        await _remoteDataSource.deleteEntityImage(image);
        // Delete from local
        await _localDataSource.deleteEntityImage(id);
      }
    } catch (e) {
      // Still try to delete locally if remote fails
      await _localDataSource.deleteEntityImage(id);
      rethrow;
    }
  }

  // Delete all images for an entity
  Future<void> deleteAllImagesForEntity(
      String entityType, String entityId) async {
    try {
      // Delete from remote
      await _remoteDataSource.deleteEntityImagesByEntityTypeAndId(
          entityType, entityId);
      // Delete from local
      await _localDataSource.deleteEntityImagesByEntityTypeAndId(
          entityType, entityId);
    } catch (e) {
      // Still try to delete locally if remote fails
      await _localDataSource.deleteEntityImagesByEntityTypeAndId(
          entityType, entityId);
      rethrow;
    }
  }

  // Base repository implementation
  @override
  Future<EntityImages> create(EntityImages item) async {
    try {
      // Create in remote
      final remoteItem = await _remoteDataSource.updateEntityImage(item);
      // Create in local
      await _localDataSource.createEntityImage(remoteItem ?? item);
      return remoteItem ?? item;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EntityImages?> getById(String id) async {
    try {
      // Only get from local database - skip remote retrieval
      final localItem = await _localDataSource.getEntityImageById(id);
      if (localItem != null) {
        print('Retrieved image ${id} from local storage');
      } else {
        print('Image ${id} not found in local storage');
      }
      return localItem;

      // Remote retrieval code removed as per user request to only use local storage
    } catch (e) {
      print('Error getting image by ID from local storage: $e');
      return null;
    }
  }

  @override
  Future<List<EntityImages>> getAll() async {
    try {
      // Only get from local database - skip remote retrieval
      final localItems = await _localDataSource.getAllEntityImages();
      print('Retrieved ${localItems.length} images from local storage');
      return localItems;

      // Remote retrieval code removed as per user request to only use local storage
    } catch (e) {
      print('Error getting all images from local storage: $e');
      return [];
    }
  }

  @override
  Future<EntityImages> update(EntityImages item) async {
    try {
      // Update remote
      final remoteItem = await _remoteDataSource.updateEntityImage(item);
      if (remoteItem != null) {
        // Update local
        await _localDataSource.updateEntityImage(remoteItem);
        return remoteItem;
      }
      return item;
    } catch (e) {
      // Try to update locally anyway
      await _localDataSource.updateEntityImage(item);
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      print('Attempting to delete image with ID: $id');

      // Get the image before deleting to log details
      final image = await getById(id);
      if (image != null) {
        print(
            'Found image to delete: ${image.id} for ${image.entityType}/${image.entityId}');
      } else {
        print('Warning: Image with ID $id not found before deletion');
      }

      await deleteImage(id);
      print('Image deletion completed for ID: $id');

      // Verify deletion
      final verifyImage = await getById(id);
      if (verifyImage == null) {
        print('Verified: Image $id was successfully deleted');
      } else {
        print('Warning: Image $id still exists after deletion attempt');
      }
    } catch (e) {
      print('Error during image deletion: $e');
      rethrow;
    }
  }

  // New method to transfer images from one entity ID to another
  Future<int> transferImages(
      String entityType, String fromEntityId, String toEntityId) async {
    try {
      print(
          'Transferring images from $entityType/$fromEntityId to $entityType/$toEntityId');

      // Get all images for the source entity
      final sourceImages =
          await getImagesByEntityTypeAndId(entityType, fromEntityId);

      if (sourceImages.isEmpty) {
        print('No images found to transfer from $entityType/$fromEntityId');
        return 0;
      }

      print('Found ${sourceImages.length} images to transfer');
      int successCount = 0;

      // Create new image records for each image with the new entity ID
      for (final image in sourceImages) {
        try {
          // Create a new image with the destination entity ID
          final newImage = EntityImages(
            id: const Uuid().v4(),
            entityType: entityType,
            entityId: toEntityId,
            imageUrl: image.imageUrl,
            createdAt: DateTime.now(),
          );

          // Save the new image
          await _localDataSource.createEntityImage(newImage);

          // Delete the old image
          await _localDataSource.deleteEntityImage(image.id);

          successCount++;
        } catch (e) {
          print('Error transferring image ${image.id}: $e');
        }
      }

      print(
          'Successfully transferred $successCount/${sourceImages.length} images');
      return successCount;
    } catch (e) {
      print('Error transferring images: $e');
      return 0;
    }
  }

  // Method to sync all stadium images on app startup
  Future<void> syncAllStadiumImages(List<String> stadiumIds) async {
    print('Starting sync of all stadium images on app startup');
    try {
      // Check if we have internet connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('No internet connection, skipping stadium image sync');
        return;
      }

      int totalSynced = 0;

      // Sync images for each stadium
      for (final stadiumId in stadiumIds) {
        final syncCount = await syncImagesWithSupabase('stadium', stadiumId);
        totalSynced += syncCount;
      }

      print('Finished syncing stadium images. Total synced: $totalSynced');
    } catch (e) {
      print('Error syncing all stadium images: $e');
    }
  }
}
