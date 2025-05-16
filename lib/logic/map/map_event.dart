import 'package:equatable/equatable.dart';

// Custom LatLng class since google_maps_flutter isn't available yet
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class InitializeMap extends MapEvent {
  final bool requestCurrentLocation;
  final LatLng? initialLocation;

  const InitializeMap({
    this.requestCurrentLocation = true,
    this.initialLocation,
  });

  @override
  List<Object?> get props => [requestCurrentLocation, initialLocation];
}

class RequestLocationPermission extends MapEvent {}

class GetCurrentLocation extends MapEvent {}

class LocationSelected extends MapEvent {
  final LatLng location;

  const LocationSelected({required this.location});

  @override
  List<Object?> get props => [location];
}

class LoadAddressFromLocation extends MapEvent {
  final LatLng location;

  const LoadAddressFromLocation({required this.location});

  @override
  List<Object?> get props => [location];
}

class ConfirmLocation extends MapEvent {
  final LatLng location;
  final String? country;
  final String? city;
  final String? district;

  const ConfirmLocation({
    required this.location,
    this.country,
    this.city,
    this.district,
  });

  @override
  List<Object?> get props => [location, country, city, district];
}

class ReverseGeocodeEvent extends MapEvent {
  final LatLng location;

  const ReverseGeocodeEvent(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationPermissionDeniedEvent extends MapEvent {
  const LocationPermissionDeniedEvent();
}

class LocationServiceDisabledEvent extends MapEvent {
  const LocationServiceDisabledEvent();
}

class ResetMapEvent extends MapEvent {
  const ResetMapEvent();
}
