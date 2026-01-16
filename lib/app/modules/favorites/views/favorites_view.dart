import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/favorites/controllers/favorites_controller.dart';
import 'package:getrebate/app/modules/buyer_v2/controllers/buyer_v2_controller.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/widgets/agent_card.dart';
import 'package:getrebate/app/widgets/loan_officer_card.dart';
import 'package:intl/intl.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});
  
  /// Helper method to set buyer tab with retries
  void _setBuyerTabWithRetry(int tabIndex, {int retries = 5, int delayMs = 200}) {
    if (retries <= 0) return;
    
    Future.delayed(Duration(milliseconds: delayMs), () {
      try {
        // First, ensure we're on the home tab (index 0) in main navigation
        if (Get.isRegistered<MainNavigationController>()) {
          final mainNavController = Get.find<MainNavigationController>();
          mainNavController.changeIndex(0); // Switch to home tab
        }
        
        // Then set the buyer tab
        if (Get.isRegistered<BuyerV2Controller>()) {
          final buyerController = Get.find<BuyerV2Controller>();
          buyerController.setSelectedTab(tabIndex);
          if (kDebugMode) {
            print('✅ Successfully set buyer tab to $tabIndex');
          }
        } else {
          // Retry if controller not registered yet
          if (kDebugMode) {
            print('⚠️ BuyerV2Controller not registered yet, retrying... (${retries - 1} retries left)');
          }
          _setBuyerTabWithRetry(tabIndex, retries: retries - 1, delayMs: delayMs);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error setting buyer tab: $e (${retries - 1} retries left)');
        }
        if (retries > 1) {
          _setBuyerTabWithRetry(tabIndex, retries: retries - 1, delayMs: delayMs);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always refresh favorites when view is built (user navigates to this screen)
    // Use a delay to ensure buyer controller data is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a bit longer to ensure agents/loan officers are loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.refreshFavorites();
      });
    });
    
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
          'Favorites',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            _buildTabs(context),

            // Content
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
          ),
          Expanded(
            child: Text(
              'My Favorites',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                controller.clearAllFavorites();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Favorites'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: Obx(() {
        final selectedTab = controller.selectedTab;
        return Row(
          children: [
            Expanded(child: _buildTab(context, 'Agents', 0, Icons.person, selectedTab)),
            Expanded(
              child: _buildTab(context, 'Homes for Sale', 1, Icons.home, selectedTab),
            ),
            Expanded(child: _buildTab(context, 'Open Houses', 2, Icons.event, selectedTab)),
            Expanded(
              child: _buildTab(
                context,
                'Loan Officers',
                3,
                Icons.account_balance,
                selectedTab,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    int index,
    IconData icon,
    int selectedTab,
  ) {
    final isSelected = selectedTab == index;
    final isHomesForSale = index == 1;
    final isOpenHouses = index == 2;
    final isLoanOfficers = index == 3;
    final primaryColor = isLoanOfficers
        ? AppTheme.lightGreen
        : isHomesForSale
            ? Colors.deepPurple
            : isOpenHouses
                ? Colors.orange
                : AppTheme.primaryBlue;

    return GestureDetector(
      onTap: () => controller.setSelectedTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : AppTheme.mediumGray,
              size: 20,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? primaryColor : AppTheme.mediumGray,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      switch (controller.selectedTab) {
        case 0:
          return _buildAgentsList(context);
        case 1:
          return _buildListingsList(context); // Houses for Sale
        case 2:
          return _buildOpenHousesList(context); // Open Houses
        default:
          return _buildLoanOfficersList(context);
      }
    });
  }

  Widget _buildAgentsList(BuildContext context) {
    if (controller.isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: AppTheme.primaryBlue,
          size: 40,
        ),
      );
    }

    return Obx(() {
      if (controller.favoriteAgents.isEmpty) {
        return _buildEmptyState(
          context,
          'No favorite agents',
          'Agents you favorite will appear here',
          Icons.person_search,
        );
      }

      final favoriteAgents = controller.favoriteAgents;

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: favoriteAgents.length,
        itemBuilder: (context, index) {
          final agent = favoriteAgents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                AgentCard(
                      agent: agent,
                      isFavorite: true,
                      onTap: () => controller.viewAgentProfile(agent),
                      onContact: () => controller.contactAgent(agent),
                      onToggleFavorite: () =>
                          controller.removeFavoriteAgent(agent.id),
                    )
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

  Widget _buildLoanOfficersList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return Center(
          child: SpinKitFadingCircle(
            color: AppTheme.primaryBlue,
            size: 40,
          ),
        );
      }
      
      if (controller.favoriteLoanOfficers.isEmpty) {
        return _buildEmptyState(
          context,
          'No favorite loan officers',
          'Loan officers you favorite will appear here',
          Icons.account_balance,
        );
      }

      final favoriteLoanOfficers = controller.favoriteLoanOfficers;

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: favoriteLoanOfficers.length,
        itemBuilder: (context, index) {
          final loanOfficer = favoriteLoanOfficers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                LoanOfficerCard(
                      loanOfficer: loanOfficer,
                      isFavorite: true,
                      onTap: () =>
                          controller.viewLoanOfficerProfile(loanOfficer),
                      onContact: () =>
                          controller.contactLoanOfficer(loanOfficer),
                      onToggleFavorite: () =>
                          controller.removeFavoriteLoanOfficer(loanOfficer.id),
                    )
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

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
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
              child: Icon(icon, size: 40, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsList(BuildContext context) {
    if (controller.isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: AppTheme.primaryBlue,
          size: 40,
        ),
      );
    }

    return Obx(() {
      if (controller.favoriteListings.isEmpty) {
        return _buildEmptyState(
          context,
          'No favorite listings',
          'Listings you favorite will appear here',
          Icons.home,
        );
      }

      final favoriteListings = controller.favoriteListings;
      final buyerController = Get.find<BuyerV2Controller>();

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: favoriteListings.length,
        itemBuilder: (context, index) {
          final listing = favoriteListings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => controller.viewListing(listing),
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    listing.photoUrls.isNotEmpty
                        ? Stack(
                            children: [
                              Builder(
                                builder: (context) {
                                  final imageUrl = listing.photoUrls.first;
                                  if (kDebugMode) {
                                    print('🖼️ Favorites - Rendering image with URL: $imageUrl');
                                  }
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    cacheKey: imageUrl,
                                    memCacheWidth: 400,
                                    memCacheHeight: 300,
                                    maxWidthDiskCache: 800,
                                    maxHeightDiskCache: 600,
                                    fadeInDuration: Duration.zero,
                                    placeholder: (context, url) => Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                    ),
                                    errorWidget: (context, url, error) {
                                      if (kDebugMode) {
                                        print('❌ Favorites - Image load error for URL: $url');
                                        print('   Error: $error');
                                        print('   Error type: ${error.runtimeType}');
                                      }
                                      return Container(
                                        height: 160,
                                        width: double.infinity,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.home,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                    httpHeaders: const {
                                      'Accept': 'image/*',
                                    },
                                  );
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Obx(() => GestureDetector(
                                  onTap: () => controller.removeFavoriteListing(listing.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      buyerController.isListingFavorite(listing.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: buyerController.isListingFavorite(listing.id)
                                          ? Colors.red
                                          : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              Container(
                                height: 160,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.home,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Obx(() => GestureDetector(
                                  onTap: () => controller.removeFavoriteListing(listing.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      buyerController.isListingFavorite(listing.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: buyerController.isListingFavorite(listing.id)
                                          ? Colors.red
                                          : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${(listing.priceCents ~/ 100).toString().replaceAll(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), ',')}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(listing.address.toString()),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  listing.dualAgencyAllowed
                                      ? 'Dual Agency Allowed'
                                      : 'No Dual Agency',
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
            )
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

  Widget _buildOpenHousesList(BuildContext context) {
    if (controller.isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          color: AppTheme.primaryBlue,
          size: 40,
        ),
      );
    }

    return Obx(() {
      if (controller.favoriteOpenHouses.isEmpty) {
        return _buildEmptyState(
          context,
          'No favorite open houses',
          'Open houses you favorite will appear here',
          Icons.event,
        );
      }

      // Get buyer controller to access listings
      final buyerController = Get.find<BuyerV2Controller>();
      final favoriteOpenHouses = controller.favoriteOpenHouses;

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: favoriteOpenHouses.length,
        itemBuilder: (context, index) {
          final openHouse = favoriteOpenHouses[index];
          final listing = buyerController.getListingForOpenHouse(openHouse);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => controller.viewOpenHouse(openHouse),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    listing != null && listing.photoUrls.isNotEmpty
                        ? Stack(
                            children: [
                              Builder(
                                builder: (context) {
                                  final imageUrl = listing?.photoUrls.first ?? '';
                                  if (kDebugMode && imageUrl.isNotEmpty) {
                                    print('🖼️ Favorites Open House - Rendering image with URL: $imageUrl');
                                  }
                                  return imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          cacheKey: imageUrl,
                                          memCacheWidth: 450,
                                          memCacheHeight: 350,
                                          maxWidthDiskCache: 900,
                                          maxHeightDiskCache: 700,
                                          fadeInDuration: Duration.zero,
                                          placeholder: (context, url) => Container(
                                            height: 180,
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                          ),
                                          errorWidget: (context, url, error) {
                                            if (kDebugMode) {
                                              print('❌ Favorites Open House - Image load error for URL: $url');
                                              print('   Error: $error');
                                            }
                                            return Container(
                                              height: 180,
                                              width: double.infinity,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.event,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                          httpHeaders: const {
                                            'Accept': 'image/*',
                                          },
                                        )
                                      : Container(
                                          height: 180,
                                          width: double.infinity,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.event,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        );
                                },
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Open House',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Obx(() {
                                  final listingId = listing?.id ?? openHouse.listingId;
                                  final isFavorite = buyerController.isListingFavorite(listingId);
                                  return GestureDetector(
                                    onTap: () => controller.removeFavoriteListing(listingId),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              Container(
                                height: 180,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.event,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Open House',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Obx(() {
                                  final listingId = listing?.id ?? openHouse.listingId;
                                  final isFavorite = buyerController.isListingFavorite(listingId);
                                  return GestureDetector(
                                    onTap: () => controller.removeFavoriteListing(listingId),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                            Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (listing != null) ...[
                            Text(
                              '\$${(listing.priceCents ~/ 100).toString().replaceAll(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), ',')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              listing.address.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.mediumGray,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 16),
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
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('EEE, MMM d').format(openHouse.startTime),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.darkGray,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${DateFormat('h:mm a').format(openHouse.startTime)} - ${DateFormat('h:mm a').format(openHouse.endTime)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.mediumGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (openHouse.notes != null && openHouse.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppTheme.mediumGray,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    openHouse.notes!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.mediumGray,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  duration: 200.ms,
                  curve: Curves.easeOutCubic,
                  delay: (index * 20).ms,
                )
                .fadeIn(
                  duration: 200.ms,
                  delay: (index * 20).ms,
                  curve: Curves.easeOut,
                ),
          );
        },
      );
    });
  }
}
