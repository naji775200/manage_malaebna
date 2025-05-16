import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stadium_model.dart';
import '../models/field_model.dart';
import '../models/service_model.dart';
import '../models/working_hour_model.dart';
import '../models/time_off_model.dart';
import '../models/price_model.dart';
import '../models/coupon_model.dart';
import '../models/review_model.dart';
import '../models/owner_model.dart';
import 'package:uuid/uuid.dart'; // Import UUID package

class StadiumRemoteDataSource {
  final SupabaseClient supabase = Supabase.instance.client;
  final String tableName = 'stadiums';

  Future<Stadium?> getStadiumById(String id) async {
    try {
      // Validate ID
      if (id.isEmpty) {
        print('❌ StadiumRemoteDataSource: Empty ID provided to getStadiumById');
        return null;
      }

      print('🏟️ StadiumRemoteDataSource: Fetching stadium with ID: $id');

      // Get stadium
      final stadiumResponse =
          await supabase.from(tableName).select().eq('id', id).maybeSingle();

      if (stadiumResponse == null) {
        print('❌ StadiumRemoteDataSource: No stadium found with ID: $id');
        return null;
      }

      print(
          '✅ StadiumRemoteDataSource: Found stadium: ${stadiumResponse['name']}');

      // Ensure all required fields have non-null values to prevent casting errors
      _ensureRequiredFields(stadiumResponse);

      // Get related entities
      final stadium = Stadium.fromJson(stadiumResponse);

      // Fetch fields for stadium
      List<Field> fields = [];
      try {
        fields = await _getFields(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${fields.length} fields for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching fields: $e');
        // Continue with empty fields list
      }

      // Fetch services for stadium
      List<Service> services = [];
      try {
        services = await _getServices(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${services.length} services for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching services: $e');
        // Continue with empty services list
      }

      // Fetch working hours for stadium
      List<WorkingHours> workingHours = [];
      try {
        workingHours = await _getWorkingHours(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${workingHours.length} working hours for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching working hours: $e');
        // Continue with empty working hours list
      }

      // Fetch times off for stadium
      List<TimeOff> timesOff = [];
      try {
        timesOff = await _getTimesOff(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${timesOff.length} time offs for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching times off: $e');
        // Continue with empty times off list
      }

      // Fetch prices for stadium's fields
      List<Price> prices = [];
      try {
        if (fields.isNotEmpty) {
          prices = await _getPrices(fields.map((f) => f.id).toList());
          print(
              '✅ StadiumRemoteDataSource: Fetched ${prices.length} prices for stadium $id');
        }
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching prices: $e');
        // Continue with empty prices list
      }

      // Fetch coupons for stadium
      List<Coupon> coupons = [];
      try {
        coupons = await _getCoupons(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${coupons.length} coupons for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching coupons: $e');
        // Continue with empty coupons list
      }

      // Fetch reviews for stadium
      List<Review> reviews = [];
      try {
        reviews = await _getReviews(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${reviews.length} reviews for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching reviews: $e');
        // Continue with empty reviews list
      }

      // Fetch owners for stadium
      List<Owner> owners = [];
      try {
        owners = await _getOwners(id);
        print(
            '✅ StadiumRemoteDataSource: Fetched ${owners.length} owners for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching owners: $e');
        // Continue with empty owners list
      }

      // Fetch image URLs
      List<String> imageUrls = [];
      try {
        imageUrls = await _getImageUrls(id, 'stadium');
        print(
            '✅ StadiumRemoteDataSource: Fetched ${imageUrls.length} images for stadium $id');
      } catch (e) {
        print('❌ StadiumRemoteDataSource: Error fetching images: $e');
        // Continue with empty image URLs list
      }

      // Return complete stadium with all related entities
      final completeStadium = stadium.copyWith(
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

      print(
          '✅ StadiumRemoteDataSource: Successfully built complete stadium object for $id');
      return completeStadium;
    } catch (e) {
      print('❌ StadiumRemoteDataSource: Error getting stadium by ID $id: $e');
      return null;
    }
  }

  // New method to get only basic stadium data without related entities
  Future<Stadium?> getBasicStadiumById(String id) async {
    try {
      print('Getting basic stadium data for ID: $id');
      // Get stadium basic info
      final stadiumResponse =
          await supabase.from(tableName).select().eq('id', id).maybeSingle();

      if (stadiumResponse == null) {
        print('No stadium found with ID: $id');
        return null;
      }

      // Ensure all required fields have non-null values
      _ensureRequiredFields(stadiumResponse);

      // Create basic stadium object
      final stadium = Stadium.fromJson(stadiumResponse);

      // We only need to fetch image URLs and fields as they're essential for the UI
      final imageUrls = await _getImageUrls(id, 'stadium');
      final fields = await _getFields(id);

      // Also fetch services for displaying in the service section
      final services = await _getServices(id);
      print('Fetched ${services.length} services for stadium $id');

      // Return stadium with minimal related entities
      return stadium.copyWith(
        imageUrls: imageUrls,
        fields: fields,
        services: services, // Include services in the returned Stadium object
      );
    } catch (e) {
      print('Error getting basic stadium by ID: $e');
      rethrow;
    }
  }

  Future<List<Stadium>> getAllStadiums() async {
    try {
      final response = await supabase.from(tableName).select();

      final stadiums = <Stadium>[];
      for (final stadiumData in response) {
        final stadium = Stadium.fromJson(stadiumData);
        final completeStadium = await getStadiumById(stadium.id);
        if (completeStadium != null) {
          stadiums.add(completeStadium);
        }
      }

      return stadiums;
    } catch (e) {
      print('Error getting all stadiums: $e');
      rethrow;
    }
  }

  Future<Stadium> createStadium(Stadium stadium) async {
    try {
      // Start by creating the stadium
      final stadiumResponse = await supabase
          .from(tableName)
          .insert(stadium.toJson())
          .select()
          .single();

      final createdStadium = Stadium.fromJson(stadiumResponse);

      // Create related entities
      await _createFields(stadium.fields);
      await _createServices(stadium.services);
      await _linkServicesToStadium(createdStadium.id, stadium.services);
      await _createWorkingHours(stadium.workingHours);
      await _createTimesOff(stadium.timesOff);
      await _createPrices(stadium.prices);
      await _createCoupons(stadium.coupons);
      await _linkOwnersToStadium(createdStadium.id, stadium.owners);
      await _createImageUrls(createdStadium.id, 'stadium', stadium.imageUrls);

      // Get the complete stadium with all related entities
      final completeStadium = await getStadiumById(createdStadium.id);
      return completeStadium!;
    } catch (e) {
      print('Error creating stadium: $e');
      rethrow;
    }
  }

  Future<Stadium> updateStadium(Stadium stadium) async {
    try {
      // Update stadium
      await supabase
          .from(tableName)
          .update(stadium.toJson())
          .eq('id', stadium.id);

      // Update related entities
      await _updateFields(stadium.fields);
      await _updateServices(stadium.services);
      await _updateStadiumServices(stadium.id, stadium.services);
      await _updateWorkingHours(stadium.workingHours);
      await _updateTimesOff(stadium.timesOff);
      await _updatePrices(stadium.prices);
      await _updateCoupons(stadium.coupons);
      await _updateStadiumOwners(stadium.id, stadium.owners);
      await _updateImageUrls(stadium.id, 'stadium', stadium.imageUrls);

      // Get the updated stadium with all related entities
      final updatedStadium = await getStadiumById(stadium.id);
      return updatedStadium!;
    } catch (e) {
      print('Error updating stadium: $e');
      rethrow;
    }
  }

  Future<void> deleteStadium(String id) async {
    try {
      // Delete stadium (this should cascade to all related entities in Supabase)
      await supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting stadium: $e');
      rethrow;
    }
  }

  // Helper methods to fetch related entities
  Future<List<Field>> _getFields(String stadiumId) async {
    final response =
        await supabase.from('fields').select().eq('stadium_id', stadiumId);

    return (response as List).map((item) => Field.fromJson(item)).toList();
  }

  Future<List<Service>> _getServices(String stadiumId) async {
    final response = await supabase
        .from('stadiums_services')
        .select('service_id')
        .eq('stadium_id', stadiumId);

    final serviceIds =
        (response as List).map((item) => item['service_id'] as String).toList();

    if (serviceIds.isEmpty) {
      return [];
    }

    final servicesResponse =
        await supabase.from('services').select().filter('id', 'in', serviceIds);

    return (servicesResponse as List)
        .map((item) => Service.fromJson(item))
        .toList();
  }

  Future<List<WorkingHours>> _getWorkingHours(String stadiumId) async {
    final response = await supabase
        .from('working_hours')
        .select()
        .eq('stadium_id', stadiumId);

    return (response as List)
        .map((item) => WorkingHours.fromJson(item))
        .toList();
  }

  // New method to get only working hours for a stadium (public version of _getWorkingHours)
  Future<List<WorkingHours>> getStadiumWorkingHours(String stadiumId) async {
    try {
      print('Getting working hours for stadium ID: $stadiumId');
      return await _getWorkingHours(stadiumId);
    } catch (e) {
      print('Error getting working hours for stadium: $e');
      rethrow;
    }
  }

  Future<List<TimeOff>> _getTimesOff(String stadiumId) async {
    final response =
        await supabase.from('times_off').select().eq('stadium_id', stadiumId);

    return (response as List).map((item) => TimeOff.fromJson(item)).toList();
  }

  // New method to get only times off for a stadium (public version of _getTimesOff)
  Future<List<TimeOff>> getStadiumTimesOff(String stadiumId) async {
    try {
      print('Getting times off for stadium ID: $stadiumId');
      return await _getTimesOff(stadiumId);
    } catch (e) {
      print('Error getting times off for stadium: $e');
      rethrow;
    }
  }

  Future<List<Price>> _getPrices(List<String> fieldIds) async {
    if (fieldIds.isEmpty) {
      return [];
    }

    final response = await supabase
        .from('prices')
        .select()
        .filter('field_id', 'in', fieldIds);

    return (response as List).map((item) => Price.fromJson(item)).toList();
  }

  Future<List<Coupon>> _getCoupons(String stadiumId) async {
    final response =
        await supabase.from('coupons').select().eq('stadium_id', stadiumId);

    return (response as List).map((item) => Coupon.fromJson(item)).toList();
  }

  Future<List<Review>> _getReviews(String stadiumId) async {
    final response =
        await supabase.from('reviews').select().eq('stadium_id', stadiumId);

    return (response as List).map((item) => Review.fromJson(item)).toList();
  }

  Future<List<Owner>> _getOwners(String stadiumId) async {
    final response = await supabase
        .from('stadium_owners')
        .select('owner_id')
        .eq('stadium_id', stadiumId);

    final ownerIds =
        (response as List).map((item) => item['owner_id'] as String).toList();

    if (ownerIds.isEmpty) {
      return [];
    }

    final ownersResponse =
        await supabase.from('owners').select().filter('id', 'in', ownerIds);

    return (ownersResponse as List)
        .map((item) => Owner.fromJson(item))
        .toList();
  }

  Future<List<String>> _getImageUrls(String entityId, String entityType) async {
    final response = await supabase
        .from('entity_images')
        .select('image_url')
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);

    return (response as List)
        .map((item) => item['image_url'] as String)
        .toList();
  }

  // Helper methods to create related entities
  Future<void> _createFields(List<Field> fields) async {
    for (final field in fields) {
      await supabase.from('fields').insert(field.toJson());
    }
  }

  Future<void> _createServices(List<Service> services) async {
    for (final service in services) {
      // Using upsert to avoid duplicate services
      await supabase.from('services').upsert(service.toJson());
    }
  }

  Future<void> _linkServicesToStadium(
      String stadiumId, List<Service> services) async {
    final uuid = Uuid(); // Create UUID generator

    for (final service in services) {
      // Generate a proper UUID instead of a concatenated string
      final id = uuid.v4();

      await supabase.from('stadiums_services').insert({
        'id': id, // Use UUID v4
        'stadium_id': stadiumId,
        'service_id': service.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _createWorkingHours(List<WorkingHours> workingHours) async {
    for (final wh in workingHours) {
      await supabase.from('working_hours').insert(wh.toJson());
    }
  }

  Future<void> _createTimesOff(List<TimeOff> timesOff) async {
    for (final timeOff in timesOff) {
      await supabase.from('times_off').insert(timeOff.toJson());
    }
  }

  Future<void> _createPrices(List<Price> prices) async {
    for (final price in prices) {
      await supabase.from('prices').insert(price.toJson());
    }
  }

  Future<void> _createCoupons(List<Coupon> coupons) async {
    for (final coupon in coupons) {
      await supabase.from('coupons').insert(coupon.toJson());
    }
  }

  Future<void> _linkOwnersToStadium(
      String stadiumId, List<Owner> owners) async {
    final uuid = Uuid(); // Create UUID generator

    for (final owner in owners) {
      // Generate a proper UUID instead of a concatenated string
      final id = uuid.v4();

      await supabase.from('stadium_owners').insert({
        'id': id, // Use UUID v4
        'stadium_id': stadiumId,
        'owner_id': owner.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _createImageUrls(
      String entityId, String entityType, List<String> imageUrls) async {
    final uuid = Uuid(); // Create UUID generator

    for (final imageUrl in imageUrls) {
      // Generate a proper UUID instead of a concatenated string
      final id = uuid.v4();

      await supabase.from('entity_images').insert({
        'id': id, // Use UUID v4
        'entity_type': entityType,
        'entity_id': entityId,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Helper methods to update related entities
  Future<void> _updateFields(List<Field> fields) async {
    for (final field in fields) {
      await supabase.from('fields').upsert(field.toJson());
    }
  }

  Future<void> _updateServices(List<Service> services) async {
    for (final service in services) {
      await supabase.from('services').upsert(service.toJson());
    }
  }

  Future<void> _updateStadiumServices(
      String stadiumId, List<Service> services) async {
    // Delete existing relations
    await supabase
        .from('stadiums_services')
        .delete()
        .eq('stadium_id', stadiumId);

    // Create new relations
    await _linkServicesToStadium(stadiumId, services);
  }

  Future<void> _updateWorkingHours(List<WorkingHours> workingHours) async {
    for (final wh in workingHours) {
      await supabase.from('working_hours').upsert(wh.toJson());
    }
  }

  Future<void> _updateTimesOff(List<TimeOff> timesOff) async {
    for (final timeOff in timesOff) {
      await supabase.from('times_off').upsert(timeOff.toJson());
    }
  }

  Future<void> _updatePrices(List<Price> prices) async {
    for (final price in prices) {
      await supabase.from('prices').upsert(price.toJson());
    }
  }

  Future<void> _updateCoupons(List<Coupon> coupons) async {
    for (final coupon in coupons) {
      await supabase.from('coupons').upsert(coupon.toJson());
    }
  }

  Future<void> _updateStadiumOwners(
      String stadiumId, List<Owner> owners) async {
    // Delete existing relations
    await supabase.from('stadium_owners').delete().eq('stadium_id', stadiumId);

    // Create new relations
    await _linkOwnersToStadium(stadiumId, owners);
  }

  Future<void> _updateImageUrls(
      String entityId, String entityType, List<String> imageUrls) async {
    // Delete existing images
    await supabase
        .from('entity_images')
        .delete()
        .eq('entity_id', entityId)
        .eq('entity_type', entityType);

    // Create new images
    await _createImageUrls(entityId, entityType, imageUrls);
  }

  // Helper method to ensure all required fields have non-null values
  void _ensureRequiredFields(Map<String, dynamic> stadiumData) {
    // Ensure required string fields have default values if null
    stadiumData['id'] = stadiumData['id'] ?? '';
    stadiumData['name'] = stadiumData['name'] ?? 'Unnamed Stadium';
    stadiumData['address_id'] = stadiumData['address_id'] ?? '';
    stadiumData['description'] = stadiumData['description'] ?? '';
    stadiumData['bank_number'] = stadiumData['bank_number'] ?? '';
    stadiumData['phone_number'] = stadiumData['phone_number'] ?? '';
    stadiumData['type'] = stadiumData['type'] ?? 'standard';
    stadiumData['status'] = stadiumData['status'] ?? 'pending';

    // Ensure numeric fields have default values if null
    stadiumData['average_review'] = stadiumData['average_review'] ?? 0.0;
    stadiumData['booked_count'] = stadiumData['booked_count'] ?? 0;
  }
}
