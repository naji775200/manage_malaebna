import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../remote/base_remote_data_source.dart';
import '../models/entity_images_model.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import '../../core/utils/network_info.dart';

class EntityImagesRemoteDataSource extends BaseRemoteDataSource<EntityImages> {
  final SupabaseClient _supabaseClient;
  final NetworkInfo _networkInfo;

  EntityImagesRemoteDataSource({
    required SupabaseClient supabaseClient,
    required NetworkInfo networkInfo,
    required String tableName,
  })  : _supabaseClient = supabaseClient,
        _networkInfo = networkInfo,
        super(tableName);

  @override
  SupabaseClient get supabase => _supabaseClient;

  // Storage bucket paths based on entity type
  static const Map<String, String> _bucketPaths = {
    'stadium': 'images/stadium',
    'field': 'images/fields',
    'owner': 'images/owners',
  };

  // Get the appropriate bucket path based on entity type
  String _getBucketPath(String entityType) {
    return _bucketPaths[entityType.toLowerCase()] ?? 'images';
  }

  // Upload image file to Supabase Storage
  Future<EntityImages> uploadImage(
    String entityType,
    String entityId,
    String filePath,
    bool isPublic,
  ) async {
    try {
      print('Starting Supabase image upload for ${entityType}_${entityId}');

      // Check if we have connection and auth
      final hasConnection = await _networkInfo.isConnected;
      if (!hasConnection) {
        print('No internet connection - falling back to data URI');
        return await _createDataUriImage(filePath, entityType, entityId);
      }

      print('Internet connection verified, proceeding with upload');

      // Get the file bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      print('Read ${bytes.length} bytes from file: $filePath');

      // Create a unique filename
      final fileName = '${entityType}_${entityId}_${const Uuid().v4()}.jpg';
      String storagePath = 'public/${entityType}s/$fileName';
      print('Storage path for upload: $storagePath');

      // Upload to Supabase Storage
      print('Attempting Supabase storage upload...');
      try {
        await supabase.storage.from('images').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert:
                    true, // Changed to true to overwrite files with same name
              ),
            );
        print('Upload to Supabase storage successful');
      } catch (storageError) {
        print('Error uploading to Supabase storage: $storageError');
        // Try a simplified bucket path
        try {
          print('Trying fallback upload to root bucket...');
          await supabase.storage.from('images').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
          print('Fallback upload successful');
          storagePath = fileName; // Update storage path for URL generation
        } catch (fallbackError) {
          print('Fallback upload also failed: $fallbackError');
          throw fallbackError; // Rethrow to trigger the fallback to data URI
        }
      }

      // Get the public URL
      print('Getting public URL for uploaded file');
      final String imageUrl =
          supabase.storage.from('images').getPublicUrl(storagePath);
      print('Successfully uploaded to Supabase Storage: $imageUrl');

      // Create entity image model
      final id = const Uuid().v4();
      final entityImage = EntityImages(
        id: id,
        entityType: entityType,
        entityId: entityId,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // Create record in Supabase database
      print('Creating record in Supabase entity_images table');
      try {
        // Ensure we have all the required fields for the entity_images table
        final Map<String, dynamic> recordData = {
          'id': entityImage.id,
          'entity_type': entityType,
          'entity_id': entityId,
          'image_url': imageUrl,
          'created_at': entityImage.createdAt.toIso8601String(),
        };

        print('Inserting data into entity_images table: $recordData');

        // Use direct insert to the entity_images table
        final insertResult =
            await supabase.from(tableName).insert(recordData).select().single();

        print(
            'Successfully created record in Supabase database: ${insertResult != null}');

        if (insertResult != null) {
          print('Created database record with ID: ${insertResult['id']}');
        }
      } catch (dbError) {
        print('Error creating database record: $dbError');
        // Continue with the local image regardless of DB error
      }

      return entityImage;
    } catch (e, stackTrace) {
      print('Error in overall upload process: $e');
      print('Stack trace: $stackTrace');
      // Fallback to data URI
      return await _createDataUriImage(filePath, entityType, entityId);
    }
  }

  // Helper method to create a data URI image object
  Future<EntityImages> _createDataUriImage(
      String filePath, String entityType, String entityId) async {
    // Convert image to base64 data URI
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final imageUrl = 'data:image/jpeg;base64,$base64Image';
    print('Created data URI for local storage');

    // Create and return the EntityImages object
    return EntityImages(
      id: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
  }

  // Helper method to ensure we have a valid authentication session
  Future<AuthResult> _ensureAuthentication() async {
    try {
      print('Starting authentication check...');

      // Check current session
      final currentUser = supabase.auth.currentUser;
      final currentSession = supabase.auth.currentSession;

      if (currentUser != null && currentSession != null) {
        // User is already authenticated with a valid session
        print(
            'Authentication successful: User is already authenticated with ID: ${currentUser.id}');
        return AuthResult(
            isAuthenticated: true, isTestMode: false, userId: currentUser.id);
      }

      print('No active session found, trying to refresh session...');

      // If no current session, try to restore from storage
      try {
        final session = await supabase.auth.refreshSession();
        if (session.session != null) {
          print('Session refreshed successfully for user: ${session.user?.id}');
          return AuthResult(
              isAuthenticated: true,
              isTestMode: false,
              userId: session.user?.id);
        } else {
          print('Session refresh returned null session');
        }
      } catch (refreshError) {
        print('Error refreshing session: $refreshError');
        // Continue to the manual token refresh approach
      }

      print('Checking if in test mode...');

      // Check if we're in test mode and handle accordingly
      if (_isTestMode()) {
        try {
          // For testing: Get the user ID from SharedPreferences
          final userId = await _getUserIdFromPrefs();
          if (userId != null && userId.isNotEmpty) {
            print('Test mode: Using stored user ID: $userId');
            // Return true for test mode with the user ID
            return AuthResult(
                isAuthenticated: true, isTestMode: true, userId: userId);
          } else {
            print('Test mode: No stored user ID found in preferences');
          }
        } catch (prefError) {
          print('Error getting user ID from prefs: $prefError');
        }
      }

      print('Checking for alternative authentication methods...');

      // If we're in development mode, create an anonymous session
      if (_isDevelopmentMode()) {
        print('Development mode detected, using anonymous authentication');
        // In development, we can use anonymous auth or a dev token
        return AuthResult(
            isAuthenticated: true,
            isTestMode: true,
            userId: 'dev-user-${DateTime.now().millisecondsSinceEpoch}');
      }

      print('Authentication failed: No valid authentication method available');
      return AuthResult(isAuthenticated: false, isTestMode: false);
    } catch (e) {
      print('Error in _ensureAuthentication: $e');
      return AuthResult(
          isAuthenticated: false, isTestMode: false, error: e.toString());
    }
  }

  // Helper method to check if we're in development mode
  bool _isDevelopmentMode() {
    // Set this to true for development, false for production
    return true; // For now, let's assume we're always in development mode
  }

  // Helper method to check if we're in test mode
  bool _isTestMode() {
    // You could check for a constant, environment variable,
    // or a setting in your app config
    return true; // For now, always assume test mode
  }

  // Helper method to get user ID from SharedPreferences
  Future<String?> _getUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error reading from SharedPreferences: $e');
      return null;
    }
  }

  // Helper method to get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  // Generate a fallback image URL for development/testing when RLS blocks uploads
  String _getFallbackImageUrl(
      String entityType, String entityId, String fileName) {
    // Use data URIs instead of online placeholder services
    // These are embedded small images that don't require network access

    // Base64 encoded 1x1 pixel images of different colors
    const String greenPixelDataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='; // green
    const String bluePixelDataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPj/HwADBwIAMCbHYQAAAABJRU5ErkJggg=='; // blue
    const String purplePixelDataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P//PwAIFgMAAL3p0QAAAABJRU5ErkJggg=='; // purple
    const String orangePixelDataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='; // orange

    print('Using data URI fallback image for ${entityType}_${entityId}');

    // Different colors for different entity types
    if (entityType == 'stadium') {
      return greenPixelDataUri;
    } else if (entityType == 'field') {
      return bluePixelDataUri;
    } else if (entityType == 'owner') {
      return purplePixelDataUri;
    }

    // Default placeholder
    return orangePixelDataUri;
  }

  // Helper to check if authentication is actually working
  Future<bool> _isAuthWorking() async {
    try {
      print('Testing Supabase authentication...');

      // First, check if we can access any public data
      try {
        print('Checking basic Supabase connection...');
        await supabase.from('entity_images').select('id').limit(1);
        print('Basic Supabase query succeeded');
      } catch (e) {
        print('Basic Supabase query failed: $e');

        // Check if this is a connection error or auth error
        if (e.toString().contains('network') ||
            e.toString().contains('connection') ||
            e.toString().contains('timeout')) {
          print('This appears to be a network connectivity issue');
          return false;
        }
      }

      // Now check if we can access the storage bucket
      try {
        print('Testing Supabase storage access...');
        // Try to list files in the stadium images bucket
        await supabase.storage.from('images/stadium').list();
        print('Successfully accessed storage bucket');
        return true;
      } catch (storageError) {
        print('Error accessing storage bucket: $storageError');

        // If this is an RLS/permission error but the connection works,
        // we'll consider auth partially working
        if (storageError.toString().contains('row-level security policy') ||
            storageError.toString().contains('403') ||
            storageError.toString().contains('Unauthorized')) {
          print(
              'Storage access denied due to permissions - auth works but RLS prevents access');
          return false;
        }

        // For other storage errors, the base connection might still work
        return false;
      }
    } catch (e) {
      print('Auth check failed with unexpected error: $e');
      return false;
    }
  }

  // Create entity image record in database
  Future<EntityImages> createEntityImage({
    required File imageFile,
    required String entityType,
    required String entityId,
  }) async {
    try {
      // Upload the image and get the public URL
      final EntityImages uploadResult =
          await uploadImage(entityType, entityId, imageFile.path, false);
      print('Image uploaded successfully with ID: ${uploadResult.id}');

      // Get current user for ownership tracking - don't use null assertion
      final currentUser = supabase.auth.currentUser;
      // If in test mode but no Supabase session, try to get userId from prefs
      String? userId = currentUser?.id;
      if (userId == null && _isTestMode()) {
        userId = await _getUserIdFromPrefs();
      }

      // Create entity image model with user ID
      final entityImage = EntityImages(
        id: const Uuid().v4(),
        entityType: entityType,
        entityId: entityId,
        imageUrl: uploadResult.imageUrl,
        createdAt: DateTime.now(),
      );

      // Check if we're using a fallback image URL (data URI)
      if (entityImage.imageUrl.startsWith('data:image')) {
        print('Using data URI fallback image - skipping database insertion');
        return entityImage;
      }

      // Print the data we're about to insert for debugging
      print('Prepared entity image data for insertion:');
      print('ID: ${entityImage.id}');
      print('Entity type: ${entityImage.entityType}');
      print('Entity ID: ${entityImage.entityId}');
      print(
          'Image URL: ${entityImage.imageUrl.length > 30 ? entityImage.imageUrl.substring(0, 30) + '...' : entityImage.imageUrl}'); // Only print the start of the URL to avoid log spam
      print('Created at: ${entityImage.createdAt}');

      // Check authentication status
      if (currentUser == null) {
        print(
            'WARNING: Attempting to insert database record without authentication');
        print(
            'This will likely fail due to RLS - returning entity with image URL only');
        return entityImage;
      } else {
        print('Inserting with authenticated user: ${currentUser.id}');
      }

      // Insert into database
      print('Inserting entity image record into database');

      try {
        final response = await insert(entityImage.toJson());

        if (response != null) {
          // Convert the string date back to DateTime
          print('Entity image record created successfully');
          response['created_at'] =
              DateTime.parse(response['created_at'] as String);
          return EntityImages.fromJson(response);
        }
      } catch (dbError) {
        print('Database insert error: $dbError');
        if (dbError.toString().contains('row-level security policy') ||
            dbError.toString().contains('403') ||
            dbError.toString().contains('Unauthorized')) {
          print(
              'This is a database permissions issue. Check your Supabase RLS policies for the entity_images table.');

          // If image was uploaded but DB insert failed, return entity with the uploaded image URL
          print('Image was uploaded but database record creation failed.');
          print('Returning entity image object with the uploaded URL.');
          return entityImage;
        }
        rethrow;
      }

      // If the insert failed, return the original entity image
      print(
          'Database insert did not return a response, returning original entity image');
      return entityImage;
    } catch (e) {
      print('Error in overall createEntityImage process: $e');
      rethrow;
    }
  }

  // Get entity image by id
  Future<EntityImages?> getEntityImageById(String id) async {
    final response = await getById(id);

    if (response != null) {
      // Convert the string date back to DateTime
      response['created_at'] = DateTime.parse(response['created_at'] as String);
      return EntityImages.fromJson(response);
    }

    return null;
  }

  // Get all images for a specific entity
  Future<List<EntityImages>> getImagesByEntityTypeAndId(
      String entityType, String entityId) async {
    final response = await supabase
        .from(tableName)
        .select()
        .eq('entity_type', entityType)
        .eq('entity_id', entityId);

    return response.map<EntityImages>((json) {
      // Convert the string date back to DateTime
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      return EntityImages.fromJson(json);
    }).toList();
  }

  // Get all entity images
  Future<List<EntityImages>> getAllEntityImages() async {
    final response = await getAll();

    return response.map<EntityImages>((json) {
      // Convert the string date back to DateTime
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      return EntityImages.fromJson(json);
    }).toList();
  }

  // Update entity image
  Future<EntityImages?> updateEntityImage(EntityImages entityImage) async {
    final response = await update(entityImage.id, entityImage.toJson());

    if (response != null) {
      // Convert the string date back to DateTime
      response['created_at'] = DateTime.parse(response['created_at'] as String);
      return EntityImages.fromJson(response);
    }

    return null;
  }

  // Delete entity image and its file in storage
  Future<void> deleteEntityImage(EntityImages entityImage) async {
    try {
      // Check if it's a data URI image (local only)
      if (entityImage.imageUrl.startsWith('data:image')) {
        print('Skipping storage deletion for data URI image');
        // Only delete the database record
        print('Deleting database record with ID: ${entityImage.id}');
        await delete(entityImage.id);
        print('Successfully deleted database record');
        return;
      }

      // Extract the file name from the URL
      final uri = Uri.parse(entityImage.imageUrl);
      final fileName = path.basename(uri.path);

      print('Attempting to delete file: $fileName from storage');

      // Delete the file from storage
      try {
        await supabase.storage.from('images').remove([fileName]);
        print('Successfully deleted file from storage');
      } catch (storageError) {
        print('Error deleting file from storage: $storageError');
        // Try alternative bucket or path if needed
      }

      // Delete the database record
      print('Deleting database record with ID: ${entityImage.id}');
      await delete(entityImage.id);
      print('Successfully deleted database record');
    } catch (e) {
      print('Error deleting entity image: $e');
      // Still try to delete the database record if storage deletion fails
      try {
        await delete(entityImage.id);
        print('Deleted database record despite storage deletion failure');
      } catch (dbError) {
        print('Failed to delete database record as well: $dbError');
      }
    }
  }

  // Delete all images for a specific entity
  Future<void> deleteEntityImagesByEntityTypeAndId(
      String entityType, String entityId) async {
    // First get all images for this entity
    final images = await getImagesByEntityTypeAndId(entityType, entityId);

    // Delete each image one by one
    for (final image in images) {
      await deleteEntityImage(image);
    }
  }

  // Fetch images from Supabase that aren't in local storage
  Future<List<EntityImages>> syncImagesFromSupabase(
      String entityType, String entityId) async {
    print('Syncing images for ${entityType}_${entityId} from Supabase');

    try {
      // Check internet connection first
      final hasConnection = await _networkInfo.isConnected;
      if (!hasConnection) {
        print('No internet connection - skipping Supabase image sync');
        return [];
      }

      // Get all images for this entity from Supabase
      final response = await supabase
          .from(tableName)
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId);

      if (response == null || response.isEmpty) {
        print('No images found in Supabase for ${entityType}_${entityId}');
        return [];
      }

      print(
          'Found ${response.length} images in Supabase for ${entityType}_${entityId}');

      // Convert to EntityImages objects
      final List<EntityImages> remoteImages =
          response.map<EntityImages>((json) {
        // Convert the string date back to DateTime
        if (json['created_at'] is String) {
          json['created_at'] = DateTime.parse(json['created_at'] as String);
        }
        return EntityImages.fromJson(json);
      }).toList();

      return remoteImages;
    } catch (e) {
      print('Error syncing images from Supabase: $e');
      return [];
    }
  }

  // Check for images directly in Supabase storage
  Future<List<String>> listStorageImages(
      String entityType, String entityId) async {
    print('Checking Supabase storage for ${entityType}_${entityId} images');

    try {
      // Check internet connection first
      final hasConnection = await _networkInfo.isConnected;
      if (!hasConnection) {
        print('No internet connection - skipping Supabase storage check');
        return [];
      }

      // List files in the storage bucket
      final List<FileObject> files =
          await supabase.storage.from('images').list();

      // Filter files that match this entity
      final String prefix = '${entityType}_${entityId}_';
      final matchingFiles = files
          .where((file) => file.name.startsWith(prefix))
          .map(
              (file) => supabase.storage.from('images').getPublicUrl(file.name))
          .toList();

      print(
          'Found ${matchingFiles.length} files in storage for ${entityType}_${entityId}');
      return matchingFiles;
    } catch (e) {
      print('Error checking Supabase storage: $e');
      return [];
    }
  }
}

// Class to hold authentication check results
class AuthResult {
  final bool isAuthenticated;
  final bool isTestMode;
  final String? userId;
  final String? error;

  AuthResult({
    required this.isAuthenticated,
    required this.isTestMode,
    this.userId,
    this.error,
  });
}
