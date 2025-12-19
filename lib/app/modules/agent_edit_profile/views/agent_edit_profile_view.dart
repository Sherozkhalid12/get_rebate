import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/agent_edit_profile/controllers/agent_edit_profile_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';
import 'package:getrebate/app/models/agent_expertise.dart';

class AgentEditProfileView extends GetView<AgentEditProfileController> {
  const AgentEditProfileView({super.key});

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
          onPressed: () => Navigator.pop(context),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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

              // About Section
              GradientCard(
                    gradientColors: AppTheme.cardGradient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: controller.descriptionController,
                          labelText: 'Description',
                          maxLines: 4,
                          prefixIcon: Icons.text_fields_outlined,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 200.ms),

              const SizedBox(height: 24),

              // Dual Agency Questions
              _buildDualAgencySection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 300.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 300.ms),

              const SizedBox(height: 24),

              // Service Areas
              _buildServiceAreasSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 400.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 400.ms),

              const SizedBox(height: 24),

              // Areas of Expertise
              _buildAreasOfExpertiseSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 450.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 450.ms),

              const SizedBox(height: 24),

              // Professional Links
              _buildProfessionalLinksSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 500.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 500.ms),

              const SizedBox(height: 24),

              // Licensed States
              _buildLicensedStatesSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 550.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 550.ms),

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
    return Obx(
      () => GradientCard(
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
                    // Show selected file if available
                    if (controller.selectedProfilePic != null) {
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        backgroundImage: Image.file(
                          controller.selectedProfilePic!,
                        ).image,
                        child: null,
                      );
                    }

                    // Show network image if URL exists
                    final imageUrl = controller.profilePictureUrl;
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
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
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
                  if (controller.selectedProfilePic != null ||
                      (controller.profilePictureUrl != null &&
                          controller.profilePictureUrl!.isNotEmpty))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => controller.removeProfilePicture(),
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
            ),
            const SizedBox(height: 12),
            Obx(
              () => TextButton.icon(
                onPressed: controller.pickProfilePicture,
                icon: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                label: Text(
                  controller.selectedProfilePic != null ||
                          (controller.profilePictureUrl != null &&
                              controller.profilePictureUrl!.isNotEmpty)
                      ? 'Change Photo'
                      : 'Add Photo',
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualAgencySection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dual Agency Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dual Agency happens when the buyer is working with an agent from the same Brokerage that has the property listed for sale.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 20),

          Text(
            'Is Dual Agency Allowed in your State?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildYesNoButton(
                    context,
                    'Yes',
                    controller.dualAgencyState == true,
                    () => controller.setDualAgencyState(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildYesNoButton(
                    context,
                    'No',
                    controller.dualAgencyState == false,
                    () => controller.setDualAgencyState(false),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Is Dual Agency Allowed at your Brokerage?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildYesNoButton(
                    context,
                    'Yes',
                    controller.dualAgencyBrokerage == true,
                    () => controller.setDualAgencyBrokerage(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildYesNoButton(
                    context,
                    'No',
                    controller.dualAgencyBrokerage == false,
                    () => controller.setDualAgencyBrokerage(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoButton(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? AppTheme.white : AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLicensedStatesSection(BuildContext context) {
    final usStates = [
      'AL',
      'AK',
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DE',
      'FL',
      'GA',
      'HI',
      'ID',
      'IL',
      'IN',
      'IA',
      'KS',
      'KY',
      'LA',
      'ME',
      'MD',
      'MA',
      'MI',
      'MN',
      'MS',
      'MO',
      'MT',
      'NE',
      'NV',
      'NH',
      'NJ',
      'NM',
      'NY',
      'NC',
      'ND',
      'OH',
      'OK',
      'OR',
      'PA',
      'RI',
      'SC',
      'SD',
      'TN',
      'TX',
      'UT',
      'VT',
      'VA',
      'WA',
      'WV',
      'WI',
      'WY',
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
            'Select all states where you are licensed to practice real estate.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: usStates.map((state) {
                final isSelected = controller.licensedStates.contains(state);
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
                        color: isSelected ? AppTheme.white : AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
            'Enter service areas separated by commas (e.g., Los Angeles, San Diego, Miami)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller.serviceAreasController,
            labelText: 'Service Areas',
            prefixIcon: Icons.location_on_outlined,
            hintText: 'Los Angeles, San Diego, Miami',
          ),
        ],
      ),
    );
  }

  Widget _buildAreasOfExpertiseSection(BuildContext context) {
    final expertiseOptions = AgentExpertise.getAll();

    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Areas of Expertise',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all areas where you have expertise',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expertiseOptions.map((expertise) {
                final isSelected = controller.isAreaOfExpertiseSelected(
                  expertise,
                );
                return GestureDetector(
                  onTap: () => controller.toggleAreaOfExpertise(expertise),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: isSelected
                              ? AppTheme.white
                              : AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          expertise,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isSelected
                                    ? AppTheme.white
                                    : AppTheme.darkGray,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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
            controller: controller.websiteLinkController,
            labelText: 'Website Link',
            prefixIcon: Icons.language_outlined,
            keyboardType: TextInputType.url,
            hintText: 'https://yourwebsite.com',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller.googleReviewsLinkController,
            labelText: 'Google Reviews Link',
            prefixIcon: Icons.reviews_outlined,
            keyboardType: TextInputType.url,
            hintText: 'https://google.com/business/reviews',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller.thirdPartReviewLinkController,
            labelText: 'Third Party Reviews Link',
            prefixIcon: Icons.star_rate_outlined,
            keyboardType: TextInputType.url,
            hintText: 'https://realtor.com/reviews',
          ),
        ],
      ),
    );
  }
}
