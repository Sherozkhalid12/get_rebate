import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer_edit_profile/controllers/loan_officer_edit_profile_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';
import 'package:getrebate/app/models/mortgage_types.dart';

class LoanOfficerEditProfileView extends GetView<LoanOfficerEditProfileController> {
  const LoanOfficerEditProfileView({super.key});

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
          'Edit Profile',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, duration: 300.ms),

              const SizedBox(height: 24),

              // Basic Information
              GradientCard(
                gradientColors: AppTheme.cardGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.black,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: controller.fullNameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: controller.emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      enabled: false, // Email should not be editable
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: controller.phoneController,
                      labelText: 'Phone',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: controller.licenseNumberController,
                      labelText: 'License Number',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: controller.companyNameController,
                      labelText: 'Company Name',
                      prefixIcon: Icons.business_outlined,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 100.ms),

              const SizedBox(height: 24),

              // Company Logo Section
              _buildCompanyLogoSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 150.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 150.ms),

              const SizedBox(height: 24),

              // About Section
              GradientCard(
                gradientColors: AppTheme.cardGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.black,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: controller.bioController,
                      labelText: 'Bio',
                      maxLines: 4,
                      prefixIcon: Icons.description_outlined,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 200.ms),

              const SizedBox(height: 24),

              // Service Areas
              _buildServiceAreasSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 300.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 300.ms),

              const SizedBox(height: 24),

              // Specialty Products
              _buildSpecialtyProductsSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 350.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 350.ms),

              const SizedBox(height: 24),

              // Professional Links
              _buildProfessionalLinksSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 400.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 400.ms),

              const SizedBox(height: 24),

              // Why Pick Me Section
              _buildWhyPickMeSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 250.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 250.ms),

              const SizedBox(height: 24),

              // Licensed States
              _buildLicensedStatesSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 450.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 450.ms),

              const SizedBox(height: 32),

              // Save Button
              Obx(
                () => CustomButton(
                  text: 'Save Changes',
                  onPressed: controller.isLoading
                      ? null
                      : controller.saveProfile,
                  isLoading: controller.isLoading,
                  width: double.infinity,
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 500.ms)
                  .slideY(begin: 0.1, duration: 300.ms, delay: 500.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        children: [
          Text(
            'Profile Picture',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: controller.pickProfilePicture,
            child: Stack(
              children: [
                Obx(() {
                  // Access reactive variables to ensure GetX tracks them
                  // This ensures proper reactivity when currentLoanOfficer changes
                  final selectedPic = controller.selectedProfilePic;
                  final imageUrl = controller.getProfilePictureUrl();
                  
                  // Show selected file if available
                  if (selectedPic != null) {
                    return CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      backgroundImage: Image.file(selectedPic).image,
                      child: null,
                    );
                  }

                  // Show network image if URL exists
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    return CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          cacheKey: imageUrl,
                          memCacheWidth: 240,
                          memCacheHeight: 240,
                          maxWidthDiskCache: 500,
                          maxHeightDiskCache: 500,
                          fadeInDuration: Duration.zero,
                          placeholder: (context, url) => Container(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: AppTheme.primaryBlue,
                            size: 60,
                          ),
                        ),
                      ),
                    );
                  }

                  // Default icon if no image
                  return CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryBlue,
                      size: 60,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              // Access reactive variables to ensure GetX tracks them
              final selectedPic = controller.selectedProfilePic;
              final imageUrl = controller.getProfilePictureUrl();
              return TextButton.icon(
                onPressed: controller.pickProfilePicture,
                icon: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                label: Text(
                  selectedPic != null || (imageUrl != null && imageUrl.isNotEmpty)
                      ? 'Change Photo'
                      : 'Add Photo',
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoSection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        children: [
          Text(
            'Company Logo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: controller.pickCompanyLogo,
            child: Stack(
              children: [
                Obx(() {
                  // Access reactive variables to ensure GetX tracks them
                  // This ensures proper reactivity when currentLoanOfficer changes
                  final selectedLogo = controller.selectedCompanyLogo;
                  final imageUrl = controller.getCompanyLogoUrl();
                  
                  // Show selected file if available
                  if (selectedLogo != null) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: Image.file(selectedLogo).image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }

                  // Show network image if URL exists
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          cacheKey: imageUrl,
                          memCacheWidth: 240,
                          memCacheHeight: 240,
                          maxWidthDiskCache: 500,
                          maxHeightDiskCache: 500,
                          fadeInDuration: Duration.zero,
                          placeholder: (context, url) => Container(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.business,
                            color: AppTheme.primaryBlue,
                            size: 60,
                          ),
                        ),
                      ),
                    );
                  }

                  // Default icon if no image
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppTheme.primaryBlue,
                      size: 60,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () {
              // Access reactive variables to ensure GetX tracks them
              final selectedLogo = controller.selectedCompanyLogo;
              final imageUrl = controller.getCompanyLogoUrl();
              return TextButton.icon(
                onPressed: controller.pickCompanyLogo,
                icon: const Icon(Icons.image, color: AppTheme.primaryBlue),
                label: Text(
                  selectedLogo != null || (imageUrl != null && imageUrl.isNotEmpty)
                      ? 'Change Logo'
                      : 'Add Logo',
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLicensedStatesSection(BuildContext context) {
    final usStates = [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
    ];

    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Licensed States',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all states where you are licensed to practice.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
          const SizedBox(height: 16),
          Obx(
            () {
              // Access the reactive variable directly to ensure GetX tracks it
              final licensedStates = controller.licensedStates;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: usStates.map((state) {
                  // Check selection directly from the reactive list
                  final isSelected = licensedStates.contains(state);
                  return GestureDetector(
                    onTap: () => controller.toggleLicensedState(state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.mediumGray,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        state,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceAreasSection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Areas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter ZIP codes or service areas separated by commas (e.g., 90210, 90211, Los Angeles)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller.serviceAreasController,
            labelText: 'Service Areas',
            prefixIcon: Icons.location_on_outlined,
            hintText: '90210, 90211, Los Angeles',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyProductsSection(BuildContext context) {
    final allProducts = MortgageTypes.getAll();

    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specialty Products',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the mortgage loan types you specialize in.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
          const SizedBox(height: 16),
          Obx(
            () {
              // Access the reactive variable directly to ensure GetX tracks it
              final specialtyProducts = controller.specialtyProducts;
              
              // Build the list of widgets directly in Obx instead of using itemBuilder
              // This ensures GetX can properly track the reactive variable
              return Column(
                children: allProducts.map((product) {
                  final description = MortgageTypes.getDescription(product);
                  // Check selection directly from the reactive list
                  final isSelected = specialtyProducts.contains(product);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => controller.toggleSpecialtyProduct(product),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                controller.toggleSpecialtyProduct(product);
                              },
                              activeColor: AppTheme.primaryBlue,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.mediumGray,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalLinksSection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Links',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            controller: controller.mortgageApplicationUrlController,
            labelText: 'Mortgage Application URL',
            prefixIcon: Icons.link_outlined,
            hintText: 'https://example.com/apply',
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: controller.externalReviewsUrlController,
            labelText: 'External Reviews URL (Google, Zillow, etc.)',
            prefixIcon: Icons.star_outline,
            hintText: 'https://example.com/reviews',
          ),
        ],
      ),
    );
  }

  Widget _buildWhyPickMeSection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: AppTheme.lightGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Why Pick Me',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Help buyers understand why they should choose you. This information will be displayed on your profile.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            controller: controller.yearsOfExperienceController,
            labelText: 'Years of Experience',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.calendar_today_outlined,
            hintText: 'e.g., 10',
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: controller.languagesSpokenController,
            labelText: 'Languages Spoken',
            prefixIcon: Icons.language_outlined,
            hintText: 'e.g., English, Spanish, French',
          ),
          const SizedBox(height: 8),
          Text(
            'Separate multiple languages with commas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: controller.discountsOfferedController,
            labelText: 'Discounts & Special Offers',
            prefixIcon: Icons.local_offer_outlined,
            maxLines: 3,
            hintText: 'e.g., Discounted appraisal, Reduced lender fees, Special first-time buyer programs',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.lightGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These are marketing statements only and are not enforced by the platform. Make sure all offers comply with your lender\'s policies.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGray,
                          fontSize: 11,
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
}

