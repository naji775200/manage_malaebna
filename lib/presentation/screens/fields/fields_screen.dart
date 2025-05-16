import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/translation_service.dart';
import '../../../logic/fields/fields_bloc.dart';
import '../../../logic/fields/fields_event.dart';
import '../../../logic/fields/fields_state.dart';
import '../../../data/models/field_model.dart';
import '../../../data/models/entity_images_model.dart';
import '../../../data/repositories/entity_images_repository.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../presentation/screens/fields/add_field_screen.dart';

// Utility to handle field dialogs globally
class FieldDialogs {
  static void showAddFieldDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sizeController = TextEditingController();
    final surfaceTypeController = TextEditingController();
    final capacityController = TextEditingController();

    // Capture the bloc context before opening dialog
    final fieldsBloc = context.read<FieldsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            translationService.tr('stadium_management.add_field', {}, context)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_management.field_name', {}, context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sizeController,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_profile.size', {}, context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: surfaceTypeController,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_management.field_type', {}, context),
                  hintText: 'Grass, Artificial, etc.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_management.field_capacity', {}, context),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(translationService.tr('common.cancel', {}, context)),
          ),
          ElevatedButton(
            onPressed: () {
              final fieldData = {
                'name': nameController.text,
                'size': sizeController.text,
                'surface_type': surfaceTypeController.text,
                'capacity': capacityController.text,
              };

              // Use the captured bloc instead of reading from dialog context
              fieldsBloc.add(AddField(fieldData));
              Navigator.of(dialogContext).pop();
            },
            child: Text(translationService.tr('common.save', {}, context)),
          ),
        ],
      ),
    );
  }

  static void showEditFieldDialog(BuildContext context, Field field) {
    final nameController = TextEditingController(text: field.name);
    final sizeController = TextEditingController(text: field.size);
    final surfaceTypeController =
        TextEditingController(text: field.surfaceType);
    final capacityController = TextEditingController(
        text: field.recommendedPlayersNumber?.toString() ?? '');

    // Capture the fieldsBloc outside of the dialog
    final fieldBloc = context.read<FieldsBloc>();

    // Get the current locale
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Get localized availability
    String availability =
        fieldBloc.mapStatusToAvailability(field.status, isArabic: isArabic);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(translationService.tr(
            'stadium_management.edit_field', {}, context)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_management.field_name', {}, context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sizeController,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_profile.size', {}, context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: surfaceTypeController,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_management.field_type', {}, context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: translationService.tr(
                      'stadium_management.field_capacity', {}, context),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(builder: (context, setState) {
                return DropdownButtonFormField<String>(
                  value: availability,
                  decoration: InputDecoration(
                    labelText: translationService.tr(
                        'stadium_management.field_availability', {}, context),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: isArabic ? 'متاح' : 'Available',
                      child: Text(translationService.tr(
                          'stadium_management.available', {}, context)),
                    ),
                    DropdownMenuItem(
                      value: isArabic ? 'محجوز' : 'Booked',
                      child: Text(translationService.tr(
                          'stadium_management.booked', {}, context)),
                    ),
                    DropdownMenuItem(
                      value: isArabic ? 'صيانة' : 'Maintenance',
                      child: Text(translationService.tr(
                          'stadium_management.maintenance', {}, context)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        availability = value;
                      });
                    }
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(translationService.tr('common.cancel', {}, context)),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedFieldData = {
                'name': nameController.text,
                'size': sizeController.text,
                'surface_type': surfaceTypeController.text,
                'capacity': capacityController.text,
                'availability': availability,
              };

              // Add debug logs to track the status value
              print('Saving field with availability: $availability');

              // Use the captured bloc instead of reading from dialog context
              fieldBloc.add(UpdateField(field.id, updatedFieldData));
              Navigator.of(dialogContext).pop();
            },
            child: Text(translationService.tr('common.save', {}, context)),
          ),
        ],
      ),
    );
  }

  static void showDeleteFieldConfirmation(BuildContext context, Field field) {
    // Capture the fieldsBloc outside of the dialog
    final fieldBloc = context.read<FieldsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(translationService.tr(
            'stadium_management.delete_field', {}, context)),
        content: Text(
          translationService.tr(
              'stadium_management.delete_field_confirmation',
              {
                'fieldName': field.name,
              },
              context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(translationService.tr('common.cancel', {}, context)),
          ),
          TextButton(
            onPressed: () {
              // Use the captured bloc instead of reading from dialog context
              fieldBloc.add(DeleteField(field.id));
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translationService.tr('common.delete', {}, context)),
          ),
        ],
      ),
    );
  }
}

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, authState) {
      if (!authState.isAuthenticated) {
        return Scaffold(
          body: Center(
            child: Text(
                '${translationService.tr('common.error', {}, context)}: ${translationService.tr('auth.login', {}, context)}'),
          ),
        );
      }

      final String stadiumId = authState.userId; // Using user ID as stadium ID

      return BlocProvider(
        create: (context) =>
            FieldsBloc(stadiumId: stadiumId)..add(const LoadFields()),
        child: Builder(
          builder: (context) => Scaffold(
            body: const _FieldsContent(),
            floatingActionButton: _buildAddFieldButton(context),
          ),
        ),
      );
    });
  }

  Widget _buildAddFieldButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Replace dialog with navigation to the new screen
        final authState = context.read<AuthBloc>().state;
        final String stadiumId =
            authState.userId; // Using user ID as stadium ID

        Navigator.of(context)
            .push<bool>(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => FieldsBloc(stadiumId: stadiumId),
              child: AddFieldScreen(stadiumId: stadiumId),
            ),
          ),
        )
            .then((shouldRefresh) {
          // Refresh the fields list when returning from add screen
          if (shouldRefresh == true) {
            context.read<FieldsBloc>().add(const RefreshFields());
          }
        });
      },
      child: const Icon(Icons.add),
    );
  }
}

class _FieldsContent extends StatelessWidget {
  const _FieldsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldsBloc, FieldsState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasFields) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!state.hasFields) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  translationService.tr(
                      'stadium_management.no_fields', {}, context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  translationService.tr(
                      'stadium_management.add_fields_hint', {}, context),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Replace dialog with navigation to the new screen
                    final authState = context.read<AuthBloc>().state;
                    final String stadiumId =
                        authState.userId; // Using user ID as stadium ID

                    Navigator.of(context)
                        .push<bool>(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => FieldsBloc(stadiumId: stadiumId),
                          child: AddFieldScreen(stadiumId: stadiumId),
                        ),
                      ),
                    )
                        .then((shouldRefresh) {
                      // Refresh the fields list when returning from add screen
                      if (shouldRefresh == true) {
                        context.read<FieldsBloc>().add(const RefreshFields());
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(translationService.tr(
                      'stadium_management.add_field', {}, context)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FieldsBloc>().add(const RefreshFields());
            // Wait for refresh to complete
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.fields.length,
            itemBuilder: (context, index) {
              final field = state.fields[index];
              return _buildFieldCard(
                context,
                field: field,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFieldCard(
    BuildContext context, {
    required Field field,
  }) {
    final fieldBloc = context.read<FieldsBloc>();
    final isAvailable = field.status == 'available';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : theme.cardColor;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Create a shared instance of EntityImagesRepository
    // to avoid creating a new one each time
    final EntityImagesRepository imagesRepository = EntityImagesRepository();

    // Format the player capacity as "7x7" for display
    String formattedPlayerCapacity = 'N/A';
    if (field.recommendedPlayersNumber != null) {
      final playerCount = field.recommendedPlayersNumber!;
      formattedPlayerCapacity = '${playerCount}x${playerCount}';
    }

    // Translate surface type based on locale
    String translatedSurfaceType =
        _getTranslatedSurfaceType(field.surfaceType, isArabic);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isAvailable
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field image with availability tag
          Stack(
            children: [
              // Image carousel - try to use field's saved images if available, fall back to default
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: FutureBuilder<List<EntityImages>>(
                  future: imagesRepository.getImagesByEntityTypeAndId(
                      'field', field.id,
                      forceRefresh: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: theme.colorScheme.surface,
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      // Get all images for the field
                      final images = snapshot.data!;
                      print(
                          'Found ${images.length} images for field ${field.id}');

                      // Return image carousel if there are multiple images
                      return ImageCarousel(
                        images: images,
                        height: 180,
                        isDark: isDark,
                      );
                    } else {
                      // No images, show default
                      print('No images found for field ${field.id}');
                      return _buildPlaceholderImage(180, isDark);
                    }
                  },
                ),
              ),

              // Availability tag
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    // Use localized status based on current locale
                    fieldBloc.mapStatusToAvailability(field.status,
                        isArabic:
                            Localizations.localeOf(context).languageCode ==
                                'ar'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Field info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field name
                Text(
                  field.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Field surface type and capacity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              translatedSurfaceType,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedPlayerCapacity,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Field size and creation date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Size information
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Size: ${field.size}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    // Creation date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${field.createdAt.day}/${field.createdAt.month}/${field.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: Text(
                            translationService.tr('common.edit', {}, context)),
                        onPressed: () {
                          // Navigate to edit field screen
                          final authState = context.read<AuthBloc>().state;
                          final String stadiumId = authState.userId;

                          Navigator.of(context)
                              .push<bool>(
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: fieldBloc,
                                child: AddFieldScreen(
                                  stadiumId: stadiumId,
                                  field: field,
                                ),
                              ),
                            ),
                          )
                              .then((shouldRefresh) {
                            // Refresh the fields list when returning from edit screen
                            if (shouldRefresh == true) {
                              context
                                  .read<FieldsBloc>()
                                  .add(const RefreshFields());
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: Text(translationService.tr(
                            'common.delete', {}, context)),
                        onPressed: () =>
                            FieldDialogs.showDeleteFieldConfirmation(
                                context, field),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to translate surface type based on locale
  String _getTranslatedSurfaceType(String surfaceType, bool isArabic) {
    switch (surfaceType) {
      case 'Standard':
        return isArabic ? 'قياسي' : 'Standard';
      case 'Grass':
        return isArabic ? 'عشب طبيعي' : 'Grass';
      case 'Artificial':
        return isArabic ? 'عشب صناعي' : 'Artificial';
      case 'Indoor':
        return isArabic ? 'داخلي' : 'Indoor';
      case 'Clay':
        return isArabic ? 'طيني' : 'Clay';
      default:
        return surfaceType;
    }
  }

  // Helper method to build a placeholder image
  Widget _buildPlaceholderImage(double height, bool isDark) {
    return Container(
      height: height,
      width: double.infinity,
      color: isDark ? Colors.grey[800] : Colors.grey[300],
      child: Icon(
        Icons.sports_soccer,
        size: 50,
        color: isDark ? Colors.white : Colors.grey[700],
      ),
    );
  }
}

// Image carousel widget for displaying multiple images with sliding
class ImageCarousel extends StatefulWidget {
  final List<EntityImages> images;
  final double height;
  final bool isDark;

  const ImageCarousel({
    Key? key,
    required this.images,
    required this.height,
    required this.isDark,
  }) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image PageView
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index].imageUrl;

              // Check if it's a data URI or network image
              if (imageUrl.startsWith('data:')) {
                // It's a data URI, display using MemoryImage
                return Image.memory(
                  Uri.parse(imageUrl).data!.contentAsBytes(),
                  height: widget.height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error displaying data URI image: $error');
                    return _buildErrorPlaceholder();
                  },
                );
              } else {
                // It's a network image
                return Image.network(
                  imageUrl,
                  height: widget.height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error displaying network image: $error');
                    return _buildErrorPlaceholder();
                  },
                );
              }
            },
          ),
        ),

        // Navigation arrows - only show if there are multiple images
        if (widget.images.length > 1) ...[
          // Left arrow (previous)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: _currentPage > 0
                    ? const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18)
                    : const SizedBox(
                        width: 18,
                        height: 18), // Empty space when on first image
              ),
            ),
          ),

          // Right arrow (next)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_currentPage < widget.images.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: _currentPage < widget.images.length - 1
                    ? const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 18)
                    : const SizedBox(
                        width: 18,
                        height: 18), // Empty space when on last image
              ),
            ),
          ),
        ],

        // Page indicators
        if (widget.images.length > 1)
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to build an error placeholder
  Widget _buildErrorPlaceholder() {
    return Container(
      height: widget.height,
      width: double.infinity,
      color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
      child: Icon(
        Icons.broken_image,
        size: 50,
        color: widget.isDark ? Colors.white : Colors.grey[700],
      ),
    );
  }
}
