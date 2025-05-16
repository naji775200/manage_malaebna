import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/stadium_profile/stadium_profile_bloc.dart';
import '../../../logic/stadium_profile/stadium_profile_event.dart';
import '../../../logic/stadium_profile/stadium_profile_state.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/repositories/stadium_repository.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../data/repositories/stadium_services_repository.dart';
import '../../../data/repositories/entity_images_repository.dart';
import '../../../data/models/address_model.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../presentation/screens/map/map_screen.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileStadiumScreen extends StatefulWidget {
  const EditProfileStadiumScreen({super.key});

  @override
  State<EditProfileStadiumScreen> createState() =>
      _EditProfileStadiumScreenState();
}

class _EditProfileStadiumScreenState extends State<EditProfileStadiumScreen> {
  String? stadiumId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStadiumId();
  }

  Future<void> _loadStadiumId() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Try to get stadium ID from AuthUtils
      final id = await AuthUtils.getStadiumIdFromAuth();

      if (id == null) {
        print("❌ ERROR: No stadium ID retrieved from AuthUtils");

        // Show an error dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("No stadium ID found. Using fallback for development."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // For debugging: Use a fallback test ID
        setState(() {
          stadiumId = "stadium_1"; // Default fallback ID
          isLoading = false;
        });
      } else {
        print("✅ Successfully retrieved Stadium ID: $id");

        // Successfully got the ID
        setState(() {
          stadiumId = id;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ ERROR loading stadium ID: $e");

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading stadium data: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Set fallback for development
      setState(() {
        stadiumId = "stadium_1"; // Default fallback ID
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // This should never happen now with fallback ID, but keep as safety
    if (stadiumId == null || stadiumId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Stadium Profile"),
        ),
        body: const Center(
          child: Text("Could not find stadium information. Please try again."),
        ),
      );
    }

    print("Building EditProfileStadiumScreen with stadiumId: $stadiumId");

    // Create the BlocProvider at the root of the widget tree
    return BlocProvider(
      create: (context) {
        print("Creating StadiumProfileBloc with stadiumId: $stadiumId");

        return StadiumProfileBloc(
          stadiumRepository: context.read<StadiumRepository>(),
          addressRepository: context.read<AddressRepository>(),
          serviceRepository: context.read<ServiceRepository>(),
          stadiumServicesRepository: context.read<StadiumServicesRepository>(),
          entityImagesRepository: context.read<EntityImagesRepository>(),
        )..add(LoadStadiumProfile(stadiumId: stadiumId));
      },
      child: const StadiumEditView(),
    );
  }
}

class StadiumEditView extends StatefulWidget {
  const StadiumEditView({super.key});

  @override
  State<StadiumEditView> createState() => _StadiumEditViewState();
}

class _StadiumEditViewState extends State<StadiumEditView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool _controllersInitialized = false;
  bool showSearchResults = false;

  // Track image management
  final ImagePicker _imagePicker = ImagePicker();
  late ImageUploadHelper _imageUploadHelper;
  List<String> _stadiumImageUrls = [];
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();

    // Initialize image upload helper
    _imageUploadHelper = ImageUploadHelper(
      context: context,
      translationService: translationService,
    );

    // Listen for search changes
    searchController.addListener(() {
      if (searchController.text.isNotEmpty && !showSearchResults) {
        setState(() {
          showSearchResults = true;
        });
      }
      // Dispatch search event when text changes
      if (searchController.text.isNotEmpty) {
        // Dispatch event to search services
        context
            .read<StadiumProfileBloc>()
            .add(SearchServices(query: searchController.text));
      }
    });
  }

  // Method to load stadium profile image
  Future<void> _loadStadiumImages() async {
    final stadiumState = context.read<StadiumProfileBloc>().state;
    final stadiumId = stadiumState.stadium?.id;

    if (stadiumId == null) {
      print('Cannot load image: Stadium ID is null');
      return;
    }

    setState(() {
      _isLoadingImages = true;
    });

    try {
      print('Loading images for stadium ID: $stadiumId');
      final images = await _imageUploadHelper.getEntityImages(
        entityType: 'stadium',
        entityId: stadiumId,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          // Just save the URLs, we'll use the first one as the profile image
          _stadiumImageUrls = images.map((img) => img.imageUrl).toList();
          _isLoadingImages = false;
        });
        print('Loaded ${_stadiumImageUrls.length} images for stadium');
      }
    } catch (e) {
      print('Error loading stadium image: $e');
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  // Method to pick and process a profile image
  Future<void> _pickProfileImage(BuildContext context) async {
    final stadiumState = context.read<StadiumProfileBloc>().state;
    final stadiumId = stadiumState.stadium?.id;

    if (stadiumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translationService.translate(
                  'stadium_profile.stadium_id_missing', {}, context) ??
              'Stadium ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Picking image for stadium ID: $stadiumId');

      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      // Set loading state
      setState(() {
        _isLoadingImages = true;
      });

      // Create a file from the picked image
      final File imageFile = File(pickedFile.path);

      // Upload image with replaceExisting set to true to replace any existing images
      final uploadedImage = await _imageUploadHelper.uploadSingleImage(
        entityType: 'stadium',
        entityId: stadiumId,
        replaceExisting: true, // Important: Replace existing images
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (uploadedImage != null) {
        print('Successfully uploaded image with ID: ${uploadedImage.id}');
        // Update local state with the new image
        setState(() {
          _stadiumImageUrls = [uploadedImage.imageUrl];
          _isLoadingImages = false;
        });

        // We don't actually need to dispatch the UpdateStadiumProfileImage event
        // as we've already updated the image through the repository
        // This eliminates the need to pass the File object to the bloc
      } else {
        print('Image upload cancelled or failed with null result');
        setState(() {
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      print('Error picking/uploading profile image: $e');
      setState(() {
        _isLoadingImages = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translationService.translate(
                    'stadium_profile.image_upload_error', {}, context) ??
                'Error uploading image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    districtController.dispose();
    cityController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StadiumProfileBloc, StadiumProfileState>(
      listener: (context, state) {
        print("StadiumProfileBloc state changed to: ${state.status}");

        if (state.isSuccess &&
            state.stadium != null &&
            !_controllersInitialized) {
          print(
              "Initializing controllers with stadium data: ${state.stadium?.name}");
          _initializeControllers(state);

          // Load the images after the stadium data is loaded
          _loadStadiumImages();
        }

        // Only show success message and pop if we are in a loading state followed by success state
        // This indicates an update operation completed, not just initial data loading
        if (state.isSuccess && state.updateComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(translationService.translate(
                      'stadium_profile.update_success', {}, context) ??
                  'Stadium profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Add a slight delay before popping to ensure the snackbar is visible
          Future.delayed(const Duration(milliseconds: 1500), () {
            Navigator.of(context).pop();
          });
        } else if (state.isError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ??
                  translationService.translate('common.error', {}, context) ??
                  'Error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(translationService.translate(
                    'stadium_profile.edit_profile', {}, context) ??
                'Edit Stadium Profile'),
            elevation: 0,
          ),
          body: state.isInitial || state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(context, state),
          bottomNavigationBar: _buildBottomBar(context, state),
        );
      },
    );
  }

  void _initializeControllers(StadiumProfileState state) {
    // Stadium data
    nameController.text = state.stadium?.name ?? '';
    descriptionController.text = state.stadium?.description ?? '';
    phoneController.text = state.stadium?.phoneNumber ?? '';

    // Address data
    if (state.address != null) {
      districtController.text = state.address?.district ?? '';
      cityController.text = state.address?.city ?? '';
    }

    setState(() {
      _controllersInitialized = true;
    });
  }

  Widget _buildForm(BuildContext context, StadiumProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stadium avatar
            _buildAvatarSection(context, state),

            const SizedBox(height: 24),

            // Basic Information Section
            _buildSectionHeader(
                context,
                translationService.translate(
                        'stadium_profile.basic_info', {}, context) ??
                    'Basic Information'),

            // Stadium name field
            _buildTextField(
              context,
              controller: nameController,
              label: translationService.translate(
                      'stadium_profile.name', {}, context) ??
                  'Stadium Name',
              prefixIcon: Icons.stadium,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return translationService.translate(
                          'validation.field_required', {}, context) ??
                      'Stadium name is required';
                }
                if (value.trim().length < 3) {
                  return translationService.translate(
                          'validation.name_short', {}, context) ??
                      'Stadium name is too short';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description field
            _buildTextField(
              context,
              controller: descriptionController,
              label: translationService.translate(
                      'stadium_profile.description', {}, context) ??
                  'Description',
              prefixIcon: Icons.description,
              maxLines: 3,
              helperText: translationService.translate(
                      'stadium_profile.description_hint', {}, context) ??
                  'Provide a detailed description of your stadium',
            ),

            const SizedBox(height: 16),

            // Phone number field
            _buildTextField(
              context,
              controller: phoneController,
              label: translationService.translate(
                      'stadium_profile.phone', {}, context) ??
                  'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              helperText: translationService.translate(
                      'stadium_profile.phone_format', {}, context) ??
                  'e.g. +966 xxxxxxxxx',
              onChanged: (value) {
                // Add "+" prefix if not already present and there's text
                if (value.isNotEmpty && !value.startsWith('+')) {
                  phoneController.text = '+$value';
                  // Set selection to end of text
                  phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: phoneController.text.length),
                  );
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return translationService.translate(
                          'validation.field_required', {}, context) ??
                      'Phone number is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader(
                context,
                translationService.translate(
                        'stadium_profile.location', {}, context) ??
                    'Location'),

            // District field
            _buildTextField(
              context,
              controller: districtController,
              label: translationService.translate(
                      'stadium_profile.district', {}, context) ??
                  'District',
              prefixIcon: Icons.location_on,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return translationService.translate(
                          'validation.field_required', {}, context) ??
                      'District is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // City field
            _buildTextField(
              context,
              controller: cityController,
              label: translationService.translate(
                      'stadium_profile.city', {}, context) ??
                  'City',
              prefixIcon: Icons.location_city,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return translationService.translate(
                          'validation.field_required', {}, context) ??
                      'City is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Display current coordinates if available
            if (state.address != null &&
                state.address!.latitude != 0 &&
                state.address!.longitude != 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${translationService.translate('stadium_profile.current_coordinates', {}, context) ?? 'Current Coordinates'}: ${state.address!.latitude.toStringAsFixed(6)}, ${state.address!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ),

            // Map location button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Navigate to map screen to select location
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(
                          returnLocation: true,
                        ),
                      ),
                    );

                    // Handle result from map screen
                    if (result != null && mounted) {
                      final location = result['location'];
                      final country = result['country'] as String?;
                      final city = result['city'] as String?;
                      final district = result['district'] as String?;

                      // Update text fields
                      setState(() {
                        if (city != null && city.isNotEmpty) {
                          cityController.text = city;
                        }
                        if (district != null && district.isNotEmpty) {
                          districtController.text = district;
                        }
                      });

                      // Store coordinates in bloc state
                      if (location != null) {
                        final double latitude = location.latitude;
                        final double longitude = location.longitude;

                        context.read<StadiumProfileBloc>().add(
                              UpdateStadiumAddress(
                                address: state.address?.copyWith(
                                      latitude: latitude,
                                      longitude: longitude,
                                    ) ??
                                    Address(
                                      id: 'address_${DateTime.now().millisecondsSinceEpoch}',
                                      latitude: latitude,
                                      longitude: longitude,
                                      city: city,
                                      district: district,
                                      country: country,
                                    ),
                              ),
                            );
                      }

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(translationService.translate(
                                  'stadium_profile.location_updated',
                                  {},
                                  context) ??
                              'Location updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error selecting location: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translationService.translate(
                                'stadium_profile.location_error',
                                {},
                                context) ??
                            'Error updating location'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map),
                label: Text(translationService.translate(
                        'stadium_profile.select_on_map', {}, context) ??
                    'Select on Map'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Services Section
            _buildServicesSection(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, StadiumProfileState state) {
    // Get the first image URL if available, otherwise use null
    String? profileImageUrl =
        _stadiumImageUrls.isNotEmpty ? _stadiumImageUrls.first : null;
    final bool hasImage = profileImageUrl != null;

    return Column(
      children: [
        // Circular avatar with camera icon overlay
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Profile image
              GestureDetector(
                onTap: state.isUploadingImage
                    ? null
                    : () => _pickProfileImage(context),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    image: hasImage ? _getDecorationImage(profileImageUrl) : null,
                  ),
                  child: !hasImage
                      ? Icon(
                          Icons.stadium,
                          size: 60,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
              ),

              // Camera icon overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: state.isUploadingImage
                      ? null
                      : () => _pickProfileImage(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Loading indicator when uploading
              if (_isLoadingImages)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get the appropriate DecorationImage based on the URL type
  DecorationImage? _getDecorationImage(String? imageUrl) {
    if (imageUrl == null) {
      return null;
    }

    if (imageUrl.startsWith('data:image')) {
      // Handle data URIs
      // Extract the base64 data from the data URI
      final dataIndex = imageUrl.indexOf(',') + 1;
      if (dataIndex > 0 && dataIndex < imageUrl.length) {
        final base64Data = imageUrl.substring(dataIndex);
        try {
          return DecorationImage(
            image: MemoryImage(base64Decode(base64Data)),
            fit: BoxFit.cover,
          );
        } catch (e) {
          print('Error decoding base64 image: $e');
          return null;
        }
      }
      return null;
    } else {
      // Regular network image for http/https URLs
      return DecorationImage(
        image: NetworkImage(imageUrl),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildServicesSection(
      BuildContext context, StadiumProfileState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context,
            translationService.translate(
                    'stadium_profile.services', {}, context) ??
                'Services'),

        // Search field
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: translationService.translate(
                      'stadium_profile.search_services', {}, context) ??
                  'Search services...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          showSearchResults = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 16,
              ),
            ),
          ),
        ),

        // Search results
        if (showSearchResults) _buildSearchResults(context, state),

        // Selected services display
        _buildSelectedServices(context, state),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context, StadiumProfileState state) {
    // Get current locale from the app
    final currentLocale = Localizations.localeOf(context).languageCode;

    if (state.isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!state.hasSearchResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            translationService.translate(
                    'stadium_profile.no_search_results', {}, context) ??
                'No services found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    // Show search results in a card
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.searchResults.length,
        itemBuilder: (context, index) {
          final service = state.searchResults[index];
          final serviceName = service.getLocalizedName(currentLocale);

          // Check if service is already selected
          final isAlreadySelected =
              state.stadium?.services.any((s) => s.id == service.id) ?? false;

          return ListTile(
            leading: Icon(
              _getIconData(service.iconName),
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(serviceName),
            trailing: isAlreadySelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      if (state.stadium != null) {
                        print(
                            "Add button pressed for service: ${service.id} - $serviceName");
                        context.read<StadiumProfileBloc>().add(
                              AddStadiumService(
                                stadiumId: state.stadium!.id,
                                serviceId: service.id,
                              ),
                            );
                        // Clear search
                        searchController.clear();
                      }
                    },
                  ),
            onTap: () {
              if (!isAlreadySelected && state.stadium != null) {
                print(
                    "ListTile tapped for service: ${service.id} - $serviceName");
                context.read<StadiumProfileBloc>().add(
                      AddStadiumService(
                        stadiumId: state.stadium!.id,
                        serviceId: service.id,
                      ),
                    );
                // Clear search
                searchController.clear();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedServices(
      BuildContext context, StadiumProfileState state) {
    // Get current locale from the app
    final currentLocale = Localizations.localeOf(context).languageCode;

    print(
        "DEBUG: Building selected services, stadium has services: ${state.stadium?.services.length ?? 0}");
    if (state.stadium != null && state.stadium!.services.isNotEmpty) {
      print(
          "DEBUG: Services to display: ${state.stadium!.services.map((s) => '${s.id}:${s.englishName}').join(', ')}");
    }

    if (state.stadium == null || state.stadium!.services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            translationService.translate(
                    'stadium_profile.no_services_selected', {}, context) ??
                'No services selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              translationService.translate(
                      'stadium_profile.selected_services', {}, context) ??
                  'Selected Services',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: state.stadium!.services.map((service) {
              final serviceName = service.getLocalizedName(currentLocale);

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (service.iconName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(
                          _getIconData(service.iconName),
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        serviceName,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        print(
                            "DEBUG: Removing service: ${service.id} - $serviceName");
                        context.read<StadiumProfileBloc>().add(
                              RemoveStadiumService(
                                stadiumId: state.stadium!.id,
                                serviceId: service.id,
                              ),
                            );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helperText,
    TextDirection? textDirection,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        helperText: helperText,
        contentPadding: EdgeInsets.symmetric(
          vertical: maxLines > 1 ? 16.0 : 0.0,
          horizontal: 16.0,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      textDirection: textDirection,
      textAlign:
          textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
    );
  }

  Widget _buildBottomBar(BuildContext context, StadiumProfileState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(translationService.translate(
                        'common.cancel', {}, context) ??
                    'Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // Update stadium profile
                          context
                              .read<StadiumProfileBloc>()
                              .add(UpdateStadiumProfile(
                                stadium: state.stadium!.copyWith(
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  phoneNumber: phoneController.text,
                                  // Keep existing services from state
                                  services: state.stadium!.services,
                                ),
                                address: state.address?.copyWith(
                                  district: districtController.text,
                                  city: cityController.text,
                                ),
                              ));
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  translationService.translate('common.save', {}, context) ??
                      'Save',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to convert icon_name string to IconData
  IconData _getIconData(String iconName) {
    // Map icon names to IconData
    switch (iconName) {
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'shower':
        return Icons.shower;
      case 'restaurant':
        return Icons.restaurant;
      case 'water':
        return Icons.water_drop;
      case 'locker':
        return Icons.lock;
      case 'restroom':
        return Icons.wc;
      case 'accessibility':
        return Icons.accessible;
      case 'sports_shop':
        return Icons.shopping_bag;
      case 'equipment_rental':
        return Icons.sports_soccer;
      default:
        return Icons.sports; // Default icon for unknown service types
    }
  }
}
