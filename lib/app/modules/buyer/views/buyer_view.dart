import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';
import 'package:getrebate/app/widgets/custom_search_field.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/agent_card.dart';
import 'package:getrebate/app/widgets/loan_officer_card.dart';
import 'package:getrebate/app/widgets/notification_badge_icon.dart';
import 'package:intl/intl.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';

class BuyerView extends GetView<BuyerController> {
  const BuyerView({super.key});

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Home',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: const NotificationBadgeIcon(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Section
            _buildSearchSection(context),
            // Tabs
            _buildTabs(context),
            // Content
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.white,
      child: Column(
        children: [
          // Search Field - ZIP Code Only
          CustomSearchField(
            controller: controller.searchController,
            hintText: 'Enter ZIP code (5 digits)',
            onChanged: (value) {
              // Handle empty or cleared input - always clear filter immediately
              if (value.isEmpty || value.trim().isEmpty) {
                controller.clearZipCodeFilter();
                return;
              }
              // Only process if it's a valid 5-digit ZIP code
              final trimmedValue = value.trim();
              if (trimmedValue.length == 5 && RegExp(r'^\d+$').hasMatch(trimmedValue)) {
                // Apply filter immediately when valid ZIP is entered
                controller.searchByZipCode(trimmedValue);
              }
              // If user is typing but hasn't reached 5 digits yet, clear the filter
              // This ensures partial input doesn't keep the old filter active
              else if (value.length < 5) {
                // Clear filter when user is deleting/typing partial ZIP
                // This ensures that when user deletes characters, filter is cleared
                controller.clearZipCodeFilter();
              }
            },
            onLocationTap: () => controller.useCurrentLocation(),
            onClear: () {
              controller.searchController.clear();
              controller.clearZipCodeFilter();
            },
          ),

          const SizedBox(height: 20),

          // 4 BUTTONS — 2×2 GRID — USING ONLY CustomButton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.9,
            children: [
              // 1. Rebate Calculator
              CustomButton(
                text: 'Rebate Calculators',
                icon: Icons.calculate,
                onPressed: () => Get.toNamed('/rebate-calculator'),
              ),

              // 2. Full Survey
              CustomButton(
                text: 'Full Survey',
                icon: Icons.rate_review,
                onPressed: () {
                  try {
                    Get.toNamed(
                      '/post-closing-survey',
                      arguments: {
                        'agentId': 'test-agent-123',
                        'agentName': 'John Smith',
                        'userId': 'test-user-456',
                        'transactionId': 'test-transaction-789',
                        'isBuyer': true,
                      },
                    );
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Survey failed: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
              ),

              // 3. Buying Checklist
              CustomButton(
                text: 'Buying Checklist',
                icon: Icons.checklist_rtl,
                onPressed: () => Get.toNamed(
                  '/checklist',
                  arguments: {
                    'type': 'buyer',
                    'title': 'Homebuyer Checklist (with Rebate!)',
                  },
                ),
              ),

              // 4. Selling Checklist
              CustomButton(
                text: 'Selling Checklist',
                icon: Icons.sell,
                onPressed: () => Get.toNamed(
                  '/checklist',
                  arguments: {
                    'type': 'seller',
                    'title': 'Home Seller Checklist (with Rebate!)',
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: Obx(
        () => Row(
          children: [
            Expanded(child: _buildTab(context, 'Agents', 0, Icons.person)),
            Expanded(
              child: _buildTab(context, 'Homes for Sale', 1, Icons.home),
            ),
            Expanded(child: _buildTab(context, 'Open Houses', 2, Icons.event)),
            Expanded(
              child: _buildTab(
                context,
                'Loan Officers',
                3,
                Icons.account_balance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    int index,
    IconData icon,
  ) {
    final isSelected = controller.selectedTab == index;
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      if (controller.isLoading) {
        final isHomesForSale = controller.selectedTab == 1;
        final isOpenHouses = controller.selectedTab == 2;
        final isLoanOfficers = controller.selectedTab == 3;
        final primaryColor = isLoanOfficers
            ? AppTheme.lightGreen
            : isHomesForSale
            ? Colors.deepPurple
            : isOpenHouses
            ? Colors.orange
            : AppTheme.primaryBlue;
        return Center(
          child: SpinKitFadingCircle(
            color: primaryColor,
            size: 40,
          ),
        );
      }

      if (controller.selectedTab == 0) {
        return _buildAgentsList(context);
      } else if (controller.selectedTab == 1) {
        return _buildListingsList(context);
      } else if (controller.selectedTab == 2) {
        return _buildOpenHousesList(context);
      } else {
        return _buildLoanOfficersList(context);
      }
    });
  }

  Widget _buildAgentsList(BuildContext context) {
    return Obx(() {
      if (controller.agents.isEmpty) {
        return _buildEmptyState(
          context,
          'No agents found',
          'Try searching in a different ZIP code or expand your search area.',
          Icons.person_search,
        );
      }

      // Access reactive values directly inside Obx
      final currentPage = controller.currentPage.value;
      final totalPages = controller.totalPages.value;
      final canLoadMore = currentPage < totalPages;

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: controller.agents.length + (canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show Load More button at the end
          if (index == controller.agents.length) {
            return _buildLoadMoreButton(context);
          }
          
          final agent = controller.agents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Obx(
                      () => AgentCard(
                        agent: agent,
                        isFavorite: controller.isAgentFavorite(agent.id),
                        onTap: () => controller.viewAgentProfile(agent),
                        onContact: () => controller.contactAgent(agent),
                        onToggleFavorite: () =>
                            controller.toggleFavoriteAgent(agent.id),
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
  
  Widget _buildLoadMoreButton(BuildContext context) {
    return Obx(() {
      final isLoadingMore = controller.isLoadingMoreAgents;
      final currentPage = controller.currentPage.value;
      final totalPages = controller.totalPages.value;
      final canLoadMore = currentPage < totalPages;
      
      if (!canLoadMore) {
        return const SizedBox.shrink();
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.05),
                AppTheme.primaryBlue.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              // Count text with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${controller.agents.length} of ${controller.totalAgents.value} agents',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Load More Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isLoadingMore
                    ? Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading more agents...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomButton(
                        text: 'Load More Agents',
                        onPressed: () => controller.loadMoreAgents(),
                        icon: Icons.expand_more,
                        height: 48,
                        isOutlined: false,
                      ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
              duration: 500.ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.3,
              duration: 500.ms,
              curve: Curves.easeOut,
            )
            .scale(
              duration: 500.ms,
              curve: Curves.easeOut,
            ),
      );
    });
  }

  Widget _buildLoanOfficersList(BuildContext context) {
    return Obx(() {
      if (controller.loanOfficers.isEmpty) {
        return _buildEmptyState(
          context,
          'No loan officers found',
          'Try searching in a different ZIP code or expand your search area.',
          Icons.account_balance,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: controller.loanOfficers.length,
        itemBuilder: (context, index) {
          final loanOfficer = controller.loanOfficers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Obx(
                      () => LoanOfficerCard(
                        loanOfficer: loanOfficer,
                        isFavorite: controller.isLoanOfficerFavorite(
                          loanOfficer.id,
                        ),
                        onTap: () =>
                            controller.viewLoanOfficerProfile(loanOfficer),
                        onContact: () =>
                            controller.contactLoanOfficer(loanOfficer),
                        onToggleFavorite: () => controller
                            .toggleFavoriteLoanOfficer(loanOfficer.id),
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

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isHomesForSale = controller.selectedTab == 1;
    final isOpenHouses = controller.selectedTab == 2;
    final isLoanOfficers = controller.selectedTab == 3;
    final primaryColor = isLoanOfficers
        ? AppTheme.lightGreen
        : isHomesForSale
        ? Colors.deepPurple
        : isOpenHouses
        ? Colors.orange
        : AppTheme.primaryBlue;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Icon(icon, size: 32, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsList(BuildContext context) {
    return Obx(() {
      if (controller.listings.isEmpty) {
        return _buildEmptyState(
          context,
          'No listings found',
          'Try searching by ZIP code or city to discover listings.',
          Icons.home,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: controller.listings.length,
        itemBuilder: (context, index) {
          final listing = controller.listings[index];
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
                                    print('🖼️ Rendering image with URL: $imageUrl');
                                  }
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      if (kDebugMode) {
                                        print('❌ Image load error for URL: $url');
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
                                    maxWidthDiskCache: 1000,
                                    maxHeightDiskCache: 1000,
                                  );
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Obx(() => GestureDetector(
                                  onTap: () => controller.toggleFavoriteListing(listing.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      controller.isListingFavorite(listing.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: controller.isListingFavorite(listing.id)
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
                                  onTap: () => controller.toggleFavoriteListing(listing.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      controller.isListingFavorite(listing.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: controller.isListingFavorite(listing.id)
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
            ),
          );
        },
      );
    });
  }

  Widget _buildOpenHousesList(BuildContext context) {
    return Obx(() {
      if (controller.openHouses.isEmpty) {
        return _buildEmptyState(
          context,
          'No open houses found',
          'Try searching by ZIP code or city to discover upcoming open houses.',
          Icons.event,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: controller.openHouses.length,
        itemBuilder: (context, index) {
          final openHouse = controller.openHouses[index];
          final listing = controller.getListingForOpenHouse(openHouse);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                GestureDetector(
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
                                          final imageUrl = listing.photoUrls.first;
                                          if (kDebugMode) {
                                            print('🖼️ Open House - Rendering image with URL: $imageUrl');
                                          }
                                          return CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              height: 180,
                                              width: double.infinity,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) {
                                              if (kDebugMode) {
                                                print('❌ Open House - Image load error for URL: $url');
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
                                            maxWidthDiskCache: 1000,
                                            maxHeightDiskCache: 1000,
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                        child: Obx(() => GestureDetector(
                                          onTap: () => controller.toggleFavoriteListing(listing.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              controller.isListingFavorite(listing.id)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: controller.isListingFavorite(listing.id)
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
                                        top: 8,
                                        left: 8,
                                        child: Obx(() => GestureDetector(
                                          onTap: () => controller.toggleFavoriteListing(listing?.id ?? openHouse.listingId),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              controller.isListingFavorite(listing?.id ?? openHouse.listingId)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: controller.isListingFavorite(listing?.id ?? openHouse.listingId)
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'EEE, MMM d',
                                                ).format(openHouse.startTime),
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
                                  if (openHouse.notes != null &&
                                      openHouse.notes!.isNotEmpty) ...[
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
