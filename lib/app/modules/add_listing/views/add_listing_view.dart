import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/add_listing/controllers/add_listing_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class AddListingView extends GetView<AddListingController> {
  const AddListingView({super.key});

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
          'Add New Listing',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.lightGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_outlined,
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Listing',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppTheme.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the details below to add your property listing',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.mediumGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader(context, 'Basic Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.titleController,
                labelText: 'Property Title',
                hintText: 'e.g., Beautiful 3BR Condo in Manhattan',
                maxLines: 1,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.descriptionController,
                labelText: 'Description',
                hintText: 'Describe your property in detail...',
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Price Information Section
              _buildSectionHeader(context, 'Price Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.priceController,
                labelText: 'Price',
                hintText: 'e.g., 1250000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),

              const SizedBox(height: 16),

              // Buyer Agent Commission (BAC)
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Buyer Agent Commission (BAC): ${controller.bacPercent.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.black,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showBacPercentageInfo(context),
                          child: Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: controller.bacPercent,
                      min: 0.5,
                      max: 5.0,
                      divisions: 45,
                      activeColor: AppTheme.primaryBlue,
                      inactiveColor: AppTheme.lightGray,
                      onChanged: controller.updateBacPercent,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0.5%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '5.0%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRebateTierReference(context),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Location Information Section
              _buildSectionHeader(context, 'Location Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.addressController,
                labelText: 'Street Address',
                hintText: 'e.g., 123 Park Avenue',
                maxLines: 1,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: controller.cityController,
                      labelText: 'City',
                      hintText: 'e.g., New York',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: controller.stateController,
                      labelText: 'State',
                      hintText: 'e.g., NY',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: controller.zipCodeController,
                      labelText: 'ZIP',
                      hintText: '10001',
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Listing Agent Verification Section (CRITICAL)
              _buildSectionHeader(context, 'Listing Agent Verification'),
              const SizedBox(height: 8),
              Text(
                'This information is critical for proper commission structure and rebate calculations',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              // Are you the listing agent question
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.isListingAgent == null
                          ? Colors.red.withOpacity(0.3)
                          : AppTheme.lightGray.withOpacity(0.5),
                      width: controller.isListingAgent == null ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: controller.isListingAgent == null
                                ? Colors.red
                                : AppTheme.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Are you the listing agent?',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (controller.isListingAgent == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'REQUIRED',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you the official listing agent representing the seller for this property?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAgentOption(
                              context,
                              'Yes',
                              'I am the listing agent',
                              true,
                              controller.isListingAgent == true,
                              () => controller.setIsListingAgent(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAgentOption(
                              context,
                              'No',
                              'I\'m listing another agent\'s property',
                              false,
                              controller.isListingAgent == false,
                              () => controller.setIsListingAgent(false),
                            ),
                          ),
                        ],
                      ),
                      if (controller.isListingAgent == false) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Note: Dual agency will not be available, and buyers may not receive the maximum rebate since you won\'t receive the full commission.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional Options Section
              _buildSectionHeader(context, 'Additional Options'),
              const SizedBox(height: 16),

              // Dual Agency Toggle
              Obx(
                () => Opacity(
                  opacity: controller.isListingAgent == false ? 0.5 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightGray.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dual Agency Allowed',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.isListingAgent == false
                                    ? 'Not available (you are not the listing agent)'
                                    : 'Allow representing both buyer and seller',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: controller.isListingAgent == false
                                          ? Colors.red
                                          : AppTheme.mediumGray,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: controller.dualAgencyAllowed,
                          onChanged: controller.isListingAgent == false
                              ? null
                              : (value) => controller.toggleDualAgency(),
                          activeColor: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dual Agency Rebate Question and Commission Slider
              Obx(
                () =>
                    controller.isListingAgent == true &&
                        controller.dualAgencyAllowed
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppTheme.primaryBlue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Would you agree to offer a larger rebate if you receive both the listing agent commission and buyer agent commission in a dual agency transaction?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: controller
                                            .toggleAgreeToLargerRebate,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                controller
                                                    .agreeToLargerRebateForDualAgency
                                                ? AppTheme.lightGreen
                                                      .withOpacity(0.1)
                                                : AppTheme.lightGray
                                                      .withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  controller
                                                      .agreeToLargerRebateForDualAgency
                                                  ? AppTheme.lightGreen
                                                  : AppTheme.lightGray,
                                              width:
                                                  controller
                                                      .agreeToLargerRebateForDualAgency
                                                  ? 2
                                                  : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                controller
                                                        .agreeToLargerRebateForDualAgency
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                color:
                                                    controller
                                                        .agreeToLargerRebateForDualAgency
                                                    ? AppTheme.lightGreen
                                                    : AppTheme.mediumGray,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Yes, I agree',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      color: AppTheme.black,
                                                      fontWeight:
                                                          controller
                                                              .agreeToLargerRebateForDualAgency
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (controller
                                    .agreeToLargerRebateForDualAgency) ...[
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Text(
                                        'Total Commission (Both Sides): ${controller.dualAgencyTotalCommissionPercent.toStringAsFixed(1)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            _showDualAgencyCommissionInfo(
                                              context,
                                            ),
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 20,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    value: controller
                                        .dualAgencyTotalCommissionPercent,
                                    min: 1.5,
                                    max: 8.0,
                                    divisions: 65,
                                    activeColor: AppTheme.primaryBlue,
                                    inactiveColor: AppTheme.lightGray,
                                    onChanged: controller
                                        .updateDualAgencyTotalCommission,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '1.5%',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      Text(
                                        '8.0%',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGreen.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          size: 16,
                                          color: AppTheme.lightGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This represents the total commission you would receive if representing both buyer and seller in a dual agency transaction.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.darkGray,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Photos Section
              _buildSectionHeader(context, 'Property Photos'),
              const SizedBox(height: 16),

              Obx(
                () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightGray.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (controller.selectedPhotos.isEmpty) ...[
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.mediumGray.withOpacity(0.3),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: AppTheme.mediumGray,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Property Photos',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.mediumGray),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to add up to 10 photos',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.mediumGray),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: controller.selectedPhotos.length,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.lightGray,
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      controller.selectedPhotos[index],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          controller.removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Add Photos',
                        onPressed: () => _showAddPhotoDialog(context),
                        icon: Icons.add_photo_alternate_outlined,
                        isOutlined: true,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Open Houses Section
              _buildSectionHeader(context, 'Open Houses'),
              const SizedBox(height: 8),
              Text(
                'Add open house dates and times. Buyers can search for open houses by location.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 16),

              Obx(
                () => Column(
                  children: [
                    // List existing open houses
                    ...List.generate(
                      controller.openHouses.length,
                      (index) =>
                          _buildOpenHouseEntry(context, controller, index),
                    ),
                    // Add Another Open House button
                    if (controller.canAddMoreOpenHouses)
                      CustomButton(
                        text: 'Add Another Open House',
                        onPressed: controller.addOpenHouse,
                        icon: Icons.add_circle_outline,
                        isOutlined: true,
                        width: double.infinity,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Maximum of 4 open houses allowed',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              Obx(
                () => CustomButton(
                  text: controller.isLoading
                      ? 'Adding Listing...'
                      : 'Add Listing',
                  onPressed: controller.isLoading
                      ? null
                      : controller.submitListing,
                  icon: controller.isLoading ? null : Icons.add_circle_outline,
                  width: double.infinity,
                  height: 56,
                ),
              ),

              const SizedBox(height: 20),
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
        color: AppTheme.black,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildRebateTierReference(BuildContext context) {
    final tiers = [
      {
        'label': 'Tier 1',
        'range': '4.0% or more',
        'rebate': '40% of commission',
      },
      {
        'label': 'Tier 2',
        'range': '3.01% - 3.99%',
        'rebate': '35% of commission',
      },
      {
        'label': 'Tier 3',
        'range': '2.5% - 3.0%',
        'rebate': '30% of commission',
      },
      {
        'label': 'Tier 4',
        'range': '2.0% - 2.49%',
        'rebate': '25% of commission',
      },
      {
        'label': 'Tier 5',
        'range': '1.5% - 1.99%',
        'rebate': '20% of commission',
      },
      {
        'label': 'Tier 6',
        'range': '0.25% - 1.49%',
        'rebate': '10% of commission',
      },
      {
        'label': 'Tier 7',
        'range': '0% - 0.24%',
        'rebate': '0% (rebate not available)',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.stacked_bar_chart,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rebate Tier Reference',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use this chart to estimate the rebate owed when you set a Buyer Agent Commission (BAC) for buyers or a Listing Agent Commission (LAC) when you plan to rebate a seller.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.darkGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...tiers.map(
            (tier) => _buildTierRow(
              context,
              tier['label']!,
              tier['range']!,
              tier['rebate']!,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For properties priced at \$700,000 or more, tiers 5 and 6 do not apply. The minimum rebate in those cases is Tier 4 (25% of commission).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(
    BuildContext context,
    String tier,
    String range,
    String rebate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tier,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              range,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            rebate,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentOption(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (value ? AppTheme.lightGreen : Colors.orange).withOpacity(0.1)
              : AppTheme.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (value ? AppTheme.lightGreen : Colors.orange)
                : AppTheme.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: isSelected
                  ? (value ? AppTheme.lightGreen : Colors.orange)
                  : AppTheme.mediumGray,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppTheme.black : AppTheme.mediumGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                Navigator.pop(context);
                await _pickImages(context, picker, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImages(context, picker, ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
            SnackbarHelper.showInfo('You can add up to 10 photos', title: 'Limit Reached');
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
              SnackbarHelper.showInfo('You can add up to 10 photos', title: 'Limit Reached');
            }
          }
        } catch (e2) {
          SnackbarHelper.showError('Failed to pick image: ${e2.toString()}');
        }
      } else {
        SnackbarHelper.showError('Failed to pick images: ${e.toString()}');
      }
    }
  }

  void _showBacPercentageInfo(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 8),
            const Expanded(child: Text('Buyer Agent Commission (BAC)')),
          ],
        ),
        content: const Text(
          'This will be used to show potential buyers a rebate range. The actual Buyer Agent Commission (BAC) will not be shared with potential buyers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showDualAgencyCommissionInfo(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 8),
            const Expanded(child: Text('Total Commission (Both Sides)')),
          ],
        ),
        content: const Text(
          'This will be used to show potential buyers a potential rebate if they work directly with the listing agent. The actual Listing Agent Commission (LAC) will not be shared with potential buyers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _buildOpenHouseEntry(
    BuildContext context,
    AddListingController controller,
    int index,
  ) {
    final openHouse = controller.openHouses[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightGray.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number and delete button
          Row(
            children: [
              Text(
                'Open House #${index + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.removeOpenHouse(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date picker
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: openHouse.date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate != null) {
                controller.updateOpenHouseDate(index, pickedDate);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Date: ${_formatDate(openHouse.date)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.black),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Start time and end time
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: openHouse.startTime,
                    );
                    if (pickedTime != null) {
                      controller.updateOpenHouseStartTime(index, pickedTime);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.mediumGray.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'From: ${openHouse.startTime.format(context)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: openHouse.endTime,
                    );
                    if (pickedTime != null) {
                      controller.updateOpenHouseEndTime(index, pickedTime);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.mediumGray.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'To: ${openHouse.endTime.format(context)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Notes field
          CustomTextField(
            controller: TextEditingController(text: openHouse.notes),
            labelText:
                'Special Notes (e.g., food provided, parking info, etc.)',
            hintText: 'Enter any special notes about this open house...',
            maxLines: 2,
            onChanged: (value) => controller.updateOpenHouseNotes(index, value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
