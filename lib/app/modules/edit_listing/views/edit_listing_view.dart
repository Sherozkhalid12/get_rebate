import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/edit_listing/controllers/edit_listing_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_search_field.dart';

class EditListingView extends GetView<EditListingController> {
  const EditListingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Text(
          'Edit Listing',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: controller.resetForm,
            child: Text(
              'Reset',
              style: TextStyle(color: AppTheme.white, fontSize: 14.sp),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionHeader(context, 'Basic Information'),
              SizedBox(height: 16.h),

              CustomSearchField(
                controller: controller.titleController,
                hintText: 'Property Title *',
                onChanged: (value) {},
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: controller.descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Property Description *',
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
                    borderSide: BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // Location Information
              _buildSectionHeader(context, 'Location Information'),
              SizedBox(height: 16.h),

              CustomSearchField(
                controller: controller.addressController,
                hintText: 'Street Address *',
                onChanged: (value) {},
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomSearchField(
                      controller: controller.cityController,
                      hintText: 'City *',
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomSearchField(
                      controller: controller.stateController,
                      hintText: 'State *',
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              CustomSearchField(
                controller: controller.zipCodeController,
                hintText: 'ZIP Code *',
                onChanged: (value) {},
              ),
              SizedBox(height: 24.h),

              // Property Details
              _buildSectionHeader(context, 'Property Details'),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      context,
                      'Property Type',
                      controller.selectedPropertyType,
                      controller.propertyTypes,
                      controller.setPropertyType,
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
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: CustomSearchField(
                      controller: controller.priceController,
                      hintText: 'Price *',
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomSearchField(
                      controller: controller.squareFeetController,
                      hintText: 'Square Feet *',
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: CustomSearchField(
                      controller: controller.bedroomsController,
                      hintText: 'Bedrooms *',
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomSearchField(
                      controller: controller.bathroomsController,
                      hintText: 'Bathrooms *',
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Features
              _buildSectionHeader(context, 'Features'),
              SizedBox(height: 16.h),

              _buildFeaturesGrid(context),
              SizedBox(height: 24.h),

              // Images
              _buildSectionHeader(context, 'Images'),
              SizedBox(height: 16.h),

              _buildImagesSection(context),
              SizedBox(height: 32.h),

              // Submit Button
              Obx(
                () => CustomButton(
                  text: controller.isLoading ? 'Updating...' : 'Update Listing',
                  onPressed: controller.isLoading
                      ? null
                      : controller.submitForm,
                  icon: Icons.save,
                  width: double.infinity,
                  isLoading: controller.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppTheme.darkGray,
        fontWeight: FontWeight.w600,
        fontSize: 18.sp,
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkGray,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: selectedValue,
          onChanged: (value) => onChanged(value ?? options.first),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
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
              borderSide: BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option.toUpperCase(),
                style: TextStyle(fontSize: 14.sp),
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
        spacing: 8.w,
        runSpacing: 8.h,
        children: controller.availableFeatures.map((feature) {
          final isSelected = controller.selectedFeatures.contains(feature);
          return FilterChip(
            label: Text(
              feature.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 12.sp),
            ),
            selected: isSelected,
            onSelected: (selected) => controller.toggleFeature(feature),
            selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
            checkmarkColor: AppTheme.primaryBlue,
            backgroundColor: AppTheme.lightGray,
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
              Text(
                'Property Images',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addMockImage(),
                icon: Icon(Icons.add, size: 16.sp),
                label: Text('Add Image', style: TextStyle(fontSize: 12.sp)),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (controller.images.isEmpty)
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.mediumGray,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 32.sp, color: AppTheme.mediumGray),
                  SizedBox(height: 8.h),
                  Text(
                    'No images added yet',
                    style: TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Stack(
                      children: [
                        Container(
                          width: 120.w,
                          height: 120.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            image: DecorationImage(
                              image: NetworkImage(controller.images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: GestureDetector(
                            onTap: () => controller.removeImage(index),
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16.sp,
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
        ],
      ),
    );
  }

  void _addMockImage() {
    // Add a mock image URL
    final mockImages = [
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400&h=300&fit=crop',
    ];

    final randomImage =
        mockImages[DateTime.now().millisecondsSinceEpoch % mockImages.length];
    controller.addImage(randomImage);
  }
}
