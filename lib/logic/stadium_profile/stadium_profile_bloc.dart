import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/stadium_repository.dart';
import '../../data/repositories/address_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/repositories/stadium_services_repository.dart';
import '../../data/repositories/entity_images_repository.dart';
import '../../data/models/stadium_model.dart';
import '../../data/models/address_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/stadium_services_model.dart';
import 'stadium_profile_event.dart';
import 'stadium_profile_state.dart';
import 'dart:async';
import 'package:uuid/uuid.dart'; // Import UUID package

class StadiumProfileBloc
    extends Bloc<StadiumProfileEvent, StadiumProfileState> {
  final StadiumRepository _stadiumRepository;
  final AddressRepository _addressRepository;
  final ServiceRepository _serviceRepository;
  final StadiumServicesRepository _stadiumServicesRepository;
  final EntityImagesRepository _entityImagesRepository;

  // Debounce for search
  Timer? _debounce;

  StadiumProfileBloc({
    required StadiumRepository stadiumRepository,
    required AddressRepository addressRepository,
    required ServiceRepository serviceRepository,
    required StadiumServicesRepository stadiumServicesRepository,
    EntityImagesRepository? entityImagesRepository,
  })  : _stadiumRepository = stadiumRepository,
        _addressRepository = addressRepository,
        _serviceRepository = serviceRepository,
        _stadiumServicesRepository = stadiumServicesRepository,
        _entityImagesRepository =
            entityImagesRepository ?? EntityImagesRepository(),
        super(const StadiumProfileState()) {
    on<LoadStadiumProfile>(_onLoadStadiumProfile);
    on<RefreshStadiumProfile>(_onRefreshStadiumProfile);
    on<UpdateStadiumProfile>(_onUpdateStadiumProfile);
    on<UpdateStadiumAddress>(_onUpdateStadiumAddress);
    on<UpdateStadiumProfileImage>(_onUpdateStadiumProfileImage);
    on<SearchServices>(_onSearchServices);
    on<PerformSearchAction>(_onPerformSearch);
    on<AddStadiumService>(_onAddStadiumService);
    on<RemoveStadiumService>(_onRemoveStadiumService);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> _onLoadStadiumProfile(
    LoadStadiumProfile event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print(
        "DEBUG: StadiumProfileBloc._onLoadStadiumProfile called with stadiumId: ${event.stadiumId}");
    emit(state.copyWith(status: StadiumProfileStatus.loading));

    try {
      if (event.stadiumId == null) {
        throw Exception('Stadium ID cannot be null');
      }

      // Use the new method that fetches only basic stadium data
      final stadium =
          await _stadiumRepository.getBasicStadiumById(event.stadiumId!);

      if (stadium == null) {
        throw Exception('Stadium not found');
      }

      // Get the address using addressId from the stadium
      final address = await _addressRepository.getById(stadium.addressId);

      // Get the stadium profile image
      final stadiumImages =
          await _entityImagesRepository.getImagesByEntityTypeAndId(
        'stadium',
        event.stadiumId!,
      );

      // Get the first image as profile image, if exists
      String? profileImageUrl;
      if (stadiumImages.isNotEmpty) {
        profileImageUrl = stadiumImages.first.imageUrl;
      }

      print("DEBUG: Basic stadium data loaded successfully: ${stadium.name}");

      emit(state.copyWith(
        status: StadiumProfileStatus.success,
        stadium: stadium,
        address: address,
        profileImageUrl: profileImageUrl,
        updateComplete: false,
      ));
    } catch (e) {
      print("DEBUG: Error in _onLoadStadiumProfile: $e");
      emit(state.copyWith(
        status: StadiumProfileStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshStadiumProfile(
    RefreshStadiumProfile event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print("DEBUG: StadiumProfileBloc._onRefreshStadiumProfile called");
    emit(state.copyWith(
      isRefreshing: true,
      // Maintain the current profileImageUrl while refreshing
      // profileImageUrl: null
    ));

    try {
      if (state.stadium == null) {
        throw Exception('No stadium data to refresh');
      }

      // Use the basic stadium data method for consistency
      final stadium =
          await _stadiumRepository.getBasicStadiumById(state.stadium!.id);

      if (stadium == null) {
        throw Exception('Stadium not found during refresh');
      }

      // Refresh the address
      final address = await _addressRepository.getById(stadium.addressId);

      // Refresh the stadium profile image - force refresh to get latest
      final stadiumImages =
          await _entityImagesRepository.getImagesByEntityTypeAndId(
        'stadium',
        stadium.id,
        forceRefresh: true, // Force a refresh of the images
      );

      print(
          "DEBUG: Found ${stadiumImages.length} images during refresh for stadium ${stadium.id}");

      // Get the first image as profile image, if exists
      String? profileImageUrl =
          state.profileImageUrl; // Keep existing if no new images found
      if (stadiumImages.isNotEmpty) {
        profileImageUrl = stadiumImages.first.imageUrl;
        print(
            "DEBUG: Refreshed profile image URL: ${profileImageUrl.substring(0, 30)}...");
      } else {
        print("DEBUG: No images found during refresh");

        // If no images found but we had one before, log a warning
        if (state.profileImageUrl != null &&
            state.profileImageUrl!.isNotEmpty) {
          print(
              "WARN: Previously had image but none found now: ${state.profileImageUrl!.substring(0, 30)}...");
        }

        // Try one more time to fetch images after a short delay
        await Future.delayed(const Duration(milliseconds: 200));
        final retryImages =
            await _entityImagesRepository.getImagesByEntityTypeAndId(
          'stadium',
          stadium.id,
        );
        if (retryImages.isNotEmpty) {
          profileImageUrl = retryImages.first.imageUrl;
          print(
              "DEBUG: Retry found image, URL: ${profileImageUrl.substring(0, 30)}...");
        }
      }

      emit(state.copyWith(
        status: StadiumProfileStatus.success,
        stadium: stadium,
        address: address,
        profileImageUrl: profileImageUrl,
        isRefreshing: false,
      ));
    } catch (e) {
      print("DEBUG: Error in _onRefreshStadiumProfile: $e");
      emit(state.copyWith(
        status: StadiumProfileStatus.failure,
        errorMessage: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  Future<void> _onUpdateStadiumProfileImage(
    UpdateStadiumProfileImage event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print("DEBUG: StadiumProfileBloc._onUpdateStadiumProfileImage called");
    emit(state.copyWith(isUploadingImage: true));

    try {
      // Upload the image to the repository
      final uploadedImage = await _entityImagesRepository.uploadImage(
        imageFile: event.imageFile,
        entityType: 'stadium',
        entityId: event.stadiumId,
      );

      print(
          "DEBUG: Stadium profile image uploaded successfully: ${uploadedImage.imageUrl}");

      // Check if this is a fallback/placeholder image (now using data URI)
      bool isFallbackImage = uploadedImage.imageUrl.startsWith('data:image');

      // Get all images after upload to ensure we have the latest
      final refreshedImages =
          await _entityImagesRepository.getImagesByEntityTypeAndId(
        'stadium',
        event.stadiumId,
        forceRefresh: true, // Force refresh to get updated images
      );

      String? profileImageUrl = uploadedImage.imageUrl;

      // If there are other images, use the first one (newest)
      if (refreshedImages.isNotEmpty) {
        profileImageUrl = refreshedImages.first.imageUrl;
        print("DEBUG: Using first image from refreshed list: $profileImageUrl");
      }

      // Even if there were DB permission issues, as long as we have the image URL, we can display it
      if (profileImageUrl.isNotEmpty) {
        emit(state.copyWith(
          profileImageUrl: profileImageUrl,
          isUploadingImage: false,
          status: StadiumProfileStatus.success,
          // If using a fallback image, add a note to the state
          errorMessage: isFallbackImage
              ? "Using placeholder image due to Supabase permissions. Enable authentication and configure RLS policies for production use."
              : null,
        ));
      } else {
        throw Exception("Failed to get valid image URL after upload");
      }
    } catch (e) {
      print("DEBUG: Error uploading stadium profile image: $e");

      // Display a more specific error message for RLS issues
      String errorMessage = "Failed to upload profile image";

      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('403') ||
          e.toString().contains('Unauthorized')) {
        errorMessage +=
            ": Permission denied. Please check Supabase RLS policies.";
      } else {
        errorMessage += ": $e";
      }

      emit(state.copyWith(
        status: StadiumProfileStatus.failure,
        errorMessage: errorMessage,
        isUploadingImage: false,
      ));
    }
  }

  Future<void> _onUpdateStadiumProfile(
    UpdateStadiumProfile event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print("DEBUG: StadiumProfileBloc._onUpdateStadiumProfile called");
    emit(state.copyWith(status: StadiumProfileStatus.loading));

    try {
      // Preserve existing images before update
      List<String> preservedImages = await _entityImagesRepository
          .preserveEntityImages('stadium', event.stadium.id);

      // Update stadium
      final updatedStadium = await _stadiumRepository.update(event.stadium);

      // Restore preserved images
      if (preservedImages.isNotEmpty) {
        await _entityImagesRepository.restoreEntityImages(
            'stadium', updatedStadium.id, preservedImages);
      }

      // Update address if provided
      Address? updatedAddress = state.address;
      if (event.address != null) {
        updatedAddress = await _addressRepository.update(event.address!);
      }

      print("DEBUG: Stadium data updated successfully: ${updatedStadium.name}");

      // Before completing, refresh the profile image to ensure it's up to date
      print("DEBUG: Refreshing profile image after update");
      final stadiumImages =
          await _entityImagesRepository.getImagesByEntityTypeAndId(
        'stadium',
        updatedStadium.id,
        forceRefresh: true,
      );

      // Get the first image as profile image, if exists
      String? profileImageUrl = state.profileImageUrl;
      if (stadiumImages.isNotEmpty) {
        profileImageUrl = stadiumImages.first.imageUrl;
        print(
            "DEBUG: Updated profile with refreshed image URL: ${profileImageUrl.substring(0, profileImageUrl.length > 30 ? 30 : profileImageUrl.length)}...");
      } else {
        print("DEBUG: No images found during profile update refresh");
      }

      emit(state.copyWith(
        stadium: updatedStadium,
        address: updatedAddress,
        profileImageUrl: profileImageUrl,
        status: StadiumProfileStatus.success,
        updateComplete: true,
      ));
    } catch (e) {
      print("DEBUG: Error in _onUpdateStadiumProfile: $e");
      emit(state.copyWith(
        status: StadiumProfileStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateStadiumAddress(
    UpdateStadiumAddress event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print("DEBUG: StadiumProfileBloc._onUpdateStadiumAddress called");
    emit(state.copyWith(status: StadiumProfileStatus.loading));

    try {
      // Update the address
      final updatedAddress = await _addressRepository.update(event.address);

      // If the stadium doesn't have an addressId yet, update it
      Stadium? updatedStadium = state.stadium;
      if (state.stadium != null &&
          (state.stadium!.addressId != updatedAddress.id)) {
        updatedStadium = state.stadium!.copyWith(
          addressId: updatedAddress.id,
        );
        await _stadiumRepository.update(updatedStadium);
      }

      print(
          "DEBUG: Address data updated successfully: ${updatedAddress.city}, ${updatedAddress.district}");
      print(
          "DEBUG: Coordinates: ${updatedAddress.latitude}, ${updatedAddress.longitude}");

      emit(state.copyWith(
        stadium: updatedStadium,
        address: updatedAddress,
        status: StadiumProfileStatus.success,
        // Don't set updateComplete to true here as we want the user to hit save
      ));
    } catch (e) {
      print("DEBUG: Error in _onUpdateStadiumAddress: $e");
      emit(state.copyWith(
        status: StadiumProfileStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSearchServices(
    SearchServices event,
    Emitter<StadiumProfileState> emit,
  ) {
    // Cancel any existing debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Save the search query immediately
    emit(state.copyWith(searchQuery: event.query, isSearching: true));

    // Use an event transformer or move the debounced logic to a separate registered event
    _debounce = Timer(const Duration(milliseconds: 300), () {
      add(PerformSearchAction(query: event.query));
    });
  }

  // Add a new event handler for the actual search
  Future<void> _onPerformSearch(
    PerformSearchAction event,
    Emitter<StadiumProfileState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }

    try {
      print("DEBUG: Performing search for query: '${event.query}'");

      // Search for services that match the query
      final services = await _serviceRepository.getAllServices();
      print("DEBUG: Retrieved ${services.length} services from repository");

      if (services.isEmpty) {
        print("DEBUG: No services found in repository");
        emit(state.copyWith(searchResults: [], isSearching: false));
        return;
      }

      // Print first few services for debugging
      if (services.isNotEmpty) {
        print(
            "DEBUG: Example service: ID=${services[0].id}, English=${services[0].englishName}, Arabic=${services[0].arabicName}");
      }

      // Filter services based on the query (case-insensitive)
      final String lowercaseQuery = event.query.toLowerCase().trim();
      print("DEBUG: Searching with lowercase query: '$lowercaseQuery'");

      final filteredServices = services.where((service) {
        final englishNameMatch =
            service.englishName.toLowerCase().contains(lowercaseQuery);
        final arabicNameMatch =
            service.arabicName.toLowerCase().contains(lowercaseQuery);

        if (englishNameMatch || arabicNameMatch) {
          print(
              "DEBUG: Found matching service: ${service.englishName} / ${service.arabicName}");
        }

        return englishNameMatch || arabicNameMatch;
      }).toList();

      print("DEBUG: Search found ${filteredServices.length} matching services");

      emit(state.copyWith(
        searchResults: filteredServices,
        isSearching: false,
      ));
    } catch (e) {
      print("DEBUG: Error searching services: $e");
      emit(state.copyWith(isSearching: false));
    }
  }

  Future<void> _onAddStadiumService(
    AddStadiumService event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print(
        "DEBUG: _onAddStadiumService called with stadiumId: ${event.stadiumId}, serviceId: ${event.serviceId}");

    try {
      // Create a proper UUID for the stadium-service relation
      final uuid = Uuid();
      final id = uuid.v4(); // Generate a valid UUID v4
      print("DEBUG: Generated UUID for stadium service: $id");

      // Create the stadium service model
      final stadiumService = StadiumServicesModel(
        id: id, // Use the UUID
        stadiumId: event.stadiumId,
        serviceId: event.serviceId,
        createdAt: DateTime.now().toIso8601String(),
      );

      print("DEBUG: Creating stadium service with UUID: $id");

      // Add the service to the stadium
      await _stadiumServicesRepository.createStadiumService(stadiumService);
      print("DEBUG: Successfully created stadium service in repository");

      // Find the service from searchResults or get it from repository
      Service? serviceToAdd;

      // First try to find in search results
      try {
        serviceToAdd = state.searchResults.firstWhere(
          (service) => service.id == event.serviceId,
        );
        print(
            "DEBUG: Found service in search results: ${serviceToAdd.englishName}");
      } catch (e) {
        print(
            "DEBUG: Service not found in search results, fetching from repository");
        // If not found in search results, fetch from repository
        serviceToAdd = await _serviceRepository.getServiceById(event.serviceId);
        print(
            "DEBUG: Fetched service from repository: ${serviceToAdd.englishName}");
      }

      // Add the service to the stadium's services list
      if (state.stadium != null) {
        print("DEBUG: Updating stadium with new service");
        // First check if service is already in the list to avoid duplicates
        final existingServiceIndex =
            state.stadium!.services.indexWhere((s) => s.id == serviceToAdd!.id);

        List<Service> updatedServices;

        if (existingServiceIndex >= 0) {
          print(
              "DEBUG: Service already exists in stadium, not adding duplicate");
          updatedServices = List.from(state.stadium!.services);
        } else {
          print("DEBUG: Adding new service to stadium's service list");
          updatedServices = [...state.stadium!.services, serviceToAdd];
        }

        final updatedStadium =
            state.stadium!.copyWith(services: updatedServices);

        emit(state.copyWith(
          stadium: updatedStadium,
          searchResults: [], // Clear search results
          searchQuery: '', // Clear search query
        ));

        print(
            "DEBUG: Stadium services updated, now has ${updatedServices.length} services");
      } else {
        print(
            "DEBUG: Could not update stadium with service: stadium=${state.stadium != null}, serviceToAdd=${serviceToAdd != null}");
      }
    } catch (e) {
      print("DEBUG: Error adding service to stadium: $e");
      // Show error state when service addition fails
      emit(state.copyWith(
        errorMessage: "Failed to add service: $e",
        status: StadiumProfileStatus.failure,
      ));

      // Reset back to success state after a moment, so user can try again
      Future.delayed(Duration(seconds: 2), () {
        if (!isClosed) {
          emit(state.copyWith(
            status: StadiumProfileStatus.success,
            errorMessage: null,
          ));
        }
      });
    }
  }

  Future<void> _onRemoveStadiumService(
    RemoveStadiumService event,
    Emitter<StadiumProfileState> emit,
  ) async {
    print(
        "DEBUG: _onRemoveStadiumService called with stadiumId: ${event.stadiumId}, serviceId: ${event.serviceId}");

    try {
      // Remove the service from the stadium in the repository
      await _stadiumServicesRepository.deleteStadiumServiceByStadiumAndService(
        event.stadiumId,
        event.serviceId,
      );
      print(
          "DEBUG: Successfully deleted stadium-service relationship from repository");

      // Remove the service from the stadium's services list in state
      if (state.stadium != null) {
        final prevCount = state.stadium!.services.length;
        final List<Service> updatedServices = state.stadium!.services
            .where((service) => service.id != event.serviceId)
            .toList();
        final updatedStadium =
            state.stadium!.copyWith(services: updatedServices);

        print(
            "DEBUG: Removed service from stadium's service list. Before: $prevCount, After: ${updatedServices.length}");

        emit(state.copyWith(
          stadium: updatedStadium,
          status: StadiumProfileStatus.success,
        ));
      } else {
        print("DEBUG: Stadium is null, cannot update services list");
      }
    } catch (e) {
      print("DEBUG: Error removing service from stadium: $e");

      // Show error state when service removal fails
      emit(state.copyWith(
        errorMessage: "Failed to remove service: $e",
        status: StadiumProfileStatus.failure,
      ));

      // Reset back to success state after a moment, so user can try again
      Future.delayed(Duration(seconds: 2), () {
        if (!isClosed) {
          emit(state.copyWith(
            status: StadiumProfileStatus.success,
            errorMessage: null,
          ));
        }
      });
    }
  }
}
