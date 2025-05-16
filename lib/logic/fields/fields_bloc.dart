import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/repositories/field_repository.dart';
import '../../data/repositories/entity_images_repository.dart';
import '../../data/remote/field_remote_data_source.dart';
import '../../data/local/field_local_data_source.dart';
import '../../data/models/field_model.dart';
import '../../data/models/entity_images_model.dart';
import 'fields_event.dart';
import 'fields_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class FieldsBloc extends Bloc<FieldsEvent, FieldsState> {
  final FieldRepository _fieldRepository;
  final String _stadiumId;

  FieldsBloc({required String stadiumId})
      : _stadiumId = stadiumId,
        _fieldRepository = FieldRepository(
          remoteDataSource: FieldRemoteDataSource(
            supabaseClient: Supabase.instance.client,
          ),
          localDataSource: FieldLocalDataSource(),
          connectivity: Connectivity(),
        ),
        super(const FieldsState()) {
    on<LoadFields>(_onLoadFields);
    on<RefreshFields>(_onRefreshFields);
    on<AddField>(_onAddField);
    on<UpdateField>(_onUpdateField);
    on<DeleteField>(_onDeleteField);
  }

  Future<void> _onLoadFields(
    LoadFields event,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.copyWith(status: FieldsStatus.loading));

    try {
      final fields = await _fieldRepository.getFieldsByStadiumId(_stadiumId);
      emit(state.copyWith(
        status: FieldsStatus.success,
        fields: fields,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FieldsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshFields(
    RefreshFields event,
    Emitter<FieldsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final fields = await _fieldRepository.getFieldsByStadiumId(
        _stadiumId,
        forceRefresh: true,
      );

      emit(state.copyWith(
        status: FieldsStatus.success,
        fields: fields,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FieldsStatus.failure,
        errorMessage: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  Future<void> _onAddField(
    AddField event,
    Emitter<FieldsState> emit,
  ) async {
    // Log incoming data for debugging
    print('Adding field with data: ${event.fieldData}');
    print('Current stadiumId: $_stadiumId');

    try {
      // Get temp ID from field data if available, otherwise generate a new one
      final tempFieldId = event.fieldData['temp_id'] as String? ??
          'temp_${DateTime.now().millisecondsSinceEpoch}';

      print('Using tempFieldId: $tempFieldId for field creation');

      // Parse the capacity string correctly to extract just the first number
      int? recommendedPlayersNumber;
      if (event.fieldData['capacity'] != null) {
        final capacityStr = event.fieldData['capacity'] as String;
        print('Parsing capacity string: $capacityStr');

        // Extract just the first number from the capacity string (e.g., "7" from "7x7")
        if (capacityStr.contains('x')) {
          final parts = capacityStr.split('x');
          if (parts.isNotEmpty && parts[0].isNotEmpty) {
            recommendedPlayersNumber = int.tryParse(parts[0]);
            print(
                'Parsed player number: $recommendedPlayersNumber from $capacityStr');
          }
        }
      }

      // Create a new Field object with the data from the UI
      final newField = Field(
        id: tempFieldId,
        stadiumId: _stadiumId,
        name: event.fieldData['name'] ?? '',
        size: event.fieldData['size'] ?? '',
        surfaceType: event.fieldData['surface_type'] ?? 'Standard',
        createdAt: DateTime.now(),
        status: 'available', // Default status for new fields
        recommendedPlayersNumber: recommendedPlayersNumber,
      );

      // Save any images that were added during field creation
      final imageUrls = event.fieldData['images'] as List<String>?;
      print(
          'Field has ${imageUrls?.length ?? 0} images associated with tempFieldId: $tempFieldId');

      // Log the created field object
      print('Created field object: ${newField.toJson()}');

      try {
        print('Attempting to create field in repository...');
        final createdField = await _fieldRepository.createField(newField);
        print('Field created successfully with ID: ${createdField.id}');

        // If we have images and the ID changed, we need to reassociate them
        if (imageUrls != null &&
            imageUrls.isNotEmpty &&
            createdField.id != tempFieldId) {
          print(
              'Reassociating images from temp ID: $tempFieldId to real field ID: ${createdField.id}');

          // Import the EntityImagesRepository to handle image reassociation
          final imagesRepository = EntityImagesRepository();

          try {
            // Use the new direct transfer method
            int transferred = await imagesRepository.transferImages(
                'field', tempFieldId, createdField.id);

            if (transferred > 0) {
              print(
                  'Successfully transferred $transferred images to the new field ID');
            } else {
              // If no images transferred, try the alternative format
              print(
                  'No images transferred with primary format, trying alternative...');

              // Try the old temp_field_ format for backward compatibility
              final altTempId = 'temp_field_${tempFieldId.split('_').last}';
              print('Looking for images with alternative ID: $altTempId');

              transferred = await imagesRepository.transferImages(
                  'field', altTempId, createdField.id);

              if (transferred > 0) {
                print(
                    'Successfully transferred $transferred images from alternative ID');
              } else {
                print(
                    'No images found with any ID format. Check that images were properly saved.');
              }
            }
          } catch (imageError) {
            print('Error reassociating images: $imageError');
            // Continue with field creation even if image reassociation fails
          }
        }

        final updatedFields = [...state.fields, createdField];

        emit(state.copyWith(
          fields: updatedFields,
          status: FieldsStatus.success,
        ));
      } catch (repoError) {
        print('Error in repository: $repoError');
        rethrow; // Rethrow to be caught by outer catch block
      }
    } catch (e) {
      print('Failed to add field: $e');
      emit(state.copyWith(
        status: FieldsStatus.failure,
        errorMessage: 'Failed to add field: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateField(
    UpdateField event,
    Emitter<FieldsState> emit,
  ) async {
    try {
      // Find existing field
      final existingField = state.fields.firstWhere(
        (field) => field.id == event.fieldId,
        orElse: () => throw Exception('Field not found'),
      );

      print('Updating field: ${existingField.id}');
      print('Update data: ${event.fieldData}');

      // Debug the status/availability values
      final directStatus = event.fieldData['status'];
      final availabilityValue = event.fieldData['availability'];
      print('Direct status value: $directStatus');
      print('Received availability value: $availabilityValue');

      // First check direct status value, then try mapping from availability
      String? finalStatus;

      if (directStatus != null) {
        // If 'status' is provided directly, use it
        finalStatus = directStatus as String;
        print('Using direct status value: $finalStatus');
      } else if (availabilityValue != null) {
        // If only 'availability' is provided, map it
        finalStatus = _mapAvailabilityToStatus(availabilityValue);
        print(
            'Mapped status from availability: $finalStatus (from $availabilityValue)');
      }

      // Parse the capacity string correctly to extract just the first number
      // This avoids the issue where "7x7" gets converted to 77 and accumulates
      int? recommendedPlayersNumber;
      if (event.fieldData['capacity'] != null) {
        final capacityStr = event.fieldData['capacity'] as String;
        print('Parsing capacity string: $capacityStr');

        // Extract just the first number from the capacity string (e.g., "7" from "7x7")
        if (capacityStr.contains('x')) {
          final parts = capacityStr.split('x');
          if (parts.isNotEmpty && parts[0].isNotEmpty) {
            recommendedPlayersNumber = int.tryParse(parts[0]);
            print(
                'Parsed player number: $recommendedPlayersNumber from $capacityStr');
          }
        }
      }

      // Create updated field
      final updatedField = existingField.copyWith(
        name: event.fieldData['name'] ?? existingField.name,
        size: event.fieldData['size'] ?? existingField.size,
        surfaceType:
            event.fieldData['surface_type'] ?? existingField.surfaceType,
        status: finalStatus ?? existingField.status,
        recommendedPlayersNumber:
            recommendedPlayersNumber ?? existingField.recommendedPlayersNumber,
      );

      print('Updated field object: ${updatedField.toJson()}');
      print(
          'Field status before update: ${existingField.status}, after update: ${updatedField.status}');

      // Update in repository
      final savedField = await _fieldRepository.updateField(updatedField);
      print('Field updated successfully in repository');
      print('Final field status after repository save: ${savedField.status}');

      // Update state
      final updatedFields = state.fields.map((field) {
        if (field.id == event.fieldId) {
          return savedField;
        }
        return field;
      }).toList();

      emit(state.copyWith(
        fields: updatedFields,
        status: FieldsStatus.success,
      ));
    } catch (e) {
      print('Failed to update field: $e');
      emit(state.copyWith(
        status: FieldsStatus.failure,
        errorMessage: 'Failed to update field: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteField(
    DeleteField event,
    Emitter<FieldsState> emit,
  ) async {
    try {
      await _fieldRepository.deleteField(event.fieldId);

      final updatedFields =
          state.fields.where((field) => field.id != event.fieldId).toList();

      emit(state.copyWith(
        fields: updatedFields,
        status: FieldsStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FieldsStatus.failure,
        errorMessage: 'Failed to delete field: ${e.toString()}',
      ));
    }
  }

  // Helper to convert UI availability to model status
  String? _mapAvailabilityToStatus(String? availability) {
    // Handle both English and Arabic values
    // Convert to lowercase for case-insensitive comparison
    if (availability == null) return null;

    final lowerCaseAvailability = availability.toLowerCase();

    // Match English values
    if (lowerCaseAvailability.contains('available') ||
        lowerCaseAvailability == 'متاح') {
      return 'available';
    } else if (lowerCaseAvailability.contains('booked') ||
        lowerCaseAvailability == 'محجوز') {
      return 'booked';
    } else if (lowerCaseAvailability.contains('maintenance') ||
        lowerCaseAvailability == 'صيانة') {
      return 'maintenance';
    }

    return null;
  }

  // Helper to convert model status to UI availability
  String mapStatusToAvailability(String status, {bool isArabic = false}) {
    if (isArabic) {
      // Return Arabic values
      switch (status) {
        case 'available':
          return 'متاح';
        case 'booked':
          return 'محجوز';
        case 'maintenance':
          return 'صيانة';
        default:
          return 'غير معروف';
      }
    } else {
      // Return English values
      switch (status) {
        case 'available':
          return 'Available';
        case 'booked':
          return 'Booked';
        case 'maintenance':
          return 'Maintenance';
        default:
          return 'Unknown';
      }
    }
  }
}
