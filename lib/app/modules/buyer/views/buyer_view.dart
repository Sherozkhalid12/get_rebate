import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';
import 'package:getrebate/app/widgets/custom_search_field.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/agent_card.dart';
import 'package:getrebate/app/widgets/loan_officer_card.dart';
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
            Obx(() {
              final user = Get.find<AuthController>().currentUser;
              if (user != null) {
                return Text(
                  'User ID: ${user.id}',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.normal,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        centerTitle: true,
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
          // Search Field
          CustomSearchField(
            controller: controller.searchController,
            hintText: 'Enter ZIP code or drop pin',
            onChanged: (value) {
              if (value.length >= 5) {
                controller.searchByZipCode(value);
              }
            },
            onLocationTap: () => controller.useCurrentLocation(),
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
        return Center(child: CircularProgressIndicator(color: primaryColor));
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

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: controller.agents.length,
        itemBuilder: (context, index) {
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: primaryColor),
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
                        ? Image.network(
                            listing.photoUrls.first,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 160,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.home,
                              size: 48,
                              color: Colors.grey,
                            ),
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
                                      Image.network(
                                        listing.photoUrls.first,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
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
                                    ],
                                  )
                                : Container(
                                    height: 180,
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.event,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
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
}
