import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../local/field_local_data_source.dart';
import '../models/field_model.dart';
import '../remote/field_remote_data_source.dart';
import '../../core/utils/auth_utils.dart';

class FieldRepository {
  final FieldRemoteDataSource _remoteDataSource;
  final FieldLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  FieldRepository({
    required FieldRemoteDataSource remoteDataSource,
    required FieldLocalDataSource localDataSource,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  Future<bool> _hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<Field> getFieldById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      final remoteField = await _remoteDataSource.getFieldById(id);
      await _localDataSource.insertField(remoteField);
      return remoteField;
    }

    try {
      final localField = await _localDataSource.getFieldById(id);
      if (localField != null) {
        return localField;
      }
      throw Exception('Field not found locally');
    } catch (e) {
      final remoteField = await _remoteDataSource.getFieldById(id);
      await _localDataSource.insertField(remoteField);
      return remoteField;
    }
  }

  Future<List<Field>> getAllFields({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final remoteFields = await _remoteDataSource.getAllFields();
      for (var field in remoteFields) {
        await _localDataSource.insertField(field);
      }
      return remoteFields;
    }

    try {
      return await _localDataSource.getAllFields();
    } catch (e) {
      final remoteFields = await _remoteDataSource.getAllFields();
      for (var field in remoteFields) {
        await _localDataSource.insertField(field);
      }
      return remoteFields;
    }
  }

  Future<List<Field>> getFieldsByStadiumId(String stadiumId,
      {bool forceRefresh = false}) async {
    try {
      print(
          '🏟️ FieldRepository: Getting fields for stadium ID: $stadiumId (forceRefresh: $forceRefresh)');

      // UUID validation - Check if stadiumId is a valid UUID format
      final bool isValidUuid = _isValidUuid(stadiumId);
      if (!isValidUuid) {
        print(
            '⚠️ FieldRepository: Invalid UUID format for stadium ID: $stadiumId');

        // Try to get a valid stadium ID from auth
        try {
          final authStadiumId = await AuthUtils.getStadiumIdFromAuth();
          if (authStadiumId != null && _isValidUuid(authStadiumId)) {
            print(
                '✅ FieldRepository: Using valid UUID from auth: $authStadiumId instead of $stadiumId');
            // Retry with the valid stadium ID
            return await getFieldsByStadiumId(authStadiumId,
                forceRefresh: forceRefresh);
          }
        } catch (authError) {
          print(
              '⚠️ FieldRepository: Error getting stadium ID from auth: $authError');
        }

        // If we can't get a valid UUID, try to convert the given ID to a UUID
        try {
          const uuid = Uuid();
          const namespace = Uuid.NAMESPACE_URL;
          final uuidStr = uuid.v5(namespace, stadiumId);
          print(
              '⚠️ FieldRepository: Converting non-UUID stadium ID "$stadiumId" to UUID: $uuidStr');

          // Retry with the converted UUID
          return await getFieldsByStadiumId(uuidStr,
              forceRefresh: forceRefresh);
        } catch (conversionError) {
          print(
              '⚠️ FieldRepository: Error converting to UUID: $conversionError');
          print('⚠️ FieldRepository: Using empty list as fallback');
          return [];
        }
      }

      if (forceRefresh || await _hasInternetConnection()) {
        print(
            '🏟️ FieldRepository: Using remote data source due to forceRefresh or internet connection');
        try {
          final remoteFields =
              await _remoteDataSource.getFieldsByStadiumId(stadiumId);
          print(
              '🏟️ FieldRepository: Found ${remoteFields.length} fields remotely');

          for (var field in remoteFields) {
            print(
                '   - Field ID: ${field.id}, Name: ${field.name}, Stadium ID: ${field.stadiumId}');
            await _localDataSource.insertField(field);
          }
          return remoteFields;
        } catch (remoteError) {
          print(
              '❌ FieldRepository ERROR: Failed to get fields from remote: $remoteError');

          // Try local data source as fallback
          final localFields =
              await _localDataSource.getFieldsByStadiumId(stadiumId);
          print(
              '🏟️ FieldRepository: Found ${localFields.length} fields locally after remote failure');

          if (localFields.isNotEmpty) {
            return localFields;
          }

          // Return empty list instead of rethrowing to prevent further crashes
          return [];
        }
      } else {
        // No internet, use local data source
        print(
            '🏟️ FieldRepository: No internet connection, using local data source');
        final localFields =
            await _localDataSource.getFieldsByStadiumId(stadiumId);
        print(
            '🏟️ FieldRepository: Found ${localFields.length} fields locally');

        if (localFields.isNotEmpty) {
          for (var field in localFields) {
            print(
                '   - Field ID: ${field.id}, Name: ${field.name}, Stadium ID: ${field.stadiumId}');
          }
          return localFields;
        }

        // Return empty list instead of throwing to prevent UI crashes
        print(
            '⚠️ FieldRepository: No fields found locally and no internet connection');
        return [];
      }
    } catch (e) {
      print('❌ FieldRepository ERROR: Failed to get fields for stadium: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  // Helper method to check if a string is a valid UUID
  bool _isValidUuid(String str) {
    try {
      // Simple UUID validation regex pattern
      final RegExp uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);

      return uuidPattern.hasMatch(str);
    } catch (e) {
      print('⚠️ FieldRepository: Error validating UUID: $e');
      return false;
    }
  }

  Future<List<Field>> getFieldsByStatus(String status,
      {bool forceRefresh = false}) async {
    if (forceRefresh) {
      final remoteFields = await _remoteDataSource.getFieldsByStatus(status);
      for (var field in remoteFields) {
        await _localDataSource.insertField(field);
      }
      return remoteFields;
    }

    try {
      return await _localDataSource.getFieldsByStatus(status);
    } catch (e) {
      final remoteFields = await _remoteDataSource.getFieldsByStatus(status);
      for (var field in remoteFields) {
        await _localDataSource.insertField(field);
      }
      return remoteFields;
    }
  }

  Future<Field> createField(Field field) async {
    try {
      print('Repository: Creating field...');
      print('Field data: ${field.toJson()}');

      final hasInternet = await _hasInternetConnection();
      print('Internet connection available: $hasInternet');

      if (!hasInternet) {
        throw Exception(
            'No internet connection available. Cannot create field.');
      }

      // Try up to 3 times to create the field
      Exception? lastException;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print(
              'Calling remote data source to create field (attempt $attempt)...');
          final createdField = await _remoteDataSource.createField(field);
          print('Field created successfully in remote: ${createdField.id}');

          print('Saving field to local storage...');
          await _localDataSource.insertField(createdField);
          print('Field saved to local storage');

          return createdField;
        } catch (e) {
          print('Attempt $attempt failed: $e');
          lastException = e is Exception ? e : Exception(e.toString());

          // Wait before retrying
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }

      // If we get here, all attempts failed
      throw lastException ??
          Exception('Failed to create field after multiple attempts');
    } catch (e) {
      print('Error in repository createField: $e');
      rethrow;
    }
  }

  Future<Field> updateField(Field field) async {
    try {
      // Add debug logging for field update
      print('Repository: Updating field with ID: ${field.id}');
      print('Field data before update: ${field.toJson()}');
      print('Field status: ${field.status}');

      final updatedField = await _remoteDataSource.updateField(field);
      await _localDataSource.updateField(updatedField);

      print('Field updated in repository with status: ${updatedField.status}');
      return updatedField;
    } catch (e) {
      print('Error updating field in repository: $e');
      rethrow;
    }
  }

  Future<void> deleteField(String id) async {
    await _remoteDataSource.deleteField(id);
    await _localDataSource.deleteField(id);
  }
}
