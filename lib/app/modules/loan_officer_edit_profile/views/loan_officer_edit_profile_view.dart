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
import 'package:webview_flutter/webview_flutter.dart';

class LoanOfficerEditProfileView
    extends GetView<LoanOfficerEditProfileController> {
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
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 200.ms),

              const SizedBox(height: 24),

              // Office ZIP
              _buildServiceAreasSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 260.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 260.ms),

              const SizedBox(height: 24),

              // Specialty Products
              _buildSpecialtyProductsSection(context)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 300.ms)
                  .slideY(begin: -0.1, duration: 300.ms, delay: 300.ms),

              const SizedBox(height: 24),

              // Video Introduction
              _buildVideoSection(context)
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
          Obx(() {
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
          }),
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
          Obx(() {
            // Access reactive variables to ensure GetX tracks them
            final selectedLogo = controller.selectedCompanyLogo;
            final imageUrl = controller.getCompanyLogoUrl();
            return TextButton.icon(
              onPressed: controller.pickCompanyLogo,
              icon: const Icon(Icons.image, color: AppTheme.primaryBlue),
              label: Text(
                selectedLogo != null ||
                        (imageUrl != null && imageUrl.isNotEmpty)
                    ? 'Change Logo'
                    : 'Add Logo',
                style: const TextStyle(color: AppTheme.primaryBlue),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLicensedStatesSection(BuildContext context) {
    // Only include states where rebates are allowed
    // CRITICAL: Only these states are allowed - do not add others without approval
    final usStates = [
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DC',
      'DE',
      'FL',
      'GA',
      'HI',
      'ID',
      'IL',
      'IN',
      'KY',
      'ME',
      'MD',
      'MA',
      'MI',
      'MN',
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
      'PA',
      'RI',
      'SC',
      'SD',
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
            'Select all states where you are licensed to practice.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 16),
          Obx(() {
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
                        color: isSelected ? AppTheme.white : AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
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
            'Office ZIP Code',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the office ZIP code you used during signup.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller.officeZipController,
            labelText: 'Office ZIP Code',
            prefixIcon: Icons.location_on_outlined,
            keyboardType: TextInputType.number,
            maxLength: 5,
            hintText: 'e.g., 90210',
            suffixIcon: IconButton(
              icon: Icon(Icons.my_location, color: AppTheme.primaryBlue, size: 20),
              onPressed: controller.useCurrentLocationForZip,
            ),
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
            'Areas of Expertise & Specialty Products (Select all that apply)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the mortgage types you specialize in. Buyers will see descriptions of each type.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allProducts.map((product) {
                final isSelected = controller.specialtyProducts.contains(product);
                return GestureDetector(
                  onTap: () => controller.toggleSpecialtyProduct(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightGreen.withOpacity(0.1)
                          : AppTheme.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightGreen
                            : AppTheme.mediumGray.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          size: 16,
                          color: isSelected
                              ? AppTheme.lightGreen
                              : AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            product,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? AppTheme.lightGreen
                                      : AppTheme.darkGray,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
            controller: controller.websiteUrlController,
            labelText: 'Website URL',
            prefixIcon: Icons.language_outlined,
            hintText: 'https://yourwebsite.com',
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: controller.mortgageApplicationUrlController,
            labelText: 'Mortgage Application URL',
            prefixIcon: Icons.link_outlined,
            hintText: 'https://example.com/apply',
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Open Mortgage Link',
            isOutlined: true,
            onPressed: () {
              final rawUrl = controller.mortgageApplicationUrlController.text
                  .trim();
              if (rawUrl.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please enter a mortgage application URL first.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final normalizedUrl = _normalizeUrl(rawUrl);
              final uri = Uri.tryParse(normalizedUrl);
              if (uri == null || !uri.isAbsolute) {
                Get.snackbar(
                  'Error',
                  'Please enter a valid URL.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              Get.to(
                () => _MortgageWebView(url: normalizedUrl),
                fullscreenDialog: true,
              );
            },
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

  Widget _buildVideoSection(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Introduction',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a short intro video to match your signup profile.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final hasVideo =
                controller.selectedVideo != null ||
                (controller.existingVideoUrl?.isNotEmpty ?? false);
            return Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: hasVideo ? 'Change Video' : 'Upload Video',
                    isOutlined: true,
                    onPressed: controller.pickVideo,
                  ),
                ),
                if (hasVideo) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: controller.removeVideo,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}
String _normalizeUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return 'https://$url';
}

class _MortgageWebView extends StatefulWidget {
  final String url;

  const _MortgageWebView({required this.url});

  @override
  State<_MortgageWebView> createState() => _MortgageWebViewState();
}

class _MortgageWebViewState extends State<_MortgageWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mortgage Application')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
