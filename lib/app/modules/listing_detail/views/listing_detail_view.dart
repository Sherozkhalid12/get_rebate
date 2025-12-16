import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:getrebate/app/modules/listing_detail/controllers/listing_detail_controller.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/utils/rebate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/pros_cons_chart_widget.dart';

class ListingDetailView extends GetView<ListingDetailController> {
  const ListingDetailView({super.key});

  String _formatMoney(int cents) {
    final int dollars = cents ~/ 100;
    final int remainder = cents % 100;
    final String remStr = remainder.toString().padLeft(2, '0');
    final String withCommas = dollars.toString().replaceAll(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      ',',
    );
    return '\$$withCommas.$remStr';
  }

  @override
  Widget build(BuildContext context) {
    final listing = controller.listing;
    if (listing == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 64,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: 16),
              Text(
                'Listing not found',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.darkGray),
              ),
            ],
          ),
        ),
      );
    }

    final rebate = estimateRebate(
      priceCents: listing.priceCents,
      bacPercent: listing.bacPercent,
      dualAgencyAllowed: listing.dualAgencyAllowed,
    );

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Image
          SliverAppBar(
            expandedHeight: 300.h,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Property Image
                  listing.photoUrls.isNotEmpty
                      ? Image.network(
                          listing.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.lightGray,
                              child: const Icon(
                                Icons.home,
                                size: 64,
                                color: AppTheme.mediumGray,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.lightGray,
                          child: const Icon(
                            Icons.home,
                            size: 64,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {
                    Get.snackbar(
                      'Added to Favorites',
                      'Property saved to your favorites',
                    );
                  },
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Address Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price
                        Text(
                          _formatMoney(listing.priceCents),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w800,
                                fontSize: 32.sp,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppTheme.mediumGray,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                listing.address.toString(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.darkGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Property Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPropertyTag(
                              context,
                              listing.dualAgencyAllowed
                                  ? 'Dual Agency Allowed'
                                  : 'No Dual Agency',
                              listing.dualAgencyAllowed
                                  ? AppTheme.lightGreen
                                  : AppTheme.mediumGray,
                              Icons.handshake,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NAR Compliance Notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Estimated Rebate Range',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If Buyer Agent Compensation is between 2.5% and 3%...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rebate Information Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _RebateCard(
                            title: 'With Your Own Agent',
                            amount: _formatMoney(rebate.ownAgentRebateCents),
                            icon: Icons.person,
                            color: AppTheme.primaryBlue,
                            subtitle: 'Estimated range',
                          ),
                        ),
                        // Only show "With The Listing Agent" card if dual agency is allowed
                        if (listing.dualAgencyAllowed) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RebateCard(
                              title: 'With The Listing Agent',
                              amount: rebate.directRebateMaxCents != null
                                  ? '${_formatMoney(rebate.directRebateCents)} - ${_formatMoney(rebate.directRebateMaxCents!)}'
                                  : _formatMoney(rebate.directRebateCents),
                              icon: Icons.trending_up,
                              color: AppTheme.lightGreen,
                              subtitle:
                                  'Based on ${listing.bacPercent.toStringAsFixed(1)}% BAC',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Disclaimer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Important Notice',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buyer Agent Compensation is negotiable and may vary from property to property and state to state. Once the exact commission percentage is known, you can determine your rebate amount more accurately. Work with your agent for specific details.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.amber.shade900,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pros and Cons Chart
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: ProsConsChartWidget(),
                  ),

                  const SizedBox(height: 24),

                  // Selected Buyer Agent Info (if they have one)
                  Obx(() {
                    final buyerController = Get.find<BuyerController>();
                    if (buyerController.hasSelectedAgent) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildSelectedAgentBanner(context, buyerController.selectedBuyerAgent!),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Primary Action Button
                        CustomButton(
                          text: 'Find Agents Near This Property',
                          onPressed: () {
                            Get.toNamed(
                              '/find-agents',
                              arguments: {
                                'zip': listing.address.zip,
                                'listing': listing,
                              },
                            );
                          },
                          icon: Icons.search,
                          width: double.infinity,
                          height: 56,
                        ),

                        const SizedBox(height: 12),

                        // Secondary Action Button - Contact Listing Agent
                        // Only show if buyer doesn't have a selected agent, or show with warning
                        Obx(() {
                          final buyerController = Get.find<BuyerController>();
                          final hasSelectedAgent = buyerController.hasSelectedAgent;

                          if (hasSelectedAgent) {
                            // Show warning button instead of direct contact
                            return CustomButton(
                              text: 'Contact Listing Agent (Not Recommended)',
                              onPressed: () => _showListingAgentWarningDialog(context, buyerController.selectedBuyerAgent!),
                              icon: Icons.warning_amber_rounded,
                              isOutlined: true,
                              width: double.infinity,
                              height: 56,
                              backgroundColor: Colors.transparent,
                            );
                          } else {
                            // No selected agent, allow direct contact
                            return CustomButton(
                              text: 'Contact Listing Agent',
                              onPressed: () => _showContactListingAgentDialog(context, listing),
                              icon: Icons.call,
                              isOutlined: true,
                              width: double.infinity,
                              height: 56,
                            );
                          }
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTag(
    BuildContext context,
    String text,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAgentBanner(BuildContext context, agent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: AppTheme.lightGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are working with ${agent.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your buyer\'s agent will handle all property inquiries and represent your interests.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showListingAgentWarningDialog(BuildContext context, AgentModel selectedAgent) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Contact Listing Agent?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'You are currently working with ${selectedAgent.name} as your buyer\'s agent.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Why this matters:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildWarningPoint(
                context,
                'Loss of Representation',
                'The listing agent represents the seller, not you. Your buyer\'s agent represents your interests.',
              ),
              const SizedBox(height: 8),
              _buildWarningPoint(
                context,
                'Potential Rebate Impact',
                'Contacting the listing agent directly may affect your rebate eligibility and amount.',
              ),
              const SizedBox(height: 8),
              _buildWarningPoint(
                context,
                'Best Practice',
                'All property inquiries and communications should go through your buyer\'s agent for proper representation.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.mediumGray),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Get.back();
                      // Still allow contact but with full understanding
                      if (controller.listing != null) {
                        _showContactListingAgentDialog(context, controller.listing!);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Continue Anyway'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningPoint(
    BuildContext context,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: AppTheme.mediumGray,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showContactListingAgentDialog(BuildContext context, Listing listing) {
    // Get buyer controller to find agent by ID
    final buyerController = Get.find<BuyerController>();
    final agentId = listing.agentId;
    
    // Try to find the agent in the agents list
    AgentModel? agent;
    try {
      if (buyerController.agents.isNotEmpty && agentId.isNotEmpty) {
        final foundAgents = buyerController.agents.where((a) => a.id == agentId);
        if (foundAgents.isNotEmpty) {
          agent = foundAgents.first;
        }
      }
    } catch (e) {
      // Agent not found, use null
      if (kDebugMode) {
        print('⚠️ Agent with ID $agentId not found in agents list: $e');
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    if (agent?.profileImage != null && agent!.profileImage!.isNotEmpty)
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(agent.profileImage!),
                      )
                    else
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent?.name ?? 'Listing Agent',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (agent?.brokerage != null && agent!.brokerage!.isNotEmpty)
                            Text(
                              agent.brokerage!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Contact Information
                if (agent != null) ...[
                  if (agent!.phone != null && agent!.phone!.isNotEmpty) ...[
                    _buildContactItem(
                      context,
                      Icons.phone,
                      'Phone',
                      agent!.phone!,
                      onTap: () async {
                        final phone = agent!.phone!;
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          Get.snackbar('Error', 'Could not open phone dialer');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildContactItem(
                    context,
                    Icons.email,
                    'Email',
                    agent!.email,
                    onTap: () async {
                      final email = agent!.email;
                      final uri = Uri.parse('mailto:$email');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        Get.snackbar('Error', 'Could not open email client');
                      }
                    },
                  ),
                  if (agent!.licenseNumber.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildContactItem(
                      context,
                      Icons.badge,
                      'License Number',
                      agent!.licenseNumber,
                    ),
                  ],
                  if (agent!.brokerage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildContactItem(
                      context,
                      Icons.business,
                      'Brokerage',
                      agent!.brokerage,
                    ),
                  ],
                  if (agent!.websiteUrl != null && agent!.websiteUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildContactItem(
                      context,
                      Icons.language,
                      'Website',
                      agent!.websiteUrl!,
                      onTap: () async {
                        final website = agent!.websiteUrl!;
                        final uri = Uri.parse(website.startsWith('http') ? website : 'https://$website');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          Get.snackbar('Error', 'Could not open website');
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ] else ...[
                  // Agent not found - show basic info and suggest fetching
                  Text(
                    'Agent Information',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agent details are being loaded...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Agent ID: $agentId',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Action Buttons
                Row(
                  children: [
                    if (agent != null)
                      Expanded(
                        child: CustomButton(
                          text: 'View Profile',
                          onPressed: () {
                            Get.back();
                            Get.toNamed(
                              '/agent-profile',
                              arguments: {'agent': agent},
                            );
                          },
                          icon: Icons.person,
                          isOutlined: true,
                        ),
                      ),
                    if (agent != null) const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Send Message',
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/contact', arguments: {
                            'userId': agent?.id ?? agentId,
                            'userName': agent?.name ?? 'Listing Agent',
                            'userProfilePic': agent?.profileImage,
                            'userRole': 'agent',
                          });
                        },
                        icon: Icons.message,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.mediumGray.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.mediumGray,
              ),
          ],
        ),
      ),
    );
  }
}

class _RebateCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _RebateCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
