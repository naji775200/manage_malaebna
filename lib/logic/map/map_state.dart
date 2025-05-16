import 'package:equatable/equatable.dart';
import 'map_event.dart'; // Import for our custom LatLng class

enum MapStatus {
  initial,
  loading,
  success, // renamed from loaded to match with other Bloc patterns
  error,
  permissionDenied,
  serviceDisabled,
}

class MapState extends Equatable {
  final MapStatus status;
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final String? country;
  final String? city;
  final String? district;
  final String? errorMessage;
  final bool isLoadingAddress;

  const MapState({
    this.status = MapStatus.initial,
    this.currentLocation,
    this.selectedLocation,
    this.country,
    this.city,
    this.district,
    this.errorMessage,
    this.isLoadingAddress = false,
  });

  MapState copyWith({
    MapStatus? status,
    LatLng? currentLocation,
    LatLng? selectedLocation,
    String? country,
    String? city,
    String? district,
    String? errorMessage,
    bool? isLoadingAddress,
  }) {
    return MapState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingAddress: isLoadingAddress ?? this.isLoadingAddress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentLocation,
        selectedLocation,
        country,
        city,
        district,
        errorMessage,
        isLoadingAddress,
      ];

  // Helper getters
  bool get isInitial => status == MapStatus.initial;
  bool get isLoading => status == MapStatus.loading;
  bool get isSuccess => status == MapStatus.success;
  bool get isError => status == MapStatus.error;
  bool get hasSelectedLocation => selectedLocation != null;
}
