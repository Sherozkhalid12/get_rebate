import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/create_listing/controllers/create_listing_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';

class CreateListingView extends GetView<CreateListingController> {
  const CreateListingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping on screen
          FocusScope.of(context).unfocus();
        },
        child: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back, color: AppTheme.white),
            ),
            // actions: [
            //   IconButton(
            //     onPressed: controller.resetForm,
            //     icon: Icon(Icons.refresh, color: AppTheme.white),
            //     tooltip: 'Reset Form',
            //   ),
            // ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Create New Listing',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.home_work,
                    size: 60.sp,
                    color: AppTheme.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Form(
              key: controller.formKey,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    // Basic Information Card
                    _buildInfoCard(
                      context,
                      'Basic Information',
                      Icons.info_outline,
                      [
                        _buildInputField(
                          context,
                          controller: controller.titleController,
                          label: 'Property Title',
                          hint: 'Enter a compelling title for your property',
                          isRequired: true,
                          icon: Icons.title,
                        ),
                        SizedBox(height: 16.h),
                        _buildTextAreaField(
                          context,
                          controller: controller.descriptionController,
                          label: 'Property Description',
                          hint: 'Describe your property in detail...',
                          isRequired: true,
                          icon: Icons.description,
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Location Information Card
                    _buildInfoCard(
                      context,
                      'Location Information',
                      Icons.location_on,
                      [
                        _buildInputField(
                          context,
                          controller: controller.addressController,
                          label: 'Street Address',
                          hint: 'Enter the full street address',
                          isRequired: true,
                          icon: Icons.home,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                context,
                                controller: controller.cityController,
                                label: 'City',
                                hint: 'City',
                                isRequired: true,
                                icon: Icons.location_city,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildInputField(
                                context,
                                controller: controller.stateController,
                                label: 'State',
                                hint: 'State',
                                isRequired: true,
                                icon: Icons.map,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _buildInputField(
                          context,
                          controller: controller.zipCodeController,
                          label: 'ZIP Code',
                          hint: 'ZIP Code',
                          isRequired: true,
                          icon: Icons.pin_drop,
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Property Details Card
                    _buildInfoCard(context, 'Property Details', Icons.home, [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              context,
                              'Property Type',
                              controller.selectedPropertyType,
                              controller.propertyTypes,
                              controller.setPropertyType,
                              Icons.category,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildDropdownField(
                              context,
                              'Status',
                              controller.selectedStatus,
                              controller.statusOptions,
                              controller.setStatus,
                              Icons.flag,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              context,
                              controller: controller.priceController,
                              label: 'Price',
                              hint: 'Enter price',
                              isRequired: true,
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildInputField(
                              context,
                              controller: controller.squareFeetController,
                              label: 'Square Feet',
                              hint: 'Square footage',
                              isRequired: true,
                              icon: Icons.square_foot,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              context,
                              controller: controller.bedroomsController,
                              label: 'Bedrooms',
                              hint: 'Number of bedrooms',
                              isRequired: true,
                              icon: Icons.bed,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildInputField(
                              context,
                              controller: controller.bathroomsController,
                              label: 'Bathrooms',
                              hint: 'Number of bathrooms',
                              isRequired: true,
                              icon: Icons.bathtub,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    SizedBox(height: 20.h),

                    // Features Card
                    _buildInfoCard(context, 'Property Features', Icons.star, [
                      _buildFeaturesGrid(context),
                    ]),

                    SizedBox(height: 20.h),

                    // Images Card
                    _buildInfoCard(
                      context,
                      'Property Images',
                      Icons.photo_library,
                      [_buildImagesSection(context)],
                    ),

                    SizedBox(height: 32.h),

                    // Submit Button
                    Obx(
                      () => GradientCard(
                        gradientColors: AppTheme.primaryGradient,
                        child: CustomButton(
                          text: controller.isLoading
                              ? 'Creating...'
                              : 'Create Listing',
                          onPressed: controller.isLoading
                              ? null
                              : controller.submitForm,
                          icon: Icons.add,
                          width: double.infinity,
                          height: 22.h,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          isLoading: controller.isLoading,
                          backgroundColor: Colors.transparent,
                          textColor: AppTheme.white,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppTheme.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Card Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: AppTheme.primaryBlue),
            SizedBox(width: 8.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4.w),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.mediumGray, size: 20.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTextAreaField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: AppTheme.primaryBlue),
            SizedBox(width: 8.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4.w),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 60.h),
              child: Icon(icon, color: AppTheme.mediumGray, size: 20.sp),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: AppTheme.primaryBlue),
            SizedBox(width: 8.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: selectedValue,
          onChanged: (value) => onChanged(value ?? options.first),
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.mediumGray, size: 18.sp),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.white,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 12.sp),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: controller.availableFeatures.map((feature) {
          final isSelected = controller.selectedFeatures.contains(feature);
          return GestureDetector(
            onTap: () => controller.toggleFeature(feature),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppTheme.primaryGradient,
                      )
                    : null,
                color: isSelected ? null : AppTheme.lightGray,
                borderRadius: BorderRadius.circular(25.r),
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Text(
                    feature.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.white : AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 16.sp,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Property Images',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextButton.icon(
                  onPressed: () => _showAddPhotoDialog(context),
                  icon: Icon(Icons.add, size: 16.sp, color: AppTheme.white),
                  label: Text(
                    'Add Image',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

              if (controller.selectedPhotos.isEmpty)
            GestureDetector(
              onTap: () => _showAddPhotoDialog(context),
              child: Container(
                height: 140.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGray,
                      AppTheme.lightGray.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.mediumGray.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate,
                        size: 28.sp,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Flexible(
                      child: Text(
                        'No images added yet',
                        style: TextStyle(
                          color: AppTheme.mediumGray,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Flexible(
                      child: Text(
                        'Tap to add images',
                        style: TextStyle(
                          color: AppTheme.mediumGray.withOpacity(0.7),
                          fontSize: 11.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Obx(
              () => SizedBox(
                height: 140.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.selectedPhotos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Stack(
                        children: [
                          Container(
                            width: 120.w,
                            height: 140.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              image: DecorationImage(
                                image: FileImage(controller.selectedPhotos[index]),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: GestureDetector(
                              onTap: () => controller.removePhoto(index),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 4.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14.sp,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8.h,
                            left: 8.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context) {
    final ImagePicker picker = ImagePicker();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Photos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Get.back();
                await _pickImages(context, picker, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Get.back();
                await _pickImages(context, picker, ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _pickImages(
    BuildContext context,
    ImagePicker picker,
    ImageSource source,
  ) async {
    try {
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (var image in images) {
          if (controller.selectedPhotos.length >= 10) {
            Get.snackbar('Limit Reached', 'You can add up to 10 photos');
            break;
          }
          controller.addPhoto(File(image.path));
        }
      }
    } catch (e) {
      if (source == ImageSource.camera) {
        // If multi-image fails for camera, try single image
        try {
          final XFile? image = await picker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (image != null) {
            if (controller.selectedPhotos.length < 10) {
              controller.addPhoto(File(image.path));
            } else {
              Get.snackbar('Limit Reached', 'You can add up to 10 photos');
            }
          }
        } catch (e2) {
          Get.snackbar('Error', 'Failed to pick image: ${e2.toString()}');
        }
      } else {
        Get.snackbar('Error', 'Failed to pick images: ${e.toString()}');
      }
    }
  }
}
