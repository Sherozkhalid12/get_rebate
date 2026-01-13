import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getrebate/app/modules/listing_detail/controllers/listing_detail_controller.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/utils/rebate.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/pros_cons_chart_widget.dart';
import 'package:getrebate/app/services/agent_service.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Allow horizontal scrolls to pass through
          if (notification is ScrollUpdateNotification) {
            final delta = notification.scrollDelta ?? 0;
            // If horizontal scroll detected, don't consume the notification
            if (delta.abs() > 0 && notification.metrics.axis == Axis.horizontal) {
              return false;
            }
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with Image Slider
            SliverAppBar(
              expandedHeight: 400.h,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: LayoutBuilder(
                  builder: (context, constraints) {
                    final carouselHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 400.h;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image Carousel Slider
                        if (listing.photoUrls.isNotEmpty)
                          SizedBox(
                            width: constraints.maxWidth,
                            height: carouselHeight,
                            child: CarouselSlider.builder(
                              carouselController: controller.carouselController,
                              itemCount: listing.photoUrls.length,
                              itemBuilder: (context, index, realIndex) {
                                return GestureDetector(
                                  onTap: () => _showFullScreenImageSlider(context, listing.photoUrls, controller.currentImageIndex),
                                  child: Builder(
                                    builder: (context) {
                                      final imageUrl = listing.photoUrls[index];
                                      if (kDebugMode) {
                                        print('🖼️ Listing Detail - Rendering image $index with URL: $imageUrl');
                                      }
                                      return CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (context, url) => Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          color: AppTheme.lightGray,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          if (kDebugMode) {
                                            print('❌ Listing Detail - Image load error for URL: $url');
                                            print('   Error: $error');
                                            print('   Error type: ${error.runtimeType}');
                                          }
                                          return Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            color: AppTheme.lightGray,
                                            child: const Icon(
                                              Icons.home,
                                              size: 64,
                                              color: AppTheme.mediumGray,
                                            ),
                                          );
                                        },
                                        httpHeaders: const {
                                          'Accept': 'image/*',
                                        },
                                        maxWidthDiskCache: 2000,
                                        maxHeightDiskCache: 2000,
                                      );
                                    },
                                  ),
                                );
                              },
                              options: CarouselOptions(
                                height: carouselHeight,
                                viewportFraction: 1.0,
                                enableInfiniteScroll: listing.photoUrls.length > 1,
                                autoPlay: false,
                                enlargeCenterPage: false,
                                onPageChanged: (index, reason) {
                                  controller.onImageChanged(index);
                                },
                                scrollPhysics: const PageScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                pageSnapping: true,
                                padEnds: false,
                                disableCenter: false,
                                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                              ),
                            ),
                          )
                      else
                        Container(
                          width: constraints.maxWidth,
                          height: carouselHeight,
                          color: AppTheme.lightGray,
                          child: const Icon(
                            Icons.home,
                            size: 64,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      // Gradient Overlay - use IgnorePointer to allow touches to pass through
                      IgnorePointer(
                        child: Container(
                          width: constraints.maxWidth,
                          height: carouselHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Page Indicators
                      if (listing.photoUrls.length > 1)
                        Positioned(
                          bottom: 20.h,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                listing.photoUrls.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  width: controller.currentImageIndex == index ? 24.w : 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    color: controller.currentImageIndex == index
                                        ? AppTheme.white
                                        : AppTheme.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                          ),
                        ),
                      // Image Counter
                      if (listing.photoUrls.length > 1)
                        Positioned(
                          top: 60.h,
                          right: 16.w,
                          child: IgnorePointer(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Obx(() => Text(
                                '${controller.currentImageIndex + 1} / ${listing.photoUrls.length}',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              // Full Screen Button
              if (listing.photoUrls.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () => _showFullScreenImageSlider(context, listing.photoUrls, controller.currentImageIndex),
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
                            final zipCode = listing.address.zip;
                            if (kDebugMode) {
                              print('🔍 Listing Detail - Navigating to Find Agents');
                              print('   Listing ID: ${listing.id}');
                              print('   Listing Address: ${listing.address.toString()}');
                              print('   ZIP Code: $zipCode');
                            }
                            Get.toNamed(
                              '/find-agents',
                              arguments: {
                                'zip': zipCode,
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
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.mediumGray),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
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

  void _showContactListingAgentDialog(BuildContext context, Listing listing) async {
    final agentId = listing.agentId;
    final agentService = AgentService();
    
    // Show dialog with loading state
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: FutureBuilder<AgentModel?>(
            future: agentService.getAgentById(agentId),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Loading Agent Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SpinKitFadingCircle(
                      color: AppTheme.primaryBlue,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fetching agent information...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                );
              }

              // Error state
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Listing Agent',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load agent details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              // Success state - agent found
              final agent = snapshot.data;
              if (agent == null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Listing Agent',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      Icons.person_outline,
                      color: AppTheme.mediumGray,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Agent information not available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              // Agent details loaded successfully
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with agent info
                    Row(
                      children: [
                        if (agent.profileImage != null && agent.profileImage!.isNotEmpty)
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              agent.profileImage!.startsWith('http')
                                  ? agent.profileImage!
                                  : '${ApiConstants.baseUrl}/${agent.profileImage!.replaceAll('\\', '/').replaceFirst('/', '')}',
                            ),
                            onBackgroundImageError: (_, __) {},
                          )
                        else
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.primaryBlue,
                              size: 28,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agent.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (agent.brokerage != null && agent.brokerage!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  agent.brokerage!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Bio section
                    if (agent.bio != null && agent.bio!.isNotEmpty) ...[
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        agent.bio!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGray,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Contact Information Section
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone - Clickable
                    if (agent.phone != null && agent.phone!.isNotEmpty) ...[
                      _buildContactItem(
                        context,
                        Icons.phone_rounded,
                        'Phone',
                        agent.phone!,
                        onTap: () async {
                          try {
                            // Record contact when user taps to call
                            try {
                              final agentService = AgentService();
                              await agentService.recordContact(agent.id);
                              if (kDebugMode) {
                                print('📞 Recording contact for agent: ${agent.id}');
                              }
                            } catch (e) {
                              if (kDebugMode) {
                                print('⚠️ Error recording contact: $e');
                              }
                              // Don't block call if contact recording fails
                            }
                            
                            // Clean phone number (remove spaces, dashes, etc.)
                            final cleanPhone = agent.phone!.replaceAll(RegExp(r'[^\d+]'), '');
                            final uri = Uri.parse('tel:$cleanPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              SnackbarHelper.showError('Could not open phone dialer');
                            }
                          } catch (e) {
                            SnackbarHelper.showError('Could not open phone dialer: ${e.toString()}');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Email - Clickable
                    _buildContactItem(
                      context,
                      Icons.email_rounded,
                      'Email',
                      agent.email,
                      onTap: () async {
                        try {
                          final uri = Uri.parse('mailto:${agent.email}?subject=Inquiry about Property Listing');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            SnackbarHelper.showError('Could not open email client');
                          }
                        } catch (e) {
                          SnackbarHelper.showError('Could not open email client: ${e.toString()}');
                        }
                      },
                    ),
                    
                    // License Number
                    if (agent.licenseNumber.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context,
                        Icons.badge_rounded,
                        'License Number',
                        agent.licenseNumber,
                      ),
                    ],
                    
                    // Brokerage
                    if (agent.brokerage != null && agent.brokerage!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context,
                        Icons.business_rounded,
                        'Brokerage',
                        agent.brokerage!,
                      ),
                    ],
                    
                    // Licensed States
                    if (agent.licensedStates.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context,
                        Icons.location_on_rounded,
                        'Licensed States',
                        agent.licensedStates.join(', '),
                      ),
                    ],
                    
                    // Website - Clickable
                    if (agent.websiteUrl != null && agent.websiteUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context,
                        Icons.language_rounded,
                        'Website',
                        agent.websiteUrl!,
                        onTap: () async {
                          try {
                            final website = agent.websiteUrl!;
                            final uri = Uri.parse(
                              website.startsWith('http') ? website : 'https://$website',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              SnackbarHelper.showError('Could not open website');
                            }
                          } catch (e) {
                            SnackbarHelper.showError('Could not open website: ${e.toString()}');
                          }
                        },
                      ),
                    ],
                    
                    // Rating & Reviews
                    if (agent.rating > 0) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${agent.rating.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (agent.reviewCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${agent.reviewCount} reviews)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'View Profile',
                            onPressed: () {
                              Navigator.pop(context);
                              Get.toNamed(
                                '/agent-profile',
                                arguments: {'agent': agent},
                              );
                            },
                            icon: Icons.person,
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Send Message',
                            onPressed: () {
                              Navigator.pop(context);
                              Get.toNamed('/contact', arguments: {
                                'userId': agent.id,
                                'userName': agent.name,
                                'userProfilePic': agent.profileImage,
                                'userRole': 'agent',
                                'agent': agent,
                              });
                            },
                            icon: Icons.message,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      barrierDismissible: true,
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

  void _showFullScreenImageSlider(BuildContext context, List<String> images, int initialIndex) {
    final currentIndex = initialIndex.obs;
    final pageController = PageController(initialPage: initialIndex);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              onPageChanged: (index) => currentIndex.value = index,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Builder(
                    builder: (context) {
                      final imageUrl = images[index];
                      if (kDebugMode) {
                        print('🖼️ Full Screen Image Viewer - Rendering image $index with URL: $imageUrl');
                      }
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.white,
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          if (kDebugMode) {
                            print('❌ Full Screen Image Viewer - Image load error for URL: $url');
                            print('   Error: $error');
                          }
                          return Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                        httpHeaders: const {
                          'Accept': 'image/*',
                        },
                        maxWidthDiskCache: 3000,
                        maxHeightDiskCache: 3000,
                      );
                    },
                  ),
                );
              },
            ),
            // Close Button
            Positioned(
              top: 40.h,
              right: 16.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                    // Dispose after navigation completes
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (pageController.hasClients) {
                        pageController.dispose();
                      }
                    });
                  },
                ),
              ),
            ),
            // Page Indicators (bottom)
            if (images.length > 1)
              Positioned(
                bottom: 40.h,
                left: 0,
                right: 0,
                child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: currentIndex.value == index ? 32.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: currentIndex.value == index
                            ? AppTheme.white
                            : AppTheme.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                )),
              ),
            // Image Counter (top)
            if (images.length > 1)
              Positioned(
                top: 40.h,
                left: 16.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Obx(() => Text(
                    '${currentIndex.value + 1} / ${images.length}',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ),
              ),
          ],
        ),
      ),
      barrierColor: Colors.black.withOpacity(0.95),
    ).then((_) {
      // Don't dispose here - it's already disposed in onPressed
    });
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
