import 'package:sqflite/sqflite.dart';
import '../models/service_model.dart';
import 'base_local_data_source.dart';

class ServiceLocalDataSource extends BaseLocalDataSource<Service> {
  ServiceLocalDataSource() : super('services');

  @override
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        english_name TEXT NOT NULL,
        arabic_name TEXT NOT NULL,
        icon_name TEXT NOT NULL
      )
    ''');

    // Create many-to-many table for stadium services
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stadiums_services (
        id TEXT PRIMARY KEY,
        stadium_id TEXT NOT NULL,
        service_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Add method to check and update table schema if needed
  Future<void> ensureTableSchema() async {
    final db = await database;

    // Check if the required columns exist
    var tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
    print("DEBUG: Services table structure: $tableInfo");

    // If table exists but doesn't have the required columns, recreate it
    if (tableInfo.isNotEmpty) {
      bool hasEnglishName = false;
      bool hasArabicName = false;
      bool hasIconName = false;

      for (var column in tableInfo) {
        String columnName = column['name'] as String;
        if (columnName == 'english_name') hasEnglishName = true;
        if (columnName == 'arabic_name') hasArabicName = true;
        if (columnName == 'icon_name') hasIconName = true;
      }

      // If any required column is missing, recreate the table
      if (!hasEnglishName || !hasArabicName || !hasIconName) {
        print(
            "DEBUG: Services table missing required columns. Recreating table.");

        // Backup existing data
        List<Map<String, dynamic>> existingData = [];
        try {
          existingData = await db.query(tableName);
          print("DEBUG: Backed up ${existingData.length} services");
        } catch (e) {
          print("DEBUG: Error backing up services data: $e");
        }

        // Drop and recreate table
        await db.execute("DROP TABLE IF EXISTS $tableName");
        await createTable(db);

        // Try to restore data if possible
        for (var service in existingData) {
          try {
            // Create a valid service record with required fields
            Map<String, dynamic> validService = {
              'id': service['id'] ??
                  'service_${DateTime.now().millisecondsSinceEpoch}',
              'english_name': service['english_name'] ??
                  service['name'] ??
                  'Unknown Service',
              'arabic_name': service['arabic_name'] ??
                  service['name_ar'] ??
                  'خدمة غير معروفة',
              'icon_name': service['icon_name'] ?? 'sports',
            };

            await db.insert(tableName, validService,
                conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (e) {
            print("DEBUG: Error restoring service: $e");
          }
        }
      }
    }
  }

  Future<Service?> getServiceById(String id) async {
    await ensureTableSchema();
    final map = await getById(id);
    if (map != null) {
      return Service.fromJson(map);
    }
    return null;
  }

  Future<List<Service>> getAllServices() async {
    await ensureTableSchema();
    final maps = await getAll();
    return maps.map((map) => Service.fromJson(map)).toList();
  }

  Future<String> insertService(Service service) async {
    await ensureTableSchema();
    return await insert(service.toJson());
  }

  Future<int> updateService(Service service) async {
    await ensureTableSchema();
    return await update(service.toJson());
  }

  Future<int> deleteService(String id) async {
    await ensureTableSchema();
    return await delete(id);
  }

  Future<List<Service>> getServicesByStadiumId(String stadiumId) async {
    await ensureTableSchema();
    final db = await database;

    // First get service IDs from the many-to-many table
    final serviceIdMaps = await db.query(
      'stadiums_services',
      columns: ['service_id'],
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    if (serviceIdMaps.isEmpty) {
      return [];
    }

    final serviceIds =
        serviceIdMaps.map((map) => map['service_id'] as String).toList();

    // Then get the actual services
    final List<Map<String, dynamic>> serviceMaps = [];
    for (final serviceId in serviceIds) {
      final serviceMap = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [serviceId],
      );

      if (serviceMap.isNotEmpty) {
        serviceMaps.add(serviceMap.first);
      }
    }

    return serviceMaps.map((map) => Service.fromJson(map)).toList();
  }

  Future<void> addServiceToStadium(String stadiumId, String serviceId) async {
    await ensureTableSchema();
    final db = await database;
    await db.insert(
      'stadiums_services',
      {
        'id': '${stadiumId}_$serviceId', // Generate a composite ID
        'stadium_id': stadiumId,
        'service_id': serviceId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeServiceFromStadium(
      String stadiumId, String serviceId) async {
    await ensureTableSchema();
    final db = await database;
    await db.delete(
      'stadiums_services',
      where: 'stadium_id = ? AND service_id = ?',
      whereArgs: [stadiumId, serviceId],
    );
  }
}
