import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/theme.dart';
import '../../../logic/fields/fields_bloc.dart';
import '../../../logic/fields/fields_event.dart';
import '../../../logic/fields/fields_state.dart';
import '../../../core/services/translation_service.dart';
import '../../../presentation/widgets/custom_snackbar.dart';
import '../../../presentation/widgets/custom_button.dart';
import '../../../presentation/widgets/custom_text_field.dart';
import '../../../presentation/widgets/custom_dropdown.dart';
import '../../../data/repositories/entity_images_repository.dart';
import '../../../data/models/entity_images_model.dart';
import '../../../data/models/field_model.dart';

class AddFieldScreen extends StatefulWidget {
  final String stadiumId;
  final Field? field; // Optional field for edit mode

  const AddFieldScreen({
    Key? key,
    required this.stadiumId,
    this.field,
  }) : super(key: key);

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _playersController = TextEditingController();
  final TextEditingController _playersController2 = TextEditingController();

  final EntityImagesRepository _imagesRepository = EntityImagesRepository();
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _imageUrls = [];
  bool _isProcessing = false;
  bool _isLoadingImages = false;
  List<File> _selectedImages = [];

  // Add properties for dropdowns
  String _selectedSurfaceType = 'Standard';
  String _selectedStatus = 'available';

  // Add a class property to store the temp ID
  final String _tempFieldId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

  bool get _isEditMode => widget.field != null;

  // Add a method to refresh the image count from the database
  Future<void> _refreshImageCount() async {
    if (_isProcessing) return; // Don't refresh while processing save

    try {
      final entityId = _isEditMode ? widget.field!.id : _tempFieldId;
      print('Refreshing image count for $entityId');

      final images = await _imagesRepository.getImagesByEntityTypeAndId(
          'field', entityId,
          forceRefresh: true // Always get latest from storage
          );

      if (mounted) {
        print(
            'Database has ${images.length} images, UI shows ${_imageUrls.length} images');

        // Update the UI state to match the database
        setState(() {
          // Update the image URLs list with what's in the database
          _imageUrls = images.map((img) => img.imageUrl).toList();

          // Log the updated image URLs for debugging
          if (_imageUrls.isNotEmpty) {
            print('Updated image URLs: ${_imageUrls.length} images available');
            if (_imageUrls.isNotEmpty) {
              print(
                  'First image URL type: ${_imageUrls.first.substring(0, 30)}...');
            }
          } else {
            print('No images available after refresh');
          }
        });
      }
    } catch (e) {
      print('Error refreshing image count: $e');
      // Show an error message to the user
      if (mounted) {
        CustomSnackBar.showError(context,
            translationService.tr('snackbar.error.general', {}, context));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFieldData();

    // Add a delayed refresh to ensure we have the latest image data
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        print(
            'Running delayed image refresh for entity ID: ${_isEditMode ? widget.field!.id : _tempFieldId}');
        _refreshImageCount();
      }
    });

    // Force another refresh after a longer delay to catch any async updates
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _imageUrls.isEmpty) {
        print('Running secondary image refresh check');
        _refreshImageCount();
      }
    });
  }

  // Initialize field data if in edit mode
  Future<void> _initializeFieldData() async {
    if (_isEditMode) {
      final field = widget.field!;

      // Set text controllers
      _nameController.text = field.name;

      // Parse size (e.g., "40x60")
      if (field.size.contains('x')) {
        final sizeParts = field.size.split('x');
        if (sizeParts.length == 2) {
          _widthController.text = sizeParts[0];
          _lengthController.text = sizeParts[1];
        }
      }

      // Parse recommended players number (e.g., "7x7")
      if (field.recommendedPlayersNumber != null) {
        final playerCount = field.recommendedPlayersNumber!;
        // Use the same number for both sides to create "7x7" format
        _playersController.text = playerCount.toString();
        _playersController2.text = playerCount.toString();
      }

      // Set dropdowns
      _selectedSurfaceType = field.surfaceType;
      _selectedStatus = field.status;

      // Try to load existing images
      setState(() {
        _isLoadingImages = true;
      });

      try {
        // Fetch field images from repository
        final images = await _imagesRepository.getImagesByEntityTypeAndId(
            'field', field.id);

        if (images.isNotEmpty) {
          setState(() {
            _imageUrls = images.map((img) => img.imageUrl).toList();
          });

          // We don't have the original File objects when editing, so we only have URLs
        }
      } catch (e) {
        CustomSnackBar.showError(
            context, 'Failed to load field images: ${e.toString()}');
      } finally {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _playersController.dispose();
    _playersController2.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Check if we already have 5 images
    if (_imageUrls.length >= 5) {
      CustomSnackBar.showWarning(
          context,
          translationService.tr(
              'stadium_management.max_images_reached', {}, context));
      return;
    }

    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imageFile != null) {
        setState(() {
          _isLoadingImages = true;
          // Add to selected images list for immediate UI feedback
          _selectedImages.add(File(imageFile.path));
        });

        final file = File(imageFile.path);

        // Use the consistent temp ID for all images in this session
        final entityId = _isEditMode ? widget.field!.id : _tempFieldId;

        print('Uploading image with entityId: $entityId');

        try {
          // Upload and store the image locally
          // Set replaceExisting to false to allow multiple images
          final entityImage = await _imagesRepository.uploadImage(
            imageFile: file,
            entityType: 'field',
            entityId: entityId,
            replaceExisting: false, // Don't replace existing images
          );

          // Important: Don't update UI state here; let _refreshImageCount handle it
          CustomSnackBar.showSuccess(
              context,
              translationService.tr(
                  'snackbar.success.image_added', {}, context));

          // Clear selectedImages to avoid duplicates, since the image is now in the database
          setState(() {
            _selectedImages.clear();
          });

          // Refresh image count to ensure UI is in sync with database
          await _refreshImageCount();
        } catch (e) {
          // If upload failed, remove from selection
          if (_selectedImages.isNotEmpty) {
            setState(() {
              _selectedImages.removeLast();
            });
          }

          CustomSnackBar.showError(
              context,
              translationService.tr('snackbar.error.image_upload_failed',
                  {'error': e.toString()}, context));
        } finally {
          setState(() {
            _isLoadingImages = false;
          });
        }
      }
    } catch (e) {
      CustomSnackBar.showError(
          context,
          translationService.tr('snackbar.error.error_picking_image',
              {'error': e.toString()}, context));
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  void _removeImage(int index) async {
    if (index >= _imageUrls.length) {
      print('Invalid index $index for image removal');
      return;
    }

    String imageUrl = _imageUrls[index];
    print(
        'Removing image at index $index with URL: ${imageUrl.substring(0, 30)}...');

    // Update the UI immediately for better UX
    setState(() {
      _imageUrls.removeAt(index);
    });

    // Show loading indicator for background deletion
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(translationService.tr(
                'snackbar.info.deleting_image', {}, context)),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Get the entity ID
      final entityId = _isEditMode ? widget.field!.id : _tempFieldId;

      // Find and delete the image from the database
      final images =
          await _imagesRepository.getImagesByEntityTypeAndId('field', entityId);
      print('Found ${images.length} total images for entity $entityId');

      bool deleted = false;

      // Find the image with matching URL
      for (final image in images) {
        if (image.imageUrl == imageUrl) {
          print('Found matching image with ID: ${image.id}');

          // Delete from local storage
          await _imagesRepository.delete(image.id);
          print('Deleted image ${image.id} from local storage');
          deleted = true;
          break;
        }
      }

      if (!deleted) {
        print(
            'WARNING: Could not find image with URL in database. It may have already been deleted.');
      }

      // Show success message
      scaffoldMessenger.hideCurrentSnackBar();
      CustomSnackBar.showSuccess(context,
          translationService.tr('snackbar.success.image_removed', {}, context));

      // No need to call _refreshImageCount here as we've already updated the UI
      // and removed the image from the database
    } catch (e) {
      // Show error but keep the image removed from UI (soft delete)
      scaffoldMessenger.hideCurrentSnackBar();
      CustomSnackBar.showError(
          context,
          translationService.tr('snackbar.error.image_delete_failed',
              {'error': e.toString()}, context));
      print('Error deleting image: $e');
    }
  }

  void _saveField() {
    if (_nameController.text.isEmpty) {
      CustomSnackBar.showError(context,
          translationService.tr('validation.name_required', {}, context));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Store width and length as a single string with format "WIDTHxLENGTH"
    final size = "${_widthController.text}x${_lengthController.text}";

    // Store player counts as a single string with format "COUNTxCOUNT"
    final playersCapacity =
        "${_playersController.text}x${_playersController2.text}";

    // Create the unique ID that will be used for the field
    // This should match the format used in fields_bloc.dart
    final tempFieldId = _isEditMode ? widget.field!.id : _tempFieldId;

    print(
        'Saving field with ${_imageUrls.length} images using ID: $tempFieldId');

    // Debug current status
    print('Current status value: $_selectedStatus');

    final fieldData = {
      'name': _nameController.text,
      'size': size,
      'surface_type': _selectedSurfaceType,
      'capacity': playersCapacity,
      'images': _imageUrls,
      'temp_id': tempFieldId, // Include the temp ID for debugging
    };

    if (_isEditMode) {
      // Include status for edit mode
      // Set both 'status' and 'availability' to ensure it works correctly
      fieldData['status'] = _selectedStatus;
      fieldData['availability'] = _selectedStatus == 'available'
          ? 'Available'
          : _selectedStatus == 'booked'
              ? 'Booked'
              : 'Maintenance';

      print(
          'Updating field with status: ${fieldData['status']} and availability: ${fieldData['availability']}');

      // Update existing field
      context.read<FieldsBloc>().add(UpdateField(widget.field!.id, fieldData));
    } else {
      // Add new field
      context.read<FieldsBloc>().add(AddField(fieldData));
    }

    // Navigate back after slight delay to show the processing state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Return true to indicate the fields should be refreshed
        Navigator.pop(context, true);
      }
    });
  }

  // Update Surface type options to use translation values
  List<Map<String, dynamic>> _getSurfaceTypes(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return [
      {'id': 'Standard', 'name': isArabic ? 'قياسي' : 'Standard'},
      {'id': 'Grass', 'name': isArabic ? 'عشب طبيعي' : 'Grass'},
      {'id': 'Artificial', 'name': isArabic ? 'عشب صناعي' : 'Artificial'},
      {'id': 'Indoor', 'name': isArabic ? 'داخلي' : 'Indoor'},
      {'id': 'Clay', 'name': isArabic ? 'طيني' : 'Clay'},
    ];
  }

  // Update Status options to use translation values
  List<Map<String, dynamic>> _getStatusOptions(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return [
      {'id': 'available', 'name': isArabic ? 'متاح' : 'Available'},
      {'id': 'booked', 'name': isArabic ? 'محجوز' : 'Booked'},
      {'id': 'maintenance', 'name': isArabic ? 'صيانة' : 'Maintenance'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    // Get translated options based on current locale
    final surfaceTypes = _getSurfaceTypes(context);
    final statusOptions = _getStatusOptions(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode
            ? translationService.tr(
                'stadium_management.edit_field', {}, context)
            : translationService.tr(
                'stadium_management.add_field', {}, context)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Images section at the top
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translationService.tr(
                        'stadium_management.images', {}, context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  // Add image counter display
                  Text(
                    '${translationService.tr('stadium_management.images', {}, context)} ${_imageUrls.length}/5',
                    style: TextStyle(
                      fontSize: 14,
                      color: _imageUrls.length >= 5
                          ? Colors.red
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: _isLoadingImages
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Add image button
                              InkWell(
                                onTap: _pickImage,
                                child: Tooltip(
                                  message: translationService.tr(
                                      'stadium_management.add_field_image',
                                      {},
                                      context),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add,
                                          size: 40,
                                          color: AppTheme.primaryColor,
                                        ),
                                        if (_imageUrls.length >= 5)
                                          Text(
                                            translationService.tr(
                                                'stadium_management.max_images',
                                                {},
                                                context),
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Selected images - only show when there are actual selected images
                              ..._selectedImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final file = entry.value;
                                return Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              // Display image URLs for both edit mode and add mode
                              if (_imageUrls.isNotEmpty) ...[
                                ..._imageUrls.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final url = entry.value;
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: url.startsWith('data:')
                                            ? MemoryImage(Uri.parse(url)
                                                .data!
                                                .contentAsBytes())
                                            : NetworkImage(url)
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Field Name
              CustomTextField(
                controller: _nameController,
                label: isRtl ? 'اسم الملعب' : 'Field Name',
                hint: isRtl ? 'اسم الملعب' : 'Field Name',
                prefixIcon: Icons.sports_soccer,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                        'validation.name_required', {}, context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // Surface Type Dropdown
              CustomDropdown<String>(
                labelText: isRtl ? 'نوع السطح' : 'Surface Type',
                value: _selectedSurfaceType,
                items: surfaceTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['id'],
                    child: Text(type['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSurfaceType = value;
                    });
                  }
                },
                isRequired: true,
              ),
              const SizedBox(height: 25),

              // Status Dropdown (only shown in edit mode)
              if (_isEditMode)
                Column(
                  children: [
                    CustomDropdown<String>(
                      labelText: isRtl ? 'الحالة' : 'Status',
                      value: _selectedStatus,
                      items: statusOptions.map((status) {
                        return DropdownMenuItem<String>(
                          value: status['id'],
                          child: Text(status['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 25),
                  ],
                ),

              // Field Size
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translationService.tr(
                        'stadium_management.field_size', {}, context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _widthController,
                          label: '',
                          hint: translationService.tr(
                              'stadium_management.width', {}, context),
                          keyboardType: TextInputType.number,
                          height: 60,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Text(
                          "x",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _lengthController,
                          label: '',
                          hint: translationService.tr(
                              'stadium_management.length', {}, context),
                          keyboardType: TextInputType.number,
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment:
                        isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      translationService.tr(
                          'stadium_management.square_meter', {}, context),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Maximum Players
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translationService.tr(
                        'stadium_management.max_players', {}, context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _playersController,
                          label: '',
                          hint: translationService.tr(
                              'stadium_management.team1', {}, context),
                          keyboardType: TextInputType.number,
                          height: 60,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Text(
                          "x",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _playersController2,
                          label: '',
                          hint: translationService.tr(
                              'stadium_management.team2', {}, context),
                          keyboardType: TextInputType.number,
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          text: _isEditMode
              ? (isRtl ? 'حفظ التغييرات' : 'Save Changes')
              : (isRtl ? 'حفظ' : 'Save'),
          onPressed: _isProcessing ? null : _saveField,
          isLoading: _isProcessing,
          variant: CustomButtonVariant.primary,
          size: CustomButtonSize.large,
          isFullWidth: true,
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
