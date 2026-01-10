import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer_profile/controllers/loan_officer_profile_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class LoanOfficerProfileView extends GetView<LoanOfficerProfileController> {
  const LoanOfficerProfileView({super.key});

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
          'Loan Officer Profile',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.loanOfficer == null) {
            return const Center(
              child: SpinKitFadingCircle(
                color: AppTheme.primaryBlue,
                size: 40,
              ),
            );
          }
          return _buildProfile(context);
        }),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return Column(
      children: [
        // Profile Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Info
                _buildProfileInfo(context),

                // Tabs
                _buildTabs(context),

                // Tab Content
                _buildTabContent(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    final loanOfficer = controller.loanOfficer!;

    return Container(
      color: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image and Basic Info
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.lightGreen.withOpacity(0.1),
                  backgroundImage: (loanOfficer.profileImage != null && 
                                    loanOfficer.profileImage!.isNotEmpty &&
                                    (loanOfficer.profileImage!.startsWith('http://') || 
                                     loanOfficer.profileImage!.startsWith('https://')))
                      ? NetworkImage(loanOfficer.profileImage!)
                      : null,
                  child: (loanOfficer.profileImage == null || 
                         loanOfficer.profileImage!.isEmpty ||
                         (!loanOfficer.profileImage!.startsWith('http://') && 
                          !loanOfficer.profileImage!.startsWith('https://')))
                      ? const Icon(
                          Icons.account_balance,
                          color: AppTheme.lightGreen,
                          size: 40,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loanOfficer.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loanOfficer.company,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppTheme.lightGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${loanOfficer.rating} (${loanOfficer.reviewCount} reviews)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (loanOfficer.companyLogoUrl != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightGreen.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          loanOfficer.companyLogoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance,
                            color: AppTheme.lightGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (loanOfficer.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppTheme.lightGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.lightGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Bio
            if (loanOfficer.bio != null) ...[
              Text(
                loanOfficer.bio!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Rebate Policy
            if (loanOfficer.allowsRebates) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightGreen, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.lightGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rebate-Friendly Lender Verified',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.lightGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This loan officer has confirmed their lender allows real estate commission rebates to be credited to buyers at closing, appearing directly on the Closing Disclosure or Settlement Statement.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.darkGray,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Reviews Section
            _buildReviewsSection(context),

            const SizedBox(height: 20),

            // Action Buttons
            // Primary Action: Create Proposal
            CustomButton(
              text: 'Create Proposal',
              onPressed: () => controller.createProposal(context),
              icon: Icons.description_outlined,
              width: double.infinity,
              backgroundColor: AppTheme.lightGreen,
            ),
            const SizedBox(height: 12),
            if (loanOfficer.mortgageApplicationUrl != null && 
                loanOfficer.mortgageApplicationUrl!.isNotEmpty) ...[
              CustomButton(
                text: 'Apply for a Mortgage',
                onPressed: () async {
                  final mortgageLink = loanOfficer.mortgageApplicationUrl!;
                  
                  // Validate URL format
                  if (mortgageLink.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Mortgage application link is not available',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: AppTheme.white,
                    );
                    return;
                  }
                  
                  try {
                    // Ensure URL has protocol
                    String urlString = mortgageLink;
                    if (!urlString.startsWith('http://') && 
                        !urlString.startsWith('https://')) {
                      urlString = 'https://$urlString';
                    }
                    
                    final url = Uri.parse(urlString);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      Get.snackbar(
                        'Error',
                        'Unable to open mortgage application',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: AppTheme.white,
                      );
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Invalid mortgage application link',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: AppTheme.white,
                    );
                  }
                },
                icon: Icons.link,
                backgroundColor: AppTheme.lightGreen.withOpacity(0.8),
                width: double.infinity,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Contact',
                    onPressed: controller.contactLoanOfficer,
                    icon: Icons.phone,
                    backgroundColor: AppTheme.lightGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Chat',
                    onPressed: controller.startChat,
                    icon: Icons.chat,
                    isOutlined: true,
                    backgroundColor: AppTheme.lightGreen,
                    textColor: AppTheme.lightGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final loanOfficer = controller.loanOfficer!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Reviews (Get a Rebate)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: AppTheme.lightGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Get a Rebate Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (loanOfficer.platformReviewCount > 0) ...[
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < loanOfficer.platformRating.round()
                            ? AppTheme.lightGreen
                            : AppTheme.mediumGray.withOpacity(0.3),
                        size: 20,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${loanOfficer.platformRating.toStringAsFixed(1)} (${loanOfficer.platformReviewCount} ${loanOfficer.platformReviewCount == 1 ? 'review' : 'reviews'})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'From verified closed transactions on Get a Rebate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                Text(
                  'No reviews yet from Get a Rebate transactions',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reviews will appear here after closing transactions through Get a Rebate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        // External Reviews Link
        if (loanOfficer.externalReviewsUrl != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final url = Uri.parse(loanOfficer.externalReviewsUrl!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                Get.snackbar(
                  'Error',
                  'Unable to open reviews link',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: AppTheme.white,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.mediumGray.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'View additional feedback for this loan officer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: Obx(
        () => Row(
          children: [
            Expanded(child: _buildTab(context, 'Overview', 0)),
            Expanded(child: _buildTab(context, 'Reviews', 1)),
            Expanded(child: _buildTab(context, 'Loan Programs', 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, int index) {
    final isSelected = controller.selectedTab == index;

    return GestureDetector(
      onTap: () => controller.setSelectedTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightGreen.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.lightGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? AppTheme.lightGreen : AppTheme.mediumGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return Obx(() {
      switch (controller.selectedTab) {
        case 0:
          return _buildOverview(context);
        case 1:
          return _buildReviews(context);
        case 2:
          return _buildLoanPrograms(context);
        default:
          return _buildOverview(context);
      }
    });
  }

  Widget _buildOverview(BuildContext context) {
    final loanOfficer = controller.loanOfficer!;

    return Container(
      color: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Licensed States
            Text(
              'Licensed States',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: loanOfficer.licensedStates.map((state) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    state,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Service Areas
            Text(
              'Service Areas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: loanOfficer.claimedZipCodes.map((zip) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    zip,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Contact Information
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(context, Icons.email, 'Email', loanOfficer.email),
            if (loanOfficer.phone != null)
              _buildContactItem(
                context,
                Icons.phone,
                'Phone',
                loanOfficer.phone!,
              ),
            _buildContactItem(
              context,
              Icons.business,
              'License Number',
              loanOfficer.licenseNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.lightGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(BuildContext context) {
    final reviews = controller.getReviews();

    return Container(
      color: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews (${reviews.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewItem(context, review);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Map<String, dynamic> review) {
    // Build full profile picture URL if available
    String? profilePicUrl = review['profilePic'];
    if (profilePicUrl != null && profilePicUrl.isNotEmpty && !profilePicUrl.startsWith('http')) {
      final baseUrl = ApiConstants.baseUrl.endsWith('/') 
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      profilePicUrl = '$baseUrl/$profilePicUrl';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Picture or Initial
                profilePicUrl != null && 
                profilePicUrl.isNotEmpty &&
                (profilePicUrl.startsWith('http://') || profilePicUrl.startsWith('https://'))
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(profilePicUrl),
                        backgroundColor: AppTheme.lightGreen.withOpacity(0.1),
                        onBackgroundImageError: (_, __) {},
                        child: const SizedBox(),
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.lightGreen.withOpacity(0.1),
                        child: Text(
                          review['name'][0].toString().toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.lightGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Row(
                        children: [
                          // Star rating with fractional support
                          ...List.generate(5, (index) {
                            final rating = review['rating'] is num 
                                ? (review['rating'] as num).toDouble() 
                                : 0.0;
                            final starIndex = index + 1;
                            
                            if (starIndex <= rating) {
                              // Full star
                              return const Icon(
                                Icons.star,
                                color: AppTheme.lightGreen,
                                size: 16,
                              );
                            } else if (starIndex - rating < 1 && starIndex - rating > 0) {
                              // Half star
                              return const Icon(
                                Icons.star_half,
                                color: AppTheme.lightGreen,
                                size: 16,
                              );
                            } else {
                              // Empty star
                              return const Icon(
                                Icons.star_border,
                                color: AppTheme.mediumGray,
                                size: 16,
                              );
                            }
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review['date'],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.mediumGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanPrograms(BuildContext context) {
    final programs = controller.getLoanPrograms();

    return Container(
      color: AppTheme.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Areas of Expertise & Specialty Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (programs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No specialty products specified',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final program = programs[index];
                  return _buildLoanProgramItem(context, program);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanProgramItem(
    BuildContext context,
    Map<String, dynamic> program,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: AppTheme.lightGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  program['name'],
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
            program['description'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
