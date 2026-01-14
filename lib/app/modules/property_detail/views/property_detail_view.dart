import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/property_detail/controllers/property_detail_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/rebate_display_widget.dart';
import 'package:getrebate/app/widgets/nearby_agents_widget.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:intl/intl.dart';

class PropertyDetailView extends GetView<PropertyDetailController> {
  const PropertyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(context),

          // Property Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Info
                  _buildPropertyInfo(context),

                  const SizedBox(height: 24),

                  // Open House Section (NEW)
                  if (controller.property['openHouses'] != null &&
                      (controller.property['openHouses'] as List)
                          .isNotEmpty) ...[
                    _buildOpenHouseSection(context),
                    const SizedBox(height: 24),
                  ],

                  // Property Features
                  _buildPropertyFeatures(context),

                  const SizedBox(height: 24),

                  // Agent Info
                  _buildAgentInfo(context),

                  const SizedBox(height: 24),

                  // Rebate Information
                  _buildRebateInfo(context),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(context),

                  const SizedBox(height: 24),

                  // Property Description
                  _buildPropertyDescription(context),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenHouseSection(BuildContext context) {
    final openHouses = controller.property['openHouses'] as List? ?? [];
    if (openHouses.isEmpty) return const SizedBox.shrink();
    
    final now = DateTime.now();

    // Separate upcoming and past open houses
    final upcomingOpenHouses = <Map<String, dynamic>>[];
    final pastOpenHouses = <Map<String, dynamic>>[];
    
    for (final oh in openHouses) {
      try {
        final ohMap = oh as Map<String, dynamic>;
        // Try to parse date
        final dateStr = ohMap['date']?.toString() ?? ohMap['startDateTime']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            if (date.isAfter(now)) {
              upcomingOpenHouses.add(ohMap);
            } else {
              pastOpenHouses.add(ohMap);
            }
          } else {
            // If can't parse date, assume upcoming
            upcomingOpenHouses.add(ohMap);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error processing open house: $e');
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            AppTheme.lightGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open House',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (upcomingOpenHouses.isNotEmpty)
                      Text(
                        '${upcomingOpenHouses.length} upcoming ${upcomingOpenHouses.length == 1 ? 'event' : 'events'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (upcomingOpenHouses.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...upcomingOpenHouses.map((openHouse) {
              return _buildOpenHouseItem(context, openHouse, false);
            }).toList(),
          ],

          if (pastOpenHouses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Past Open Houses',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.mediumGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...pastOpenHouses.map((openHouse) {
              return _buildOpenHouseItem(context, openHouse, true);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildOpenHouseItem(
    BuildContext context,
    Map<String, dynamic> openHouse,
    bool isPast,
  ) {
    // Parse date - handle both formats
    DateTime? startDate;
    final dateStr = openHouse['date']?.toString() ?? openHouse['startDateTime']?.toString() ?? '';
    
    try {
      if (dateStr.isNotEmpty) {
        startDate = DateTime.parse(dateStr);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error parsing open house date: $dateStr');
      }
      startDate = DateTime.now();
    }
    
    startDate ??= DateTime.now();
    
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final fromTime = openHouse['fromTime']?.toString() ?? '10:00 AM';
    final toTime = openHouse['toTime']?.toString() ?? '2:00 PM';

    final isToday = DateUtils.isSameDay(startDate, DateTime.now());
    final isTomorrow = DateUtils.isSameDay(
      startDate,
      DateTime.now().add(const Duration(days: 1)),
    );

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = dateFormat.format(startDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPast ? AppTheme.mediumGray.withOpacity(0.05) : AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPast
              ? AppTheme.mediumGray.withOpacity(0.3)
              : AppTheme.primaryBlue.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppTheme.mediumGray.withOpacity(0.2)
                      : (isToday || isTomorrow)
                      ? AppTheme.lightGreen.withOpacity(0.2)
                      : AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPast
                        ? AppTheme.mediumGray
                        : (isToday || isTomorrow)
                        ? AppTheme.lightGreen
                        : AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isPast)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '(Ended)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: isPast ? AppTheme.mediumGray : AppTheme.darkGray,
              ),
              const SizedBox(width: 6),
              Text(
                '$fromTime - $toTime',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isPast ? AppTheme.mediumGray : AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (openHouse['notes']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isPast ? AppTheme.mediumGray : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    openHouse['notes']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPast ? AppTheme.mediumGray : AppTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isPast) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addToCalendar(context, openHouse),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Add to Calendar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _getDirections(context),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _addToCalendar(BuildContext context, Map<String, dynamic> openHouse) {
    // TODO: Implement add to calendar functionality
    Get.snackbar(
      'Add to Calendar',
      'Calendar integration coming soon!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.primaryBlue,
      colorText: AppTheme.white,
    );
  }

  void _getDirections(BuildContext context) {
    // TODO: Implement directions to property
    SnackbarHelper.showInfo(
      'Opening maps...',
      title: 'Get Directions',
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final images =
        controller.property['images'] ?? [controller.property['image']];

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppTheme.white),
      ),
      // REMOVED: Favorite and Share icons from property view
      // actions: [
      //   Obx(
      //     () => IconButton(
      //       onPressed: controller.toggleFavorite,
      //       icon: Icon(
      //         controller.isFavorite ? Icons.favorite : Icons.favorite_border,
      //         color: controller.isFavorite ? Colors.red : AppTheme.white,
      //       ),
      //     ),
      //   ),
      //   IconButton(
      //     onPressed: () {
      //       Get.snackbar('Share', 'Share functionality coming soon!');
      //     },
      //     icon: const Icon(Icons.share, color: AppTheme.white),
      //   ),
      // ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                onPageChanged: controller.setCurrentImageIndex,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    cacheKey: images[index],
                    memCacheWidth: 800,
                    memCacheHeight: 600,
                    maxWidthDiskCache: 1600,
                    maxHeightDiskCache: 1200,
                    fadeInDuration: Duration.zero,
                    placeholder: (context, url) => Container(
                      color: AppTheme.lightGray,
                    ),
                    errorWidget: (context, url, error) {
                      return Container(
                        color: AppTheme.lightGray,
                        child: const Icon(
                          Icons.home,
                          size: 48,
                          color: AppTheme.mediumGray,
                        ),
                      );
                    },
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Obx(
                        () => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.currentImageIndex == index
                                ? AppTheme.white
                                : AppTheme.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.property['price'] ?? 'Price not available',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.property['address'] ?? 'Address not available',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (controller.property['status'] == 'For Sale')
                ? AppTheme.lightGreen.withOpacity(0.1)
                : AppTheme.mediumGray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            controller.property['status'] ?? 'Status unknown',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: (controller.property['status'] == 'For Sale')
                  ? AppTheme.lightGreen
                  : AppTheme.mediumGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyFeatures(BuildContext context) {
    final beds = controller.property['beds'] ?? 0;
    final baths = controller.property['baths'] ?? 0;
    final sqft = controller.property['sqft'] ?? 0;
    final lotSize = controller.property['lotSize'];
    final yearBuilt = controller.property['yearBuilt'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (beds > 0)
              _buildFeatureItem(
                context,
                Icons.bed,
                '$beds ${beds == 1 ? "bed" : "beds"}',
              ),
            if (baths > 0)
              _buildFeatureItem(
                context,
                Icons.bathtub,
                '$baths ${baths == 1 ? "bath" : "baths"}',
              ),
            if (sqft > 0)
              _buildFeatureItem(
                context,
                Icons.square_foot,
                '$sqft sqft',
              ),
            if (lotSize != null && lotSize != 'N/A')
              _buildFeatureItem(
                context,
                Icons.landscape,
                '$lotSize lot',
              ),
            if (yearBuilt != null)
              _buildFeatureItem(
                context,
                Icons.calendar_today,
                'Built $yearBuilt',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.mediumGray, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
        ),
      ],
    );
  }

  Widget _buildAgentInfo(BuildContext context) {
    final agent = controller.property['agent'] as Map<String, dynamic>? ?? {};
    final agentName = agent['name']?.toString() ?? 'Agent Name';
    final agentCompany = agent['company']?.toString() ?? 'Real Estate Company';
    final agentProfileImage = agent['profileImage']?.toString();
    final hasValidImage = agentProfileImage != null && 
                          agentProfileImage.isNotEmpty && 
                          agentProfileImage.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listed by',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                backgroundImage: hasValidImage
                    ? NetworkImage(agentProfileImage)
                    : null,
                child: !hasValidImage
                    ? Text(
                        agentName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
                onBackgroundImageError: hasValidImage ? (_, __) {} : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (agentCompany.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        agentCompany,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.contactAgent,
                icon: const Icon(Icons.message, color: AppTheme.primaryBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRebateInfo(BuildContext context) {
    final property = controller.property;
    final agent = property['agent'] ?? {};

    // === 1. DUAL AGENCY CHECK – ONLY SHOW IF ALLOWED ===
    final dualAllowedInState = agent['isDualAgencyAllowedInState'] == true;
    final dualAllowedAtBrokerage =
        agent['isDualAgencyAllowedAtBrokerage'] == true;
    final dualAgencyAllowed = dualAllowedInState && dualAllowedAtBrokerage;

    // === 2. PRICE & REBATE CALCULATION ===
    double price = 400000;
    if (property['price'] is String) {
      final cleaned = property['price'].toString().replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
      price = double.tryParse(cleaned) ?? 400000;
    } else if (property['price'] is num) {
      price = property['price'].toDouble();
    }

    // BAC = Buyer's Agent Commission (default 2.7%)
    final bacPercent = (property['bacPercent'] ?? 2.7);
    final buyerCommission = price * (bacPercent / 100);

    // Apply tier-based rebate percentages (matching rebate calculator)
    final isHighValue = price >= 700000;

    // Determine rebate percentage based on commission rate and price
    double rebatePercent;
    if (bacPercent >= 4.0) {
      rebatePercent = 40.0; // Tier 1
    } else if (bacPercent >= 3.01) {
      rebatePercent = 35.0; // Tier 2
    } else if (bacPercent >= 2.5) {
      rebatePercent = 30.0; // Tier 3
    } else if (bacPercent >= 2.0) {
      rebatePercent = 25.0; // Tier 4
    } else if (bacPercent >= 1.5 && !isHighValue) {
      rebatePercent = 20.0; // Tier 5 (not available for $700k+)
    } else if (bacPercent >= 0.25 && !isHighValue) {
      rebatePercent = 10.0; // Tier 6 (not available for $700k+)
    } else if (bacPercent < 0.25) {
      rebatePercent = 0.0; // Tier 7
    } else {
      // For $700k+ homes with commission < 2%, minimum is Tier 4 (25%)
      rebatePercent = isHighValue ? 25.0 : 10.0;
    }

    final rebateAmount = buyerCommission * (rebatePercent / 100);

    // === 3. MOCK LISTING FOR WIDGETS ===
    // Extract ZIP code from various possible locations in property data
    String zipCode = '';
    if (property['zip'] != null) {
      zipCode = property['zip'].toString();
    } else if (property['zipCode'] != null) {
      zipCode = property['zipCode'].toString();
    } else if (property['address'] is Map) {
      final address = property['address'] as Map<String, dynamic>;
      zipCode = address['zip']?.toString() ?? 
                address['zipCode']?.toString() ?? 
                '';
    }
    
    if (kDebugMode) {
      print('📍 Property Detail - Extracted ZIP Code: $zipCode');
      print('   From property[\'zip\']: ${property['zip']}');
      print('   From property[\'zipCode\']: ${property['zipCode']}');
      if (property['address'] is Map) {
        print('   From property[\'address\'][\'zip\']: ${(property['address'] as Map)['zip']}');
      }
    }
    
    final mockListing = Listing(
      id: property['id'] ?? 'mock',
      agentId: property['agentId'] ?? 'mock_agent',
      priceCents: (price * 100).toInt(),
      address: ListingAddress(
        street: property['address'] is Map 
            ? (property['address'] as Map)['street']?.toString() ?? property['address']?.toString() ?? '123 Luxury Ave'
            : property['address']?.toString() ?? '123 Luxury Ave',
        city: property['city'] ?? 'Beverly Hills',
        state: property['state'] ?? 'CA',
        zip: zipCode.isNotEmpty ? zipCode : '90210',
      ),
      photoUrls: List<String>.from(
        property['images'] ?? [property['image'] ?? ''],
      ),
      bacPercent: bacPercent * 100,
      dualAgencyAllowed: dualAgencyAllowed,
      dualAgencyCommissionPercent: dualAgencyAllowed ? 400.0 : null,
      createdAt: DateTime.now(),
    );

    return Column(
      children: [
        // === REBATE DISPLAY WIDGET ===
        RebateDisplayWidget(
          listing: mockListing,
          onFindAgents: () => _navigateToFindAgents(mockListing),
          onDualAgencyInfo: dualAgencyAllowed
              ? () => _showDualAgencyInfo(context)
              : null,
        ),

        const SizedBox(height: 16),

        // === REBATE DISCLOSURE BOX (UPDATED) ===
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.08),
                AppTheme.lightGreen.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: AppTheme.lightGreen,
                    size: 28,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Your Potential Rebate',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Big Rebate Amount
              Text(
                '\$${rebateAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.lightGreen,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 8.h),

              // Dynamic Disclaimer
              Text(
                isHighValue
                    ? 'Minimum 25% rebate on homes \$700k+ (Tier ${_getTierName(bacPercent, isHighValue)})'
                    : 'Up to 40% of buyer-agent commission (Tier ${_getTierName(bacPercent, isHighValue)})',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),

              // Final Legal Note
              Text(
                'Could be more or less depending on total commission received',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12.h),

              // Dual Agency Note
              if (dualAgencyAllowed) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.handshake,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'This agent allows dual agency — you may qualify for even higher rebates!',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
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

        const SizedBox(height: 16),
        _buildRebateDisclosure(context),
        const SizedBox(height: 16),
        NearbyAgentsWidget(listing: mockListing),
      ],
    );
  }

  Widget _buildRebateDisclosure(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
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
              Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Important Rebate Disclosure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showFullRebateDisclosure(context),
                icon: Icon(Icons.open_in_full, size: 16),
                label: Text('View Full'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The Get a Rebate Real Estate platform is designed to help buyers and sellers save money by sharing a portion of the real estate commission earned by participating agents. The availability and amount of a rebate will vary based on the total commission received and applicable state laws.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real estate commissions are 100% negotiable.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Commission rates and rebate percentages are subject to negotiation and final agreement between all parties',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
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

  void _showFullRebateDisclosure(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RebateDisclosureDialog(
        onAcknowledge: () {
          controller.acknowledgeRebateDisclosure();
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Navigate to Find Agents screen with ZIP code from listing
  void _navigateToFindAgents(Listing listing) {
    final zipCode = listing.address.zip;
    
    if (kDebugMode) {
      print('🔍 Navigating to Find Agents');
      print('   Listing ID: ${listing.id}');
      print('   Listing Address: ${listing.address.toString()}');
      print('   ZIP Code from listing: $zipCode');
    }
    
    if (zipCode.isEmpty || zipCode == '90210') {
      // Try to get ZIP from property data if listing ZIP is missing or default
      final property = controller.property;
      String fallbackZip = '';
      if (property['zip'] != null) {
        fallbackZip = property['zip'].toString();
      } else if (property['zipCode'] != null) {
        fallbackZip = property['zipCode'].toString();
      } else if (property['address'] is Map) {
        final address = property['address'] as Map<String, dynamic>;
        fallbackZip = address['zip']?.toString() ?? 
                     address['zipCode']?.toString() ?? 
                     '';
      }
      
      if (kDebugMode) {
        print('   Fallback ZIP from property: $fallbackZip');
      }
      
      if (fallbackZip.isNotEmpty && fallbackZip != '90210') {
        // Use fallback ZIP
        Get.toNamed(
          '/find-agents',
          arguments: {
            'zip': fallbackZip,
            'listing': listing,
          },
        );
        return;
      }
      
      SnackbarHelper.showError('ZIP code not available for this property');
      return;
    }
    
    Get.toNamed(
      '/find-agents',
      arguments: {
        'zip': zipCode,
        'listing': listing,
      },
    );
  }

  void _showNearbyAgents(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.lightGray, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nearby Agents',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(child: NearbyAgentsWidget(listing: listing)),
          ],
        ),
      ),
    );
  }

  void _showDualAgencyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DualAgencyExplanationDialog(),
    );
  }

  String _getTierName(double bacPercent, bool isHighValue) {
    if (bacPercent >= 4.0) return '1';
    if (bacPercent >= 3.01) return '2';
    if (bacPercent >= 2.5) return '3';
    if (bacPercent >= 2.0) return '4';
    if (bacPercent >= 1.5 && !isHighValue) return '5';
    if (bacPercent >= 0.25 && !isHighValue) return '6';
    if (bacPercent < 0.25) return '7';
    return '4'; // Default for high-value homes
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          text: 'I am interested in this property',
          onPressed: controller.openBuyerLeadForm,
          fontSize: 11.sp,
          icon: Icons.shopping_cart,
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Calculate Rebate',
          onPressed: controller.openRebateCalculator,
          icon: Icons.calculate,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildPropertyDescription(BuildContext context) {
    final description = controller.property['description']?.toString() ?? '';
    final hasDescription = description.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasDescription
              ? description
              : 'This beautiful property offers modern amenities and a great location. Contact us for more details about this amazing opportunity.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: hasDescription ? AppTheme.darkGray : AppTheme.mediumGray,
            fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class RebateDisclosureDialog extends StatefulWidget {
  final VoidCallback onAcknowledge;

  const RebateDisclosureDialog({super.key, required this.onAcknowledge});

  @override
  State<RebateDisclosureDialog> createState() => _RebateDisclosureDialogState();
}

class _RebateDisclosureDialogState extends State<RebateDisclosureDialog> {
  bool _hasRead = false;
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rebate Disclosure',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    final metrics = notification.metrics;
                    if (metrics.pixels >= metrics.maxScrollExtent - 50) {
                      setState(() => _hasRead = true);
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Full rebate disclosure text here...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                border: Border(
                  top: BorderSide(color: AppTheme.lightGray, width: 1),
                ),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _acknowledged,
                    onChanged: _hasRead
                        ? (value) => setState(() => _acknowledged = value!)
                        : null,
                    title: Text(
                      'I acknowledge that I have read and understand this rebate disclosure',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _hasRead ? AppTheme.black : AppTheme.mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    activeColor: AppTheme.primaryBlue,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _acknowledged ? widget.onAcknowledge : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: AppTheme.mediumGray,
                      ),
                      child: Text(
                        _acknowledged
                            ? 'I Understand'
                            : 'Please read and acknowledge above',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DualAgencyExplanationDialog extends StatelessWidget {
  const DualAgencyExplanationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dual Agency Explanation',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              'Dual agency occurs when the same agent represents both buyer and seller...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}
