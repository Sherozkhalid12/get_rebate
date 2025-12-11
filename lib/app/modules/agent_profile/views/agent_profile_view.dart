import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/agent_profile/controllers/agent_profile_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AgentProfileView extends GetView<AgentProfileController> {
  const AgentProfileView({super.key});

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
          'Agent Profile',
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
          if (controller.agent == null) {
            return const Center(child: CircularProgressIndicator());
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
    final agent = controller.agent!;

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
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  backgroundImage: agent.profileImage != null
                      ? NetworkImage(agent.profileImage!)
                      : null,
                  child: agent.profileImage == null
                      ? const Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
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
                        agent.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent.brokerage,
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
                            '${agent.rating} (${agent.reviewCount} reviews)',
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
                if (agent.companyLogoUrl != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          agent.companyLogoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business_outlined,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (agent.isVerified)
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

            // Video Introduction
            if (agent.videoUrl != null) ...[
              _buildVideoPlayer(context, agent.videoUrl!),
              const SizedBox(height: 20),
            ],

            // Bio
            if (agent.bio != null) ...[
              Text(
                agent.bio!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Areas of Expertise
            if (agent.expertise != null && agent.expertise!.isNotEmpty) ...[
              _buildExpertiseSection(context),
              const SizedBox(height: 20),
            ],

            // Professional Links (always show section)
            _buildProfessionalLinks(context),
            const SizedBox(height: 20),

            // Reviews Section
            _buildReviewsSection(context),

            const SizedBox(height: 20),

            // Action Buttons
            Column(
              children: [
                // Primary Action: Select as My Agent
                CustomButton(
                  text: 'Select as My Agent',
                  onPressed: controller.selectAsMyAgent,
                  icon: Icons.check_circle,
                  width: double.infinity,
                  backgroundColor: AppTheme.lightGreen,
                ),
                const SizedBox(height: 12),
                // Secondary Actions
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Contact',
                        onPressed: controller.contactAgent,
                        icon: Icons.phone,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Chat',
                        onPressed: controller.startChat,
                        icon: Icons.chat,
                        isOutlined: true,
                        backgroundColor: AppTheme.primaryBlue,
                        textColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, String videoUrl) {
    // Extract YouTube video ID from URL
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId == null) {
      // If not a YouTube URL, show a placeholder or link
      return InkWell(
        onTap: () => _launchUrl(videoUrl),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 8),
              Text(
                'Watch Introduction Video',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // For YouTube videos, use youtube_player_flutter
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildExpertiseSection(BuildContext context) {
    final agent = controller.agent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Areas of Expertise',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: agent.expertise!.map((area) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.lightGreen.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    area,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProfessionalLinks(BuildContext context) {
    final agent = controller.agent!;
    final hasLinks = _hasAnyLinks(agent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Links',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Show links if available, otherwise show placeholder
        if (hasLinks) ...[
          if (agent.websiteUrl != null && agent.websiteUrl!.trim().isNotEmpty)
            _buildLinkItem(
              context,
              Icons.language,
              'Website',
              agent.websiteUrl!,
              AppTheme.primaryBlue,
            ),
          if (agent.googleReviewsUrl != null && agent.googleReviewsUrl!.trim().isNotEmpty)
            _buildLinkItem(
              context,
              Icons.reviews,
              'Google Reviews',
              agent.googleReviewsUrl!,
              Colors.red,
            ),
          if (agent.thirdPartyReviewsUrl != null && agent.thirdPartyReviewsUrl!.trim().isNotEmpty)
            _buildLinkItem(
              context,
              Icons.star_rate,
              'Client Reviews',
              agent.thirdPartyReviewsUrl!,
              AppTheme.lightGreen,
            ),
        ] else ...[
          // Show placeholder when no links are available
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mediumGray.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.mediumGray.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link_off, color: AppTheme.mediumGray, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No professional links added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLinkItem(
    BuildContext context,
    IconData icon,
    String label,
    String url,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasAnyLinks(dynamic agent) {
    return (agent.websiteUrl != null && agent.websiteUrl!.trim().isNotEmpty) ||
        (agent.googleReviewsUrl != null && agent.googleReviewsUrl!.trim().isNotEmpty) ||
        (agent.thirdPartyReviewsUrl != null && agent.thirdPartyReviewsUrl!.trim().isNotEmpty);
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      // Validate and clean URL
      String cleanUrl = urlString.trim();
      
      // Add https:// if no protocol is specified
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      
      // Parse URL
      final url = Uri.parse(cleanUrl);
      
      // Validate URL has a host
      if (url.host.isEmpty) {
        _showErrorSnackbar('Invalid URL format', 'Please check the link and try again');
        return;
      }
      
      // Check if URL can be launched
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackbar('Cannot open link', 'No app available to handle this URL');
      }
    } on FormatException catch (e) {
      _showErrorSnackbar('Invalid URL', 'The link format is not valid: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to open link: ${e.toString()}');
    }
  }
  
  /// Safely shows error snackbar without causing overlay errors
  void _showErrorSnackbar(String title, String message) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: AppTheme.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // If snackbar fails (overlay error), just print to console
      print('⚠️ Error showing snackbar: $title - $message');
    }
  }

  Widget _buildReviewsSection(BuildContext context) {
    final agent = controller.agent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Reviews (Get a Rebate)
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
                  Icon(Icons.verified, color: AppTheme.primaryBlue, size: 20),
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
              if (agent.platformReviewCount > 0) ...[
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < agent.platformRating.round()
                            ? AppTheme.primaryBlue
                            : AppTheme.mediumGray.withOpacity(0.3),
                        size: 20,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${agent.platformRating.toStringAsFixed(1)} (${agent.platformReviewCount} ${agent.platformReviewCount == 1 ? 'review' : 'reviews'})',
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

        // View All Platform Reviews Link
        if (agent.platformReviewCount > 0) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _viewAllPlatformReviews(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.rate_review,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'View all ${agent.platformReviewCount} Get a Rebate ${agent.platformReviewCount == 1 ? 'review' : 'reviews'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
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
            Expanded(child: _buildTab(context, 'Properties', 2)),
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
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
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
          return _buildProperties(context);
        default:
          return _buildOverview(context);
      }
    });
  }

  Widget _buildOverview(BuildContext context) {
    final agent = controller.agent!;

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
              children: agent.licensedStates.map((state) {
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
                    state,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Service Areas (show serviceAreas if available, otherwise show claimedZipCodes)
            if (agent.serviceAreas != null && agent.serviceAreas!.isNotEmpty) ...[
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
                children: agent.serviceAreas!.map((area) {
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
                      area,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else if (agent.claimedZipCodes.isNotEmpty) ...[
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
                children: agent.claimedZipCodes.map((zip) {
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
                      zip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

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
            _buildContactItem(context, Icons.email, 'Email', agent.email),
            if (agent.phone != null)
              _buildContactItem(context, Icons.phone, 'Phone', agent.phone!),
            _buildContactItem(
              context,
              Icons.business,
              'License Number',
              agent.licenseNumber,
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
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
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
                profilePicUrl != null && profilePicUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(profilePicUrl),
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        onBackgroundImageError: (_, __) {
                          // Fallback handled by errorBuilder in child
                        },
                        child: const SizedBox(), // Empty child for error fallback
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        child: Text(
                          review['name'][0].toString().toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryBlue,
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

  Widget _buildProperties(BuildContext context) {
    return Obx(() {
      final properties = controller.getProperties();
      final isLoading = controller.isLoadingProperties;

      return Container(
        color: AppTheme.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Properties (${properties.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Loading state
              if (isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryBlue),
                        const SizedBox(height: 16),
                        Text(
                          'Loading properties...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // Empty state
              else if (properties.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 64,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Properties Listed',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This agent hasn\'t listed any properties yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              // Properties list
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return _buildPropertyItem(context, property);
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPropertyItem(
    BuildContext context,
    Map<String, dynamic> property,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image with Tap
          InkWell(
            onTap: () => _viewPropertyDetails(property),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: property['image'] != null && property['image'].toString().isNotEmpty
                      ? Image.network(
                          property['image'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: AppTheme.lightGray,
                              child: const Center(
                                child: Icon(
                                  Icons.home_work,
                                  size: 64,
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          color: AppTheme.lightGray,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: AppTheme.mediumGray,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No Image',
                                  style: TextStyle(
                                    color: AppTheme.mediumGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                // Tap indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 16,
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
                Text(
                  property['address'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property['price'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.bed, color: AppTheme.mediumGray, size: 16),
                    const SizedBox(width: 4),
                    Text('${property['beds']} beds'),
                    const SizedBox(width: 16),
                    Icon(Icons.bathtub, color: AppTheme.mediumGray, size: 16),
                    const SizedBox(width: 4),
                    Text('${property['baths']} baths'),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.square_foot,
                      color: AppTheme.mediumGray,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('${property['sqft']} sqft'),
                  ],
                ),
                const SizedBox(height: 12),

                // Status and Buy Button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: property['status'] == 'For Sale'
                            ? AppTheme.lightGreen.withOpacity(0.1)
                            : AppTheme.mediumGray.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        property['status'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: property['status'] == 'For Sale'
                              ? AppTheme.lightGreen
                              : AppTheme.mediumGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (property['status'] == 'For Sale')
                      ElevatedButton(
                        onPressed: () => _openBuyerLeadForm(property),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Buy'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewPropertyDetails(Map<String, dynamic> property) {
    Get.toNamed('/property-detail', arguments: property);
  }

  void _openBuyerLeadForm(Map<String, dynamic> property) {
    Get.toNamed(
      '/buyer-lead-form',
      arguments: {'property': property, 'agent': controller.agent},
    );
  }

  void _viewAllPlatformReviews() {
    Get.toNamed('/agent-reviews', arguments: {'agentId': controller.agent!.id});
  }
}
