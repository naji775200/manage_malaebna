import '../local/base_local_data_source.dart';
import '../models/entity_images_model.dart';

class EntityImagesLocalDataSource extends BaseLocalDataSource<EntityImages> {
  EntityImagesLocalDataSource() : super('entity_images');

  Future<String> createEntityImage(EntityImages entityImage) async {
    try {
      // Use toLocalJson instead of toJson to exclude user_id field
      return await insert(entityImage.toLocalJson());
    } catch (e) {
      print('Error saving entity image to local database: $e');
      rethrow;
    }
  }

  Future<EntityImages?> getEntityImageById(String id) async {
    final map = await getById(id);
    if (map != null) {
      final jsonMap = Map<String, dynamic>.from(map);
      // Convert the createdAt string back to DateTime
      jsonMap['created_at'] = DateTime.parse(jsonMap['created_at'] as String);
      return EntityImages.fromJson(jsonMap);
    }
    return null;
  }

  Future<List<EntityImages>> getAllEntityImages() async {
    final maps = await getAll();
    return maps.map((map) {
      final jsonMap = Map<String, dynamic>.from(map);
      // Convert the createdAt string back to DateTime
      jsonMap['created_at'] = DateTime.parse(jsonMap['created_at'] as String);
      return EntityImages.fromJson(jsonMap);
    }).toList();
  }

  Future<List<EntityImages>> getImagesByEntityTypeAndId(
      String entityType, String entityId) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );

    return maps.map((map) {
      final jsonMap = Map<String, dynamic>.from(map);
      // Convert the createdAt string back to DateTime
      jsonMap['created_at'] = DateTime.parse(jsonMap['created_at'] as String);
      return EntityImages.fromJson(jsonMap);
    }).toList();
  }

  Future<int> updateEntityImage(EntityImages entityImage) async {
    try {
      // Use toLocalJson instead of toJson to exclude user_id field
      return await update(entityImage.toLocalJson());
    } catch (e) {
      print('Error updating entity image in local database: $e');
      rethrow;
    }
  }

  Future<int> deleteEntityImage(String id) async {
    try {
      print('EntityImagesLocalDataSource: Deleting image with ID: $id');
      final result = await delete(id);
      print(
          'EntityImagesLocalDataSource: Deletion result: $result rows affected');
      return result;
    } catch (e) {
      print('EntityImagesLocalDataSource: Error deleting image: $e');
      rethrow;
    }
  }

  Future<int> deleteEntityImagesByEntityTypeAndId(
      String entityType, String entityId) async {
    try {
      print(
          'EntityImagesLocalDataSource: Deleting all images for $entityType/$entityId');

      // Get count before deletion for verification
      final before = await getImagesByEntityTypeAndId(entityType, entityId);
      print(
          'EntityImagesLocalDataSource: Found ${before.length} images to delete');

      final db = await database;
      final result = await db.delete(
        tableName,
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, entityId],
      );

      // Verify deletion
      final after = await getImagesByEntityTypeAndId(entityType, entityId);
      print(
          'EntityImagesLocalDataSource: Deletion complete. ${before.length} before, ${after.length} after, $result rows affected');

      return result;
    } catch (e) {
      print(
          'EntityImagesLocalDataSource: Error deleting images for $entityType/$entityId: $e');
      rethrow;
    }
  }
}
