import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/map_repository.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository _mapRepository;

  MapBloc({required MapRepository mapRepository})
      : _mapRepository = mapRepository,
        super(const MapState()) {
    on<InitializeMap>(_onInitializeMap);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<LocationSelected>(_onLocationSelected);
    on<LoadAddressFromLocation>(_onLoadAddressFromLocation);
    on<ConfirmLocation>(_onConfirmLocation);
  }

  Future<void> _onInitializeMap(
    InitializeMap event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(status: MapStatus.loading));

    try {
      // Check if location permission is already granted
      final hasPermission = await _mapRepository.checkLocationPermission();

      if (hasPermission) {
        if (event.requestCurrentLocation) {
          // Get current location
          await _getCurrentLocation(emit);
        } else if (event.initialLocation != null) {
          // Use provided initial location
          emit(state.copyWith(
            status: MapStatus.success,
            selectedLocation: event.initialLocation,
            currentLocation: event.initialLocation,
          ));

          // Load address for initial location
          add(LoadAddressFromLocation(location: event.initialLocation!));
        } else {
          emit(state.copyWith(status: MapStatus.success));
        }
      } else {
        // Show permission dialog if permission not granted
        emit(state.copyWith(status: MapStatus.permissionDenied));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        errorMessage: 'Failed to initialize map: $e',
      ));
    }
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(status: MapStatus.loading));

    try {
      final granted = await _mapRepository.requestLocationPermission();

      if (granted) {
        // Get current location after permission is granted
        await _getCurrentLocation(emit);
      } else {
        emit(state.copyWith(
          status: MapStatus.permissionDenied,
          errorMessage: 'Location permission was denied',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        errorMessage: 'Failed to request location permission: $e',
      ));
    }
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(status: MapStatus.loading));
    await _getCurrentLocation(emit);
  }

  Future<void> _getCurrentLocation(Emitter<MapState> emit) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await _mapRepository.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          status: MapStatus.serviceDisabled,
          errorMessage:
              'Location services are disabled. Please enable in settings.',
        ));
        return;
      }

      // Get current location
      final currentLocation = await _mapRepository.getCurrentLocation();

      emit(state.copyWith(
        status: MapStatus.success,
        currentLocation: currentLocation,
        selectedLocation: currentLocation,
      ));

      // Load address information
      add(LoadAddressFromLocation(location: currentLocation));
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        errorMessage: 'Failed to get current location: $e',
      ));
    }
  }

  Future<void> _onLocationSelected(
    LocationSelected event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(
      selectedLocation: event.location,
    ));

    // Load address when location is selected
    add(LoadAddressFromLocation(location: event.location));
  }

  Future<void> _onLoadAddressFromLocation(
    LoadAddressFromLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(isLoadingAddress: true));

    try {
      final addressData =
          await _mapRepository.getAddressFromLocation(event.location);

      emit(state.copyWith(
        isLoadingAddress: false,
        country: addressData['country'],
        city: addressData['city'],
        district: addressData['district'],
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingAddress: false,
        errorMessage: 'Failed to load address information',
      ));
    }
  }

  Future<void> _onConfirmLocation(
    ConfirmLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(
      selectedLocation: event.location,
      country: event.country,
      city: event.city,
      district: event.district,
    ));
  }
}
