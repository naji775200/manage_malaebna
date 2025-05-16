import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/entity_images_repository.dart';
import '../../data/models/entity_images_model.dart';
import '../../presentation/widgets/custom_snackbar.dart';
import '../services/translation_service.dart';

/// A helper class to manage image uploads for different entity types
/// (stadium, field, owner) with consistent behavior and error handling
class ImageUploadHelper {
  final EntityImagesRepository _imagesRepository;
  final ImagePicker _imagePicker;
  final BuildContext context;
  final TranslationService translationService;

  /// Constructor requiring repository, context, and translation service
  ImageUploadHelper({
    required this.context,
    required this.translationService,
    EntityImagesRepository? imagesRepository,
    ImagePicker? imagePicker,
  })  : _imagesRepository = imagesRepository ?? EntityImagesRepository(),
        _imagePicker = imagePicker ?? ImagePicker();

  /// Upload a single image for an entity
  Future<EntityImages?> uploadSingleImage({
    required String entityType,
    required String entityId,
    bool replaceExisting = true,
    int imageQuality = 80,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (imageFile == null) {
        // User canceled image picking
        return null;
      }

      final file = File(imageFile.path);

      // Display loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              translationService.tr('common.uploading_image', {}, context) ??
                  'Uploading image...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Upload the image
      final entityImage = await _imagesRepository.uploadImage(
        imageFile: file,
        entityType: entityType,
        entityId: entityId,
        replaceExisting: replaceExisting,
      );

      // Show success message
      CustomSnackBar.showSuccess(
        context,
        translationService.tr('snackbar.success.image_added', {}, context) ??
            'Image added successfully',
      );

      return entityImage;
    } catch (e) {
      print('Error uploading image: $e');
      CustomSnackBar.showError(
        context,
        translationService.tr('snackbar.error.image_upload_failed',
                {'error': e.toString()}, context) ??
            'Failed to upload image: $e',
      );
      return null;
    }
  }

  /// Get all images for an entity
  Future<List<EntityImages>> getEntityImages({
    required String entityType,
    required String entityId,
    bool forceRefresh = false,
  }) async {
    try {
      return await _imagesRepository.getImagesByEntityTypeAndId(
        entityType,
        entityId,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      print('Error getting images: $e');
      // Instead of showing a snackbar, just return empty list
      // The UI should handle empty states gracefully
      return [];
    }
  }

  /// Delete an image by its ID
  Future<bool> deleteImage(String imageId) async {
    try {
      await _imagesRepository.delete(imageId);
      CustomSnackBar.showSuccess(
        context,
        translationService.tr('snackbar.success.image_removed', {}, context) ??
            'Image removed successfully',
      );
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      CustomSnackBar.showError(
        context,
        translationService.tr('snackbar.error.image_delete_failed',
                {'error': e.toString()}, context) ??
            'Failed to delete image: $e',
      );
      return false;
    }
  }

  /// Upload multiple images (up to maxImages) for an entity
  Future<List<EntityImages>> uploadMultipleImages({
    required String entityType,
    required String entityId,
    int maxImages = 5,
    bool replaceExisting = false,
    int imageQuality = 80,
  }) async {
    try {
      // First get current images to check count
      final currentImages = await getEntityImages(
        entityType: entityType,
        entityId: entityId,
      );

      if (currentImages.length >= maxImages) {
        CustomSnackBar.showWarning(
          context,
          translationService.tr('common.max_images_reached',
                  {'count': maxImages.toString()}, context) ??
              'Maximum of $maxImages images allowed',
        );
        return currentImages;
      }

      // Calculate how many more images we can add
      final int remainingSlots = maxImages - currentImages.length;

      // Pick multiple images
      final List<XFile>? pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: imageQuality,
      );

      if (pickedFiles == null || pickedFiles.isEmpty) {
        // User canceled image picking
        return currentImages;
      }

      // Take only what we need to stay under the max
      final imagesToUpload = pickedFiles.take(remainingSlots).toList();

      if (imagesToUpload.isEmpty) {
        return currentImages;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translationService.tr('common.uploading_images',
                  {'count': imagesToUpload.length.toString()}, context) ??
              'Uploading ${imagesToUpload.length} images...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Upload each image
      List<EntityImages> uploadedImages = [];

      for (final xFile in imagesToUpload) {
        final file = File(xFile.path);
        try {
          final entityImage = await _imagesRepository.uploadImage(
            imageFile: file,
            entityType: entityType,
            entityId: entityId,
            replaceExisting: false, // Never replace when uploading multiple
          );
          uploadedImages.add(entityImage);
        } catch (e) {
          print('Error uploading one of multiple images: $e');
          // Continue with remaining images
        }
      }

      if (uploadedImages.isNotEmpty) {
        CustomSnackBar.showSuccess(
          context,
          translationService.tr('common.uploaded_multiple_images',
                  {'count': uploadedImages.length.toString()}, context) ??
              'Uploaded ${uploadedImages.length} images successfully',
        );

        // Get fresh list of all images after upload
        return await getEntityImages(
          entityType: entityType,
          entityId: entityId,
          forceRefresh: true,
        );
      } else {
        CustomSnackBar.showError(
          context,
          translationService.tr(
                  'common.failed_to_upload_images', {}, context) ??
              'Failed to upload images',
        );
        return currentImages;
      }
    } catch (e) {
      print('Error in uploadMultipleImages: $e');
      CustomSnackBar.showError(
        context,
        translationService.tr('snackbar.error.image_upload_failed',
                {'error': e.toString()}, context) ??
            'Failed to upload images: $e',
      );
      return [];
    }
  }

  /// Find and delete an image by comparing URLs
  Future<bool> deleteImageByUrl({
    required String entityType,
    required String entityId,
    required String imageUrl,
  }) async {
    try {
      final images = await getEntityImages(
        entityType: entityType,
        entityId: entityId,
      );

      for (final image in images) {
        if (image.imageUrl == imageUrl) {
          return await deleteImage(image.id);
        }
      }

      print('Image with URL not found in database');
      return false;
    } catch (e) {
      print('Error deleting image by URL: $e');
      return false;
    }
  }
}
