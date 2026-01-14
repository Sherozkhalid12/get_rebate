import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/property_listings/controllers/property_listings_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_search_field.dart';
import 'package:getrebate/app/widgets/notification_badge_icon.dart';

class PropertyListingsView extends GetView<PropertyListingsController> {
  const PropertyListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
        title: Text(
          'Sell',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: const NotificationBadgeIcon(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filters
            _buildSearchAndFilters(context),

            // Properties List
            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.properties.isEmpty) {
                  return const Center(
                    child: SpinKitFadingCircle(
                      color: AppTheme.primaryBlue,
                      size: 40,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => controller.fetchListings(),
                  child: _buildPropertiesList(context),
                );
              }),
            ),
          ],
        ),
      ),
      // DISABLED: Floating action button for creating listings - buyers cannot create listings anymore
      // floatingActionButton: FloatingActionButton(
      //   onPressed: controller.createNewListing,
      //   backgroundColor: AppTheme.primaryBlue,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
          ),

          // Title
          Expanded(
            child: Text(
              'My Properties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // DISABLED: Add Property Button - buyers cannot create listings anymore
          // IconButton(
          //   onPressed: controller.createNewListing,
          //   icon: const Icon(Icons.add, color: AppTheme.primaryBlue),
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          // Search Field
          CustomSearchField(
            controller: TextEditingController(text: controller.searchQuery),
            hintText: 'Search properties...',
            // allowText: true,
            onChanged: controller.setSearchQuery,
          ),

          SizedBox(height: 16.h),

          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    'All',
                    'all',
                    controller.selectedStatus,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    context,
                    'Active',
                    'active',
                    controller.selectedStatus,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    context,
                    'Pending',
                    'pending',
                    controller.selectedStatus,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    context,
                    'Sold',
                    'sold',
                    controller.selectedStatus,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    context,
                    'Draft',
                    'draft',
                    controller.selectedStatus,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Additional Filters
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildDropdownFilter(
          //         context,
          //         'Property Type',
          //         controller.selectedPropertyType,
          //         ['all', 'house', 'condo', 'townhouse'],
          //         controller.setSelectedPropertyType,
          //       ),
          //     ),
          //     SizedBox(width: 12.w),
          //     Expanded(
          //       child: _buildDropdownFilter(
          //         context,
          //         'Price Range',
          //         controller.selectedPriceRange,
          //         ['all', 'under_500k', '500k_1m', 'over_1m'],
          //         controller.setSelectedPriceRange,
          //       ),
          //     ),
          //   ],
          // ),

          // Clear Filters Button
          Obx(
            () =>
                controller.selectedStatus != 'all' ||
                    controller.selectedPropertyType != 'all' ||
                    controller.selectedPriceRange != 'all' ||
                    controller.searchQuery.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: TextButton.icon(
                      onPressed: controller.clearFilters,
                      icon: Icon(Icons.clear, size: 16.sp),
                      label: Text(
                        'Clear Filters',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    String selectedValue,
  ) {
    final isSelected = selectedValue == value;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.darkGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => controller.setSelectedStatus(value),
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.lightGray,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray.withOpacity(0.3),
        width: isSelected ? 1.5 : 1.0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    );
  }


  Widget _buildDropdownFilter(
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.darkGray,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<String>(
          value: selectedValue,
          onChanged: (value) => onChanged(value ?? 'all'),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
          items: options.map((option) {
            String displayText;
            switch (option) {
              case 'all':
                displayText = 'All ${label}s';
                break;
              case 'house':
                displayText = 'House';
                break;
              case 'condo':
                displayText = 'Condo';
                break;
              case 'townhouse':
                displayText = 'Townhouse';
                break;
              case 'under_500k':
                displayText = 'Under \$500K';
                break;
              case '500k_1m':
                displayText = '\$500K - \$1M';
                break;
              case 'over_1m':
                displayText = 'Over \$1M';
                break;
              default:
                displayText = option;
            }
            return DropdownMenuItem(
              value: option,
              child: Text(displayText, style: TextStyle(fontSize: 12.sp)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertiesList(BuildContext context) {
    return Obx(() {
      final filteredProperties = controller.filteredProperties;

      if (filteredProperties.isEmpty && !controller.isLoading) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredProperties.length,
        itemBuilder: (context, index) {
          final property = filteredProperties[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPropertyCard(context, property)
                .animate()
                .slideX(
                  begin: 0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                  delay: (index * 100).ms,
                )
                .fadeIn(duration: 600.ms, delay: (index * 100).ms),
          );
        },
      );
    });
  }

  Widget _buildPropertyCard(BuildContext context, property) {
    return Card(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: property.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(property.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: property.images.isEmpty ? AppTheme.lightGray : null,
              ),
              child: property.images.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.home,
                        size: 50,
                        color: AppTheme.mediumGray,
                      ),
                    )
                  : Stack(
                      children: [
                        // Status Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  controller
                                      .getStatusColor(property.status)
                                      .replaceAll('#', '0xFF'),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              controller.getStatusLabel(property.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Price
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '\$${property.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property.address}, ${property.city}, ${property.state} ${property.zipCode}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.mediumGray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Property Details
                  Row(
                    children: [
                      _buildPropertyDetail(
                        context,
                        Icons.bed,
                        '${property.bedrooms} bed',
                      ),
                      const SizedBox(width: 16),
                      _buildPropertyDetail(
                        context,
                        Icons.bathtub,
                        '${property.bathrooms} bath',
                      ),
                      const SizedBox(width: 16),
                      _buildPropertyDetail(
                        context,
                        Icons.square_foot,
                        '${property.squareFeet.toStringAsFixed(0)} sqft',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Edit',
                          onPressed: () => controller.editProperty(property),
                          isOutlined: true,
                          icon: Icons.edit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Delete',
                          onPressed: () => controller.showDeleteConfirmation(
                            property.id,
                            property.title,
                          ),
                          backgroundColor: Colors.red,
                          icon: Icons.delete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDetail(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.mediumGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.home,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No properties found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start by creating your first property listing',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // DISABLED: Create Listing button - buyers cannot create listings anymore
            // CustomButton(
            //   text: 'Create Listing',
            //   onPressed: controller.createNewListing,
            //   icon: Icons.add,
            // ),
          ],
        ),
      ),
    );
  }
}
