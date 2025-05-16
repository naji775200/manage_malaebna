import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../data/repositories/entity_images_repository.dart';
import '../../../data/models/entity_images_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../../presentation/widgets/custom_button.dart';
import '../../../presentation/widgets/custom_text_field.dart';
import '../../../presentation/widgets/custom_snackbar.dart';

class OwnerProfileScreen extends StatefulWidget {
  final String ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;

  const OwnerProfileScreen({
    Key? key,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
  }) : super(key: key);

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Image management
  late ImageUploadHelper _imageUploadHelper;
  List<String> _ownerImageUrls = [];
  bool _isLoadingImages = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameController.text = widget.ownerName ?? '';
    _phoneController.text = widget.ownerPhone ?? '';
    _emailController.text = widget.ownerEmail ?? '';

    // Initialize image upload helper
    _imageUploadHelper = ImageUploadHelper(
      context: context,
      translationService: translationService,
    );

    // Load owner images
    _loadOwnerImages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerImages() async {
    setState(() {
      _isLoadingImages = true;
    });

    try {
      final images = await _imageUploadHelper.getEntityImages(
        entityType: 'owner',
        entityId: widget.ownerId,
        forceRefresh: true,
      );

      setState(() {
        _ownerImageUrls = images.map((img) => img.imageUrl).toList();
        _isLoadingImages = false;
      });
    } catch (e) {
      print('Error loading owner images: $e');
      setState(() {
        _isLoadingImages = false;
      });

      CustomSnackBar.showError(context, 'Failed to load owner images: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      // Check if we're at the maximum number of images (5)
      if (_ownerImageUrls.length >= 5) {
        CustomSnackBar.showWarning(
            context,
            translationService.tr(
                    'owner_profile.max_images_reached', {}, context) ??
                'Maximum of 5 images reached');
        return;
      }

      final uploadedImage = await _imageUploadHelper.uploadSingleImage(
        entityType: 'owner',
        entityId: widget.ownerId,
        replaceExisting: false,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (uploadedImage != null) {
        // Refresh the image list
        _loadOwnerImages();
      }
    } catch (e) {
      print('Error picking image: $e');
      CustomSnackBar.showError(context, 'Error uploading image: $e');
    }
  }

  Future<void> _removeImage(String imageUrl) async {
    try {
      // First update the UI for immediate feedback
      setState(() {
        _ownerImageUrls.remove(imageUrl);
      });

      // Delete the image from the database
      final success = await _imageUploadHelper.deleteImageByUrl(
        entityType: 'owner',
        entityId: widget.ownerId,
        imageUrl: imageUrl,
      );

      if (!success) {
        // If delete failed, restore the image in the UI
        setState(() {
          _ownerImageUrls.add(imageUrl);
        });

        CustomSnackBar.showError(context, 'Failed to delete image');
      }
    } catch (e) {
      print('Error removing image: $e');

      // Restore the image in the UI
      setState(() {
        if (!_ownerImageUrls.contains(imageUrl)) {
          _ownerImageUrls.add(imageUrl);
        }
      });

      CustomSnackBar.showError(context, 'Error deleting image: $e');
    }
  }

  void _saveOwnerProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // In a real app, you would save the owner profile data here
    // For this example, we'll just simulate a save operation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        CustomSnackBar.showSuccess(context, 'Owner profile saved successfully');

        // Return to previous screen
        Navigator.of(context).pop();
      }
    });
  }

  // Helper method to get the appropriate DecorationImage based on the URL type
  DecorationImage _getDecorationImage(String imageUrl) {
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
          // Fallback to default image
          return const DecorationImage(
            image: AssetImage('assets/images/profile/default_avatar.png'),
            fit: BoxFit.cover,
          );
        }
      }
      // If data URI parsing fails, fall back to default image
      return const DecorationImage(
        image: AssetImage('assets/images/profile/default_avatar.png'),
        fit: BoxFit.cover,
      );
    } else {
      // Regular network image for http/https URLs
      return DecorationImage(
        image: NetworkImage(imageUrl),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translationService.tr('owner_profile.title', {}, context) ??
            'Owner Profile'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Images Section
              Text(
                translationService.tr(
                        'owner_profile.owner_images', {}, context) ??
                    'Owner Images',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Image Counter
              Text(
                '${translationService.tr('owner_profile.images', {}, context) ?? 'Images'}: ${_ownerImageUrls.length}/5',
                style: TextStyle(
                  fontSize: 14,
                  color: _ownerImageUrls.length >= 5
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Image carousel
              SizedBox(
                height: 120,
                child: _isLoadingImages
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add image button
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                  Text(
                                    translationService.tr(
                                            'owner_profile.add_image',
                                            {},
                                            context) ??
                                        'Add Image',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Display all owner images
                          if (_ownerImageUrls.isNotEmpty)
                            ..._ownerImageUrls.map((url) {
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: _getDecorationImage(url),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Delete button
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: InkWell(
                                        onTap: () => _removeImage(url),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Owner Information Section
              Text(
                translationService.tr(
                        'owner_profile.personal_information', {}, context) ??
                    'Personal Information',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              CustomTextField(
                controller: _nameController,
                label:
                    translationService.tr('owner_profile.name', {}, context) ??
                        'Name',
                hint: translationService.tr(
                        'owner_profile.enter_name', {}, context) ??
                    'Enter owner name',
                prefixIcon: Icons.person,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                            'validation.name_required', {}, context) ??
                        'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              CustomTextField(
                controller: _phoneController,
                label:
                    translationService.tr('owner_profile.phone', {}, context) ??
                        'Phone',
                hint: translationService.tr(
                        'owner_profile.enter_phone', {}, context) ??
                    'Enter phone number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                            'validation.phone_required', {}, context) ??
                        'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              CustomTextField(
                controller: _emailController,
                label:
                    translationService.tr('owner_profile.email', {}, context) ??
                        'Email',
                hint: translationService.tr(
                        'owner_profile.enter_email', {}, context) ??
                    'Enter email address',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return translationService.tr(
                              'validation.email_invalid', {}, context) ??
                          'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text:
                    translationService.tr('common.save', {}, context) ?? 'Save',
                onPressed: _isSaving ? null : _saveOwnerProfile,
                isLoading: _isSaving,
                variant: CustomButtonVariant.primary,
                size: CustomButtonSize.large,
                isFullWidth: true,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
