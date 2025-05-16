import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address_model.dart';

class AddressRemoteDataSource {
  final SupabaseClient supabase = Supabase.instance.client;
  final String tableName = 'addresses';

  Future<Address?> getAddressById(String id) async {
    try {
      final response =
          await supabase.from(tableName).select().eq('id', id).maybeSingle();

      if (response != null) {
        return Address.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting address by ID: $e');
      rethrow;
    }
  }

  Future<List<Address>> getAllAddresses() async {
    try {
      final response = await supabase.from(tableName).select();

      return (response as List).map((item) => Address.fromJson(item)).toList();
    } catch (e) {
      print('Error getting all addresses: $e');
      rethrow;
    }
  }

  Future<Address> createAddress(Address address) async {
    try {
      final response = await supabase
          .from(tableName)
          .insert(address.toJson())
          .select()
          .single();

      return Address.fromJson(response);
    } catch (e) {
      print('Error creating address: $e');
      rethrow;
    }
  }

  Future<Address> updateAddress(Address address) async {
    try {
      final response = await supabase
          .from(tableName)
          .update(address.toJson())
          .eq('id', address.id)
          .select()
          .single();

      return Address.fromJson(response);
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await supabase.from(tableName).delete().eq('id', id);
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  Future<List<Address>> getAddressesByCity(String city) async {
    try {
      final response = await supabase.from(tableName).select().eq('city', city);

      return (response as List).map((item) => Address.fromJson(item)).toList();
    } catch (e) {
      print('Error getting addresses by city: $e');
      rethrow;
    }
  }

  Future<List<Address>> getAddressesByCountry(String country) async {
    try {
      final response =
          await supabase.from(tableName).select().eq('country', country);

      return (response as List).map((item) => Address.fromJson(item)).toList();
    } catch (e) {
      print('Error getting addresses by country: $e');
      rethrow;
    }
  }

  Future<List<Address>> getNearbyAddresses(
      double latitude, double longitude, double radiusKm) async {
    try {
      // Using PostGIS for geographic queries in PostgreSQL
      final response = await supabase.rpc('get_nearby_addresses', params: {
        'ref_latitude': latitude,
        'ref_longitude': longitude,
        'radius_km': radiusKm
      });

      return (response as List).map((item) => Address.fromJson(item)).toList();
    } catch (e) {
      print('Error getting nearby addresses: $e');

      // Fallback to a simpler approach if the RPC function doesn't exist
      try {
        // Get all addresses (this is not efficient but serves as a fallback)
        final response = await supabase.from(tableName).select();
        final addresses =
            (response as List).map((item) => Address.fromJson(item)).toList();

        // Filter addresses by distance in Dart
        return addresses.where((address) {
          // Calculate distance using the Haversine formula
          final distance = _calculateDistance(
              latitude, longitude, address.latitude, address.longitude);
          return distance <= radiusKm;
        }).toList();
      } catch (fallbackError) {
        print('Error in fallback for nearby addresses: $fallbackError');
        rethrow;
      }
    }
  }

  // Calculate distance between two points using the Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c; // Distance in km
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
