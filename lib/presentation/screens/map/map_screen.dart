import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

import '../../../core/constants/theme.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/repositories/map_repository.dart';
import '../../../logic/map/map_bloc.dart';
import '../../../logic/map/map_event.dart';
import '../../../logic/map/map_state.dart';
import '../../../logic/theme/theme_bloc.dart';
import '../../../logic/localization_bloc.dart';

// Define stub widgets/classes for missing dependencies
class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFullWidth = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: isFullWidth ? Size(double.infinity, 48) : null,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  final bool returnLocation;
  final dynamic initialLocation; // Changed to dynamic to handle different types
  final Locale? locale; // Add locale parameter

  const MapScreen({
    super.key,
    this.returnLocation = true,
    this.initialLocation,
    this.locale, // Pass locale to map screen
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapBloc(
        mapRepository: MapRepository(),
      )..add(
          InitializeMap(
            requestCurrentLocation: initialLocation == null,
            initialLocation: initialLocation is LatLng ? initialLocation : null,
          ),
        ),
      child: _MapScreenContent(
        returnLocation: returnLocation,
        locale: locale, // Pass locale to content widget
      ),
    );
  }
}

class _MapScreenContent extends StatefulWidget {
  final bool returnLocation;
  final Locale? locale;

  const _MapScreenContent({
    required this.returnLocation,
    this.locale,
  });

  @override
  State<_MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<_MapScreenContent>
    with SingleTickerProviderStateMixin {
  google_maps.GoogleMapController? _mapController;
  final Set<google_maps.Marker> _markers = {};
  final String _markerId = 'selected_location';
  bool _showConfirmation = false;
  google_maps.LatLng? _markerPosition;

  // Animation controller for the confirmation panel
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Map style strings
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
''';

  static const String _arabicLanguageStyle = '''
[
  {
    "elementType": "labels",
    "stylers": [
      {
        "language": "ar"
      }
    ]
  }
]
''';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listenWhen: (previous, current) {
        // Only trigger listener for meaningful state changes
        if (previous.selectedLocation != null &&
            current.selectedLocation != null &&
            previous.selectedLocation!.latitude ==
                current.selectedLocation!.latitude &&
            previous.selectedLocation!.longitude ==
                current.selectedLocation!.longitude) {
          return false;
        }
        return true;
      },
      listener: (context, state) {
        // Handle various map states
        if (state.status == MapStatus.permissionDenied) {
          _showPermissionDeniedDialog(context);
        } else if (state.status == MapStatus.serviceDisabled) {
          _showLocationServiceDisabledDialog(context);
        } else if (state.status == MapStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        } else if (state.status == MapStatus.success &&
            state.selectedLocation != null) {
          // Update the marker and center the map
          _updateMarker(state.selectedLocation!);
          _centerMapOnLocation(state.selectedLocation!);

          // Store marker position for reference
          _markerPosition = google_maps.LatLng(state.selectedLocation!.latitude,
              state.selectedLocation!.longitude);

          // Show the confirmation with animation
          if (!_showConfirmation) {
            setState(() {
              _showConfirmation = true;
            });
            _animationController.forward();
          }
        }
      },
      builder: (context, state) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(translationService.translate(
                    'map.select_location', {}, context)),
                elevation: 0,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {
                      _showHelpDialog(context);
                    },
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // Google Map with theme awareness
                  _buildGoogleMap(context, state, themeState),

                  // Loading indicator
                  if (state.status == MapStatus.loading)
                    const Center(child: CustomProgressIndicator()),

                  // Tap instruction overlay
                  if (!_showConfirmation)
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            translationService.translate(
                                'map.tap_to_select', {}, context),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                  // Confirmation container - fixed position at the top third of the screen
                  if (_showConfirmation && state.selectedLocation != null)
                    _buildFixedConfirmationContainer(context, state),

                  // Map control buttons
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // My Location Button
                        FloatingActionButton(
                          backgroundColor: AppTheme.primaryColor,
                          onPressed: () {
                            context.read<MapBloc>().add(GetCurrentLocation());
                          },
                          mini: false,
                          heroTag: 'locationButton',
                          child: const Icon(Icons.my_location,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        // Zoom in button
                        FloatingActionButton(
                          backgroundColor: Colors.white,
                          mini: true,
                          heroTag: 'zoomInButton',
                          child: Icon(Icons.add, color: AppTheme.primaryColor),
                          onPressed: () {
                            _mapController?.animateCamera(
                                google_maps.CameraUpdate.zoomIn());
                          },
                        ),
                        const SizedBox(height: 8),
                        // Zoom out button
                        FloatingActionButton(
                          backgroundColor: Colors.white,
                          mini: true,
                          heroTag: 'zoomOutButton',
                          child:
                              Icon(Icons.remove, color: AppTheme.primaryColor),
                          onPressed: () {
                            _mapController?.animateCamera(
                                google_maps.CameraUpdate.zoomOut());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoogleMap(
      BuildContext context, MapState state, ThemeState themeState) {
    // Default to a location in Saudi Arabia if no location is provided
    final initialPosition = state.selectedLocation != null
        ? google_maps.LatLng(
            state.selectedLocation!.latitude, state.selectedLocation!.longitude)
        : const google_maps.LatLng(24.774265, 46.738586); // Default to Riyadh

    // Initialize markers if there's a selected location and markers are empty
    if (state.selectedLocation != null && _markers.isEmpty) {
      _updateMarker(state.selectedLocation!);
      _markerPosition = google_maps.LatLng(
          state.selectedLocation!.latitude, state.selectedLocation!.longitude);
    }

    // Get current locale
    final currentLocale = widget.locale ?? Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return google_maps.GoogleMap(
      initialCameraPosition: google_maps.CameraPosition(
        target: initialPosition,
        zoom: 15.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      mapType: google_maps.MapType.normal,
      onMapCreated: (controller) async {
        _mapController = controller;

        // Determine if dark mode is enabled
        final isDarkMode = themeState.themeMode == ThemeMode.dark ||
            (themeState.themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        try {
          // Apply appropriate map style based on theme
          if (isDarkMode) {
            await controller.setMapStyle(_darkMapStyle);
          } else {
            await controller.setMapStyle('[]'); // Empty style for light theme
          }

          // Apply language setting after theme style
          if (isArabic) {
            // Note: We're not combining the styles to avoid JSON parsing issues
            if (!isDarkMode) {
              // Only set Arabic for light theme; for dark, it's too complex to merge styles
              await controller.setMapStyle(_arabicLanguageStyle);
            }
          }
        } catch (e) {
          debugPrint('Error setting map style: $e');
        }

        setState(() {});
      },
      onTap: (google_maps.LatLng position) {
        // Convert Google Maps LatLng to our custom LatLng
        final customLatLng = LatLng(position.latitude, position.longitude);

        // If confirmation is showing, hide it first with animation
        if (_showConfirmation) {
          _animationController.reverse().then((_) {
            setState(() {
              _showConfirmation = false;
            });

            // After hiding animation completes, select the new location
            context
                .read<MapBloc>()
                .add(LocationSelected(location: customLatLng));
          });
        } else {
          // Select location directly
          context.read<MapBloc>().add(LocationSelected(location: customLatLng));
        }
      },
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed width container for icon to ensure alignment
          SizedBox(
            width: 24,
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          // Fixed width container for labels to ensure alignment
          SizedBox(
            width: 65,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? translationService.translate('map.unknown', {}, context),
              style: TextStyle(
                fontSize: 13,
                color: value == null ? Colors.grey : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedConfirmationContainer(
      BuildContext context, MapState state) {
    // Use a fixed position in the top part of the screen
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15, // 15% from the top
      left: MediaQuery.of(context).size.width * 0.12, // Increased left padding
      right:
          MediaQuery.of(context).size.width * 0.12, // Increased right padding
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Opacity(
              opacity: _animation.value,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12), // Reduced vertical padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  translationService.translate(
                                      'map.confirm_location', {}, context),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _animationController.reverse().then((_) {
                                setState(() {
                                  _showConfirmation = false;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      const SizedBox(height: 4),
                      if (state.isLoadingAddress)
                        const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAddressRow(
                                Icons.public,
                                translationService.translate(
                                    'map.country', {}, context),
                                state.country),
                            _buildAddressRow(
                                Icons.location_city,
                                translationService.translate(
                                    'map.city', {}, context),
                                state.city),
                            _buildAddressRow(
                                Icons.grid_4x4,
                                translationService.translate(
                                    'map.district', {}, context),
                                state.district),
                            if (state.selectedLocation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 24), // Icon width
                                    Expanded(
                                      child: Text(
                                        '${translationService.translate('map.coordinates', {}, context)}: ${state.selectedLocation!.latitude.toStringAsFixed(6)}, ${state.selectedLocation!.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontSize: 9, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: translationService.translate(
                            'map.confirm', {}, context),
                        isFullWidth: true,
                        color: AppTheme.primaryColor,
                        onPressed: state.selectedLocation == null
                            ? null
                            : () {
                                if (widget.returnLocation) {
                                  Navigator.of(context).pop({
                                    'location': state.selectedLocation,
                                    'country': state.country,
                                    'city': state.city,
                                    'district': state.district,
                                  });
                                } else {
                                  context.read<MapBloc>().add(
                                        ConfirmLocation(
                                          location: state.selectedLocation!,
                                          country: state.country,
                                          city: state.city,
                                          district: state.district,
                                        ),
                                      );
                                  _animationController.reverse().then((_) {
                                    setState(() {
                                      _showConfirmation = false;
                                    });
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateMarker(LatLng location) {
    final googleMapsLatLng =
        google_maps.LatLng(location.latitude, location.longitude);

    setState(() {
      _markers.clear();
      _markers.add(
        google_maps.Marker(
          markerId: google_maps.MarkerId(_markerId),
          position: googleMapsLatLng,
          icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(
              google_maps.BitmapDescriptor.hueGreen),
          infoWindow: google_maps.InfoWindow(
              title: translationService.translate(
                  'map.selected_location', {}, context)),
          draggable: false,
          zIndex: 2,
        ),
      );
    });
  }

  void _centerMapOnLocation(LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        google_maps.CameraUpdate.newLatLngZoom(
          google_maps.LatLng(location.latitude, location.longitude),
          15.0,
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(translationService.translate('map.help_title', {}, context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '• ${translationService.translate('map.help_tap', {}, context)}'),
            const SizedBox(height: 8),
            Text(
                '• ${translationService.translate('map.help_gps', {}, context)}'),
            const SizedBox(height: 8),
            Text(
                '• ${translationService.translate('map.help_zoom', {}, context)}'),
            const SizedBox(height: 8),
            Text(
                '• ${translationService.translate('map.help_confirm', {}, context)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
                translationService.translate('common.got_it', {}, context)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    // Store a reference to the MapBloc before showing the dialog
    final mapBloc = context.read<MapBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            translationService.translate('map.permission_title', {}, context)),
        content: Text(
          translationService.translate('map.permission_denied', {}, context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              mapBloc.add(RequestLocationPermission());
            },
            child: Text(
                translationService.translate('map.try_again', {}, context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
                translationService.translate('common.cancel', {}, context)),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDisabledDialog(BuildContext context) {
    // Store a reference to the MapBloc before showing the dialog
    final mapBloc = context.read<MapBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(translationService.translate(
            'map.service_disabled_title', {}, context)),
        content: Text(
          translationService.translate(
              'map.service_disabled_message', {}, context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              mapBloc.add(const InitializeMap(requestCurrentLocation: true));
            },
            child: Text(
                translationService.translate('map.try_again', {}, context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
                translationService.translate('common.cancel', {}, context)),
          ),
        ],
      ),
    );
  }
}
