import 'package:sqflite/sqflite.dart';
import '../models/stadium_model.dart';
import '../models/field_model.dart';
import '../models/service_model.dart';
import '../models/working_hour_model.dart';
import '../models/time_off_model.dart';
import '../models/price_model.dart';
import '../models/coupon_model.dart';
import '../models/review_model.dart';
import '../models/owner_model.dart';
import 'base_local_data_source.dart';
import 'dart:convert';

class StadiumLocalDataSource extends BaseLocalDataSource<Stadium> {
  StadiumLocalDataSource() : super('stadiums');

  Future<Stadium?> getStadiumById(String id) async {
    final db = await database;
    final stadiumMap = await getById(id);

    if (stadiumMap == null) {
      return null;
    }

    // Get related entities
    final fields = await _getFields(db, id);
    final services = await _getServices(db, id);
    final workingHours = await _getWorkingHours(db, id);
    final timesOff = await _getTimesOff(db, id);
    final prices = await _getPrices(db, id);
    final coupons = await _getCoupons(db, id);
    final reviews = await _getReviews(db, id);
    final owners = await _getOwners(db, id);
    final imageUrls = await _getImageUrls(db, id);

    final stadium = Stadium.fromJson(stadiumMap);

    // Return a complete Stadium object with all related entities
    return stadium.copyWith(
      fields: fields,
      services: services,
      workingHours: workingHours,
      timesOff: timesOff,
      prices: prices,
      coupons: coupons,
      reviews: reviews,
      owners: owners,
      imageUrls: imageUrls,
    );
  }

  Future<List<Stadium>> getAllStadiums() async {
    final db = await database;
    final stadiumMaps = await getAll();

    // Convert maps to Stadium objects
    final stadiums = <Stadium>[];
    for (final stadiumMap in stadiumMaps) {
      final stadium = Stadium.fromJson(stadiumMap);

      // Get related entities
      final fields = await _getFields(db, stadium.id);
      final services = await _getServices(db, stadium.id);
      final workingHours = await _getWorkingHours(db, stadium.id);
      final timesOff = await _getTimesOff(db, stadium.id);
      final prices = await _getPrices(db, stadium.id);
      final coupons = await _getCoupons(db, stadium.id);
      final reviews = await _getReviews(db, stadium.id);
      final owners = await _getOwners(db, stadium.id);
      final imageUrls = await _getImageUrls(db, stadium.id);

      // Add a complete Stadium object with all related entities
      stadiums.add(stadium.copyWith(
        fields: fields,
        services: services,
        workingHours: workingHours,
        timesOff: timesOff,
        prices: prices,
        coupons: coupons,
        reviews: reviews,
        owners: owners,
        imageUrls: imageUrls,
      ));
    }

    return stadiums;
  }

  Future<String> insertStadium(Stadium stadium) async {
    final db = await database;

    // Start a transaction to ensure all related data is inserted atomically
    try {
    return await db.transaction((txn) async {
        print("Starting to insert stadium: ${stadium.id}");

      // Insert stadium
      final stadiumId = await txn.insert(
        'stadiums',
        stadium.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
        print("Inserted main stadium record: ${stadium.id}");

        try {
          // Insert related entities with individual try-catch blocks
      await _insertFields(txn, stadium.fields);
          print("Inserted ${stadium.fields.length} fields");
        } catch (e) {
          print("Error inserting fields: $e");
        }

        try {
      await _insertServices(txn, stadium.id, stadium.services);
          print("Inserted ${stadium.services.length} services");
        } catch (e) {
          print("Error inserting services: $e");
        }

        try {
      await _insertWorkingHours(txn, stadium.workingHours);
          print("Inserted ${stadium.workingHours.length} working hours");
        } catch (e) {
          print("Error inserting working hours: $e");
        }

        try {
      await _insertTimesOff(txn, stadium.timesOff);
          print("Inserted ${stadium.timesOff.length} times off");
        } catch (e) {
          print("Error inserting times off: $e");
        }

        try {
      await _insertPrices(txn, stadium.prices);
          print("Inserted ${stadium.prices.length} prices");
        } catch (e) {
          print("Error inserting prices: $e");
        }

        try {
      await _insertCoupons(txn, stadium.coupons);
          print("Inserted ${stadium.coupons.length} coupons");
        } catch (e) {
          print("Error inserting coupons: $e");
        }

        try {
      await _insertOwners(txn, stadium.id, stadium.owners);
          print("Inserted ${stadium.owners.length} owners");
        } catch (e) {
          print("Error inserting owners: $e");
        }

        try {
      await _insertImageUrls(txn, 'stadium', stadium.id, stadium.imageUrls);
          print("Inserted ${stadium.imageUrls.length} image URLs");
        } catch (e) {
          print("Error inserting image URLs: $e");
        }

        print("Successfully completed inserting stadium: ${stadium.id}");
      return stadium.id;
    });
    } catch (e) {
      print("Fatal error during stadium insertion: $e");
      // In case of a fatal error, try to insert just the stadium record without related entities
      try {
        await db.insert(
          'stadiums',
          stadium.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Inserted bare stadium record as fallback");
        return stadium.id;
      } catch (fallbackError) {
        print("Even fallback stadium insertion failed: $fallbackError");
        rethrow;
      }
    }
  }

  Future<int> updateStadium(Stadium stadium) async {
    final db = await database;

    // Start a transaction to ensure all related data is updated atomically
    try {
    return await db.transaction((txn) async {
        print("Starting to update stadium: ${stadium.id}");

      // Update stadium
      final result = await txn.update(
        'stadiums',
        stadium.toJson(),
        where: 'id = ?',
        whereArgs: [stadium.id],
      );
        print("Updated main stadium record: ${stadium.id}");

        try {
          // Delete existing related entities to avoid orphaned records
      await _deleteRelatedEntities(txn, stadium.id);
          print("Deleted existing related entities for stadium: ${stadium.id}");
        } catch (e) {
          print("Error deleting related entities: $e");
          // Continue with insert operations even if delete fails
        }

        // Insert updated related entities with individual error handling
        try {
      await _insertFields(txn, stadium.fields);
          print("Updated ${stadium.fields.length} fields");
        } catch (e) {
          print("Error updating fields: $e");
        }

        try {
      await _insertServices(txn, stadium.id, stadium.services);
          print("Updated ${stadium.services.length} services");
        } catch (e) {
          print("Error updating services: $e");
        }

        try {
      await _insertWorkingHours(txn, stadium.workingHours);
          print("Updated ${stadium.workingHours.length} working hours");
        } catch (e) {
          print("Error updating working hours: $e");
        }

        try {
      await _insertTimesOff(txn, stadium.timesOff);
          print("Updated ${stadium.timesOff.length} times off");
        } catch (e) {
          print("Error updating times off: $e");
        }

        try {
      await _insertPrices(txn, stadium.prices);
          print("Updated ${stadium.prices.length} prices");
        } catch (e) {
          print("Error updating prices: $e");
        }

        try {
      await _insertCoupons(txn, stadium.coupons);
          print("Updated ${stadium.coupons.length} coupons");
        } catch (e) {
          print("Error updating coupons: $e");
        }

        try {
      await _insertOwners(txn, stadium.id, stadium.owners);
          print("Updated ${stadium.owners.length} owners");
        } catch (e) {
          print("Error updating owners: $e");
        }

        try {
      await _insertImageUrls(txn, 'stadium', stadium.id, stadium.imageUrls);
          print("Updated ${stadium.imageUrls.length} image URLs");
        } catch (e) {
          print("Error updating image URLs: $e");
        }

        print("Successfully completed updating stadium: ${stadium.id}");
        return result;
      });
    } catch (e) {
      print("Fatal error during stadium update: $e");
      // In case of a fatal error, just try to update the main stadium record
      try {
        final result = await db.update(
          'stadiums',
          stadium.toJson(),
          where: 'id = ?',
          whereArgs: [stadium.id],
        );
        print("Updated bare stadium record as fallback");
        return result;
      } catch (fallbackError) {
        print("Even fallback stadium update failed: $fallbackError");
        rethrow;
      }
    }
  }

  // New method for updating only basic stadium data (main record and fields)
  Future<int> updateBasicStadium(Stadium stadium) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        print("Starting to update basic stadium: ${stadium.id}");

        // Update stadium main record
        final result = await txn.update(
          'stadiums',
          stadium.toJson(),
          where: 'id = ?',
          whereArgs: [stadium.id],
        );
        print("Updated basic stadium record: ${stadium.id}");

        // Only update fields - which are essential for the UI
        if (stadium.fields.isNotEmpty) {
          try {
            // First delete existing fields for this stadium
            await txn.delete(
              'fields',
              where: 'stadium_id = ?',
              whereArgs: [stadium.id],
            );

            // Then insert the updated fields
            await _insertFields(txn, stadium.fields);
            print("Updated ${stadium.fields.length} fields");
          } catch (e) {
            print("Error updating fields: $e");
          }
        }

        // Update image URLs if available
        if (stadium.imageUrls.isNotEmpty) {
          try {
            // Delete existing images
            await txn.delete(
              'entity_images',
              where: 'entity_id = ? AND entity_type = ?',
              whereArgs: [stadium.id, 'stadium'],
            );

            // Insert updated images
            await _insertImageUrls(
                txn, 'stadium', stadium.id, stadium.imageUrls);
            print("Updated ${stadium.imageUrls.length} image URLs");
          } catch (e) {
            print("Error updating image URLs: $e");
          }
        }

        print("Successfully completed updating basic stadium: ${stadium.id}");
      return result;
    });
    } catch (e) {
      print("Error during basic stadium update: $e");
      // In case of error, just update the main stadium record
      try {
        final result = await db.update(
          'stadiums',
          stadium.toJson(),
          where: 'id = ?',
          whereArgs: [stadium.id],
        );
        print("Updated bare stadium record as fallback");
        return result;
      } catch (fallbackError) {
        print("Even fallback stadium update failed: $fallbackError");
        rethrow;
      }
    }
  }

  Future<int> deleteStadium(String id) async {
    final db = await database;

    // Start a transaction to ensure all related data is deleted atomically
    return await db.transaction((txn) async {
      // Delete related entities
      await _deleteRelatedEntities(txn, id);

      // Delete stadium
      final result = await txn.delete(
        'stadiums',
        where: 'id = ?',
        whereArgs: [id],
      );

      return result;
    });
  }

  Future<void> _deleteRelatedEntities(Transaction txn, String stadiumId) async {
    // Delete fields
    await txn.delete(
      'fields',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    // Delete services
    await txn.delete(
      'stadiums_services',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    // Delete working hours
    await txn.delete(
      'working_hours',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    // Delete times off
    await txn.delete(
      'times_off',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    // Delete coupons
    await txn.delete(
      'coupons',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    // Delete stadium owners
    await txn.delete(
      'stadium_owners',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    // Delete images
    await txn.delete(
      'entity_images',
      where: 'entity_id = ? AND entity_type = ?',
      whereArgs: [stadiumId, 'stadium'],
    );
  }

  // Helper methods to fetch related entities
  Future<List<Field>> _getFields(Database db, String stadiumId) async {
    final maps = await db.query(
      'fields',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => Field.fromJson(map)).toList();
  }

  Future<List<Service>> _getServices(Database db, String stadiumId) async {
    final maps = await db.rawQuery('''
      SELECT s.* FROM services s
      JOIN stadiums_services ss ON s.id = ss.service_id
      WHERE ss.stadium_id = ?
    ''', [stadiumId]);

    return maps.map((map) => Service.fromJson(map)).toList();
  }

  Future<List<WorkingHours>> _getWorkingHours(
      Database db, String stadiumId) async {
    final maps = await db.query(
      'working_hours',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => WorkingHours.fromJson(map)).toList();
  }

  Future<List<TimeOff>> _getTimesOff(Database db, String stadiumId) async {
    final maps = await db.query(
      'times_off',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => TimeOff.fromJson(map)).toList();
  }

  Future<List<Price>> _getPrices(Database db, String stadiumId) async {
    try {
    final maps = await db.rawQuery('''
      SELECT p.* FROM prices p
      JOIN fields f ON p.field_id = f.id
      WHERE f.stadium_id = ?
    ''', [stadiumId]);

      return maps.map((map) {
        // Convert the comma-separated days_of_week string back to a list
        var daysOfWeekStr = map['days_of_week'] as String?;
        List<String> daysOfWeek = [];

        if (daysOfWeekStr != null) {
          if (daysOfWeekStr.startsWith('[') && daysOfWeekStr.endsWith(']')) {
            // It's a JSON array string
            try {
              daysOfWeek = List<String>.from(jsonDecode(daysOfWeekStr));
            } catch (e) {
              print('Error parsing JSON days_of_week: $e');
              daysOfWeek = daysOfWeekStr.split(',');
            }
          } else {
            // It's a comma-separated string
            daysOfWeek = daysOfWeekStr.split(',');
          }
        }

        // Create a new map with the parsed days_of_week
        final modifiedMap = Map<String, dynamic>.from(map);
        modifiedMap['days_of_week'] = daysOfWeek;

        return Price.fromJson(modifiedMap);
      }).toList();
    } catch (e) {
      print('Error getting prices for stadium $stadiumId: $e');
      return [];
    }
  }

  Future<List<Coupon>> _getCoupons(Database db, String stadiumId) async {
    try {
    final maps = await db.query(
      'coupons',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

      return maps.map((map) {
        // Convert the comma-separated days_of_week string back to a list
        var daysOfWeekStr = map['days_of_week'] as String?;
        List<String> daysOfWeek = [];

        if (daysOfWeekStr != null) {
          if (daysOfWeekStr.startsWith('[') && daysOfWeekStr.endsWith(']')) {
            // It's a JSON array string
            try {
              daysOfWeek = List<String>.from(jsonDecode(daysOfWeekStr));
            } catch (e) {
              print('Error parsing JSON days_of_week for coupon: $e');
              daysOfWeek = daysOfWeekStr.split(',');
            }
          } else {
            // It's a comma-separated string
            daysOfWeek = daysOfWeekStr.split(',');
          }
        }

        // Create a new map with the parsed days_of_week
        final modifiedMap = Map<String, dynamic>.from(map);
        modifiedMap['days_of_week'] = daysOfWeek;

        return Coupon.fromJson(modifiedMap);
      }).toList();
    } catch (e) {
      print('Error getting coupons for stadium $stadiumId: $e');
      return [];
    }
  }

  Future<List<Review>> _getReviews(Database db, String stadiumId) async {
    final maps = await db.query(
      'reviews',
      where: 'stadium_id = ?',
      whereArgs: [stadiumId],
    );

    return maps.map((map) => Review.fromJson(map)).toList();
  }

  Future<List<Owner>> _getOwners(Database db, String stadiumId) async {
    final maps = await db.rawQuery('''
      SELECT o.* FROM owners o
      JOIN stadium_owners so ON o.id = so.owner_id
      WHERE so.stadium_id = ?
    ''', [stadiumId]);

    return maps.map((map) => Owner.fromJson(map)).toList();
  }

  Future<List<String>> _getImageUrls(Database db, String entityId) async {
    final maps = await db.query(
      'entity_images',
      columns: ['image_url'],
      where: 'entity_id = ? AND entity_type = ?',
      whereArgs: [entityId, 'stadium'],
    );

    return maps.map((map) => map['image_url'] as String).toList();
  }

  // Helper methods to insert related entities
  Future<void> _insertFields(Transaction txn, List<Field> fields) async {
    for (final field in fields) {
      await txn.insert(
        'fields',
        field.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertServices(
      Transaction txn, String stadiumId, List<Service> services) async {
    for (final service in services) {
      // Insert service if it doesn't exist
      await txn.insert(
        'services',
        service.toJson(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Insert relation
      await txn.insert(
        'stadiums_services',
        {
          'id': '${stadiumId}_${service.id}',
          'stadium_id': stadiumId,
          'service_id': service.id,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertWorkingHours(
      Transaction txn, List<WorkingHours> workingHours) async {
    for (final wh in workingHours) {
      await txn.insert(
        'working_hours',
        wh.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertTimesOff(Transaction txn, List<TimeOff> timesOff) async {
    for (final timeOff in timesOff) {
      await txn.insert(
        'times_off',
        timeOff.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertPrices(Transaction txn, List<Price> prices) async {
    for (final price in prices) {
      try {
        // Convert days_of_week to a JSON string before storing in SQLite
        final priceMap = price.toJson();

        // Convert days_of_week array to a JSON string
        if (priceMap['days_of_week'] is List) {
          priceMap['days_of_week'] = priceMap['days_of_week'].join(',');
        }

        // Format time values as strings (HH:MM)
        priceMap['start_time'] =
            '${price.startTime.hour.toString().padLeft(2, '0')}:${price.startTime.minute.toString().padLeft(2, '0')}';
        priceMap['end_time'] =
            '${price.endTime.hour.toString().padLeft(2, '0')}:${price.endTime.minute.toString().padLeft(2, '0')}';

      await txn.insert(
        'prices',
          priceMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

        print('Successfully inserted price: ${price.id}');
      } catch (e) {
        print('Error inserting price ${price.id}: $e');
        // Continue with other prices even if one fails
      }
    }
  }

  Future<void> _insertCoupons(Transaction txn, List<Coupon> coupons) async {
    for (final coupon in coupons) {
      try {
        // Convert days_of_week to a string before storing in SQLite
        final couponMap = coupon.toJson();

        // Convert days_of_week array to a comma-separated string
        if (couponMap['days_of_week'] is List) {
          couponMap['days_of_week'] = couponMap['days_of_week'].join(',');
        }

        // Format time values as strings (HH:MM)
        couponMap['start_time'] =
            '${coupon.startTime.hour.toString().padLeft(2, '0')}:${coupon.startTime.minute.toString().padLeft(2, '0')}';
      
        couponMap['end_time'] =
            '${coupon.endTime.hour.toString().padLeft(2, '0')}:${coupon.endTime.minute.toString().padLeft(2, '0')}';
      
      await txn.insert(
        'coupons',
          couponMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

        print('Successfully inserted coupon: ${coupon.id}');
      } catch (e) {
        print('Error inserting coupon ${coupon.id}: $e');
        // Continue with other coupons even if one fails
      }
    }
  }

  Future<void> _insertOwners(
      Transaction txn, String stadiumId, List<Owner> owners) async {
    for (final owner in owners) {
      // Insert owner if it doesn't exist
      await txn.insert(
        'owners',
        owner.toJson(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Insert relation
      await txn.insert(
        'stadium_owners',
        {
          'id': '${stadiumId}_${owner.id}',
          'stadium_id': stadiumId,
          'owner_id': owner.id,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertImageUrls(Transaction txn, String entityType,
      String entityId, List<String> imageUrls) async {
    for (int i = 0; i < imageUrls.length; i++) {
      await txn.insert(
        'entity_images',
        {
          'id': '${entityId}_$i',
          'entity_type': entityType,
          'entity_id': entityId,
          'image_url': imageUrls[i],
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
