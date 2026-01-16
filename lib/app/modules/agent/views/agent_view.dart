import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/agent/controllers/agent_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/models/agent_listing_model.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/utils/image_url_helper.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AgentView extends GetView<AgentController> {
  const AgentView({super.key});

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
          'Agent Dashboard',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: AppTheme.white),
            onPressed: () => Get.toNamed('/messages'),
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
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
      floatingActionButton: Obx(() {
        if (controller.selectedTab == 2) {
          // My Listings tab
          return FloatingActionButton.extended(
            onPressed: controller.canAddFreeListing
                ? () => Get.toNamed('/add-listing')
                : () => _showBuySlotDialog(context),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            icon: Icon(
              controller.canAddFreeListing
                  ? Icons.add
                  : Icons.shopping_cart_outlined,
            ),
            label: Text(
              controller.canAddFreeListing ? 'Add Listing' : 'Buy Slot',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 5.5,
                child: _buildTab(context, 'Dashboard', 0, Icons.dashboard),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 5.5,
                child: _buildTab(context, 'ZIP Codes', 1, Icons.location_on),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 5.5,
                child: _buildTab(context, 'Listings', 2, Icons.home),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 5.5,
                child: _buildTab(context, 'Stats', 3, Icons.analytics),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 5.5,
                child: _buildTab(context, 'Billing', 4, Icons.payment),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 5.5,
                child: _buildTab(context, 'Leads', 5, Icons.people),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRebateChecklistSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: Icon(
                    Icons.checklist_rtl,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rebate Compliance Checklist',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Follow these step-by-step guidelines to ensure rebate compliance and a smooth transaction.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.lightGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Includes checklists for both buying and selling transactions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'View Compliance Checklists',
              onPressed: () {
                Get.toNamed('/rebate-checklist');
              },
              icon: Icons.assignment_outlined,
              width: double.infinity,
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

    return GestureDetector(
      onTap: () => controller.setSelectedTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          return _buildDashboard(context);
        case 1:
          return _buildZipManagement(context);
        case 2:
          return _buildMyListings(context);
        case 3:
          return _buildStats(context);
        case 4:
          return _buildBilling(context);
        case 5:
          return _buildLeads(context);
        default:
          return _buildDashboard(context);
      }
    });
  }

  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsCards(context),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context),

          const SizedBox(height: 24),
          _buildRebateChecklistSection(context),

          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Obx(() {
      final stats = controller.getStatsData();
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final stat = stats[index];

        return GradientCardWithIcon(
              icon: stat['icon'],
              iconColor: Colors.white,
              gradientColors: AppTheme.primaryGradient,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stat['value'].toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat['label'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .slideY(
              begin: 0.2,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
              delay: (index * 50).ms,
            )
            .fadeIn(duration: 250.ms, delay: (index * 50).ms, curve: Curves.easeOut);
        },
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Manage ZIP Codes',
                  onPressed: () => controller.setSelectedTab(1),
                  icon: Icons.location_on,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'View Billing',
                  onPressed: () => controller.setSelectedTab(4),
                  icon: Icons.payment,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Compliance Tutorial',
                  onPressed: () {
                    Get.toNamed('/compliance-tutorial');
                  },
                  icon: Icons.school,
                  isOutlined: true,
                  height: 60.h,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Edit Profile',
                  onPressed: () {
                    Get.toNamed('/agent-edit-profile');
                  },
                  icon: Icons.edit,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            context,
            'New search in ZIP 10001',
            '2 hours ago',
            Icons.search,
          ),
          _buildActivityItem(
            context,
            'Profile viewed by buyer',
            '4 hours ago',
            Icons.visibility,
          ),
          _buildActivityItem(
            context,
            'Contact request received',
            '6 hours ago',
            Icons.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZipManagement(BuildContext context) {
    final authController = Get.find<global.AuthController>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
          // Search
          CustomTextField(
            controller: TextEditingController(),
            labelText: 'Search ZIP codes',
            prefixIcon: Icons.search,
            onChanged: (value) => controller.searchZipCodes(value),
          ),

          const SizedBox(height: 20),

          // Licensed States Section
          Obx(() {
            final licensedStates = authController.currentUser?.licensedStates ?? [];
            if (licensedStates.isNotEmpty) {
              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your Licensed States',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'States you selected during sign up:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: licensedStates.map((state) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                  ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // State Selector for ZIP Codes - Always show, but only show licensed states in dropdown
          Obx(() {
            final licensedStates = authController.currentUser?.licensedStates ?? [];
            final uniqueStates = licensedStates.toSet().toList()..sort((a, b) => a.compareTo(b));
            
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select State to View ZIP Codes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (uniqueStates.isEmpty)
                      Container(
                        padding: EdgeInsets.zero,
                        child: Text(
                          'No licensed states found. Please update your profile to add licensed states.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                        ),
                      )
                    else
                      Obx(() {
                        final currentValue = controller.selectedState;
                        final safeValue = uniqueStates.contains(currentValue)
                            ? currentValue
                            : null;

                        return DropdownButtonFormField<String>(
                          value: safeValue,
                          decoration: InputDecoration(
                            labelText: 'Select State',
                            prefixIcon: Icon(Icons.map, color: AppTheme.primaryBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppTheme.lightGray,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Select a state',
                                style: TextStyle(color: AppTheme.mediumGray),
                              ),
                            ),
                            ...uniqueStates.map((stateName) {
                              return DropdownMenuItem<String>(
                                value: stateName,
                                child: Text(stateName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectStateAndFetchZipCodes(value);
                            } else {
                              controller.selectStateAndFetchZipCodes('');
                            }
                          },
                        );
                      }),
                    if (controller.isLoadingZipCodes) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading ZIP codes...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

              // Claimed ZIP Codes
              Obx(
                () {
                  if (controller.claimedZipCodes.isEmpty) {
                    return _buildEmptyState(
                      context,
                      'No claimed ZIP codes',
                      'Start by claiming a ZIP code below',
                      icon: Icons.location_on_outlined,
                      infoMessage: 'Claim ZIP codes in your licensed states to appear in buyer searches',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Claimed ZIP Codes (${controller.claimedZipCodes.length}/6)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...controller.claimedZipCodes.map((zip) => RepaintBoundary(
                        child: _buildZipCodeCard(context, zip, true),
                      )),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Available ZIP Codes Header
              Text(
                'Available ZIP Codes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
        
        // Available ZIP Codes List (optimized with SliverList)
        Obx(
          () {
            if (controller.selectedState == null) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildEmptyState(
                    context,
                    'Select a State',
                    'Please select a state above to view available ZIP codes',
                    icon: Icons.location_off_outlined,
                  ),
                ),
              );
            }
            
            if (controller.isLoadingZipCodes) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryBlue),
                          const SizedBox(height: 16),
                          Text(
                            'Loading ZIP codes...',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            
            if (controller.availableZipCodes.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildEmptyState(
                    context,
                    'No available ZIP codes',
                    'All ZIP codes in ${controller.selectedState} are claimed',
                    icon: Icons.location_off_outlined,
                  ),
                ),
              );
            }
            
            return SliverPadding(
              padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final zip = controller.availableZipCodes[index];
                    return RepaintBoundary(
                      child: _buildZipCodeCard(context, zip, false),
                    );
                  },
                  childCount: controller.availableZipCodes.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildZipCodeCard(
    BuildContext context,
    ZipCodeModel zip,
    bool isClaimed,
  ) {
    // Pre-compute expensive string formatting
    final formattedPopulation = zip.population.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formattedPrice = '\$${zip.calculatedPrice.toStringAsFixed(2)}/month';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zip.zipCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zip.state} • Population: $formattedPopulation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedPrice,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isClaimed)
              Obx(
                () => CustomButton(
                  text: 'Release',
                  onPressed: controller.isZipProcessing(zip.zipCode)
                      ? null
                      : () => controller.releaseZipCode(zip),
                  isOutlined: true,
                  // Let button size itself; show loader per ZIP
                  isLoading: controller.isZipProcessing(zip.zipCode),
                ),
              )
            else
              Obx(
                () => CustomButton(
                  text: 'Claim',
                  onPressed: controller.isZipProcessing(zip.zipCode)
                      ? null
                      : () => controller.claimZipCode(zip),
                  isLoading: controller.isZipProcessing(zip.zipCode),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyListings(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.lightGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Listings',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.black,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.currentListingCount}/${controller.freeListingLimit} free listings used',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: controller.canAddFreeListing
                            ? AppTheme.lightGreen.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.canAddFreeListing
                            ? 'Free Listings Available'
                            : '\$${controller.additionalListingPrice.toStringAsFixed(2)} per listing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: controller.canAddFreeListing
                              ? AppTheme.lightGreen
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: controller.canAddFreeListing
                      ? 'Add New Listing'
                      : 'Buy Slot',
                  onPressed: controller.canAddFreeListing
                      ? () => Get.toNamed('/add-listing')
                      : () => _showBuySlotDialog(context),
                  icon: controller.canAddFreeListing
                      ? Icons.add_circle_outline
                      : Icons.shopping_cart_outlined,
                  width: double.infinity,
                  height: 48,
                ),
                if (!controller.canAddFreeListing) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '\$${controller.additionalListingPrice.toStringAsFixed(2)} one-time fee per listing until it sells. All agents can add listings, subscription not required.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
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

          const SizedBox(height: 24),

          // Filters Section
          _buildFiltersSection(context),

          const SizedBox(height: 24),

          // Enhanced Stats Section
          _buildListingStats(context),

          const SizedBox(height: 24),

          // Listings List
          Obx(() {
            if (controller.myListings.isEmpty && controller.allListings.isNotEmpty) {
              return _buildNoFilterResults(context);
            }
            
            if (controller.myListings.isEmpty) {
              return _buildEmptyListingsState(context);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.myListings.length,
              itemBuilder: (context, index) {
                final listing = controller.myListings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildListingCard(context, listing),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListingStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Lifecycle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'For Sale',
                controller.activeListingsCount.toString(),
                Icons.home_work_outlined,
                AppTheme.primaryBlue,
                'Live listings',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Under Contract',
                controller.pendingListingsCount.toString(),
                Icons.rule_folder_outlined,
                Colors.orange,
                'Offer accepted',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Sold',
                controller.soldListingsCount.toString(),
                Icons.verified_outlined,
                Colors.teal,
                'Closed + recorded',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Needs Update',
                controller.staleListingsCount.toString(),
                Icons.warning_amber_outlined,
                Colors.deepOrange,
                '60+ days For Sale',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Engagement',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Views',
                controller.totalListingViews.toString(),
                Icons.visibility_outlined,
                AppTheme.lightGreen,
                'Total views',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Contacts',
                controller.totalListingContacts.toString(),
                Icons.phone_outlined,
                AppTheme.mediumGray,
                'Leads generated',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, AgentListingModel listing) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: listing.isActive
              ? AppTheme.lightGreen.withOpacity(0.3)
              : AppTheme.mediumGray.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image placeholder and status
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.lightGreen.withOpacity(0.05),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Property image carousel
                if (listing.photoUrls.isNotEmpty) ...[
                  _ListingImageCarousel(
                    listingId: listing.id,
                    listingTitle: listing.title,
                    photoUrls: listing.photoUrls,
                  ),
                ]
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 40,
                          color: AppTheme.primaryBlue.withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No Image',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Status chip with quick actions
                Positioned(
                  top: 12,
                  right: 12,
                  child: PopupMenuButton<MarketStatus>(
                    tooltip: 'Update listing status',
                    onSelected: (status) => controller
                        .updateListingMarketStatus(listing.id, status),
                    itemBuilder: (context) => MarketStatus.values
                        .map(
                          (status) => PopupMenuItem<MarketStatus>(
                            value: status,
                            child: Row(
                              children: [
                                if (listing.marketStatus == status)
                                  const Icon(Icons.check, size: 16)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(
                                  status == MarketStatus.pending
                                      ? 'Mark Under Contract'
                                      : status == MarketStatus.sold
                                      ? 'Mark Sold'
                                      : 'Mark For Sale',
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: _buildStatusChip(context, listing),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            listing.formattedPrice,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Address
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.mediumGray,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.fullAddress,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Performance Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildListingStatItem(
                          context,
                          'Views',
                          listing.viewCount.toString(),
                          Icons.visibility_outlined,
                          AppTheme.primaryBlue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.mediumGray.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildListingStatItem(
                          context,
                          'Contacts',
                          listing.contactCount.toString(),
                          Icons.phone_outlined,
                          AppTheme.lightGreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.mediumGray.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildListingStatItem(
                          context,
                          'Searches',
                          listing.searchCount.toString(),
                          Icons.search_outlined,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                if (listing.isStale) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This listing has been For Sale for 60+ days. Update the status or refresh the price/photos to keep it trustworthy.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Edit',
                        onPressed: () =>
                            _showEditListingDialog(context, listing),
                        icon: Icons.edit_outlined,
                        isOutlined: true,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: listing.isActive ? 'Deactivate' : 'Activate',
                        onPressed: () =>
                            controller.toggleListingStatus(listing.id),
                        icon: listing.isActive
                            ? Icons.pause_outlined
                            : Icons.play_arrow_outlined,
                        isOutlined: true,
                        height: 44,
                        backgroundColor: listing.isActive
                            ? Colors.orange
                            : AppTheme.lightGreen,
                        textColor: listing.isActive
                            ? Colors.orange
                            : AppTheme.lightGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () =>
                            _showDeleteConfirmation(context, listing),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
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

  Widget _buildStatusChip(BuildContext context, AgentListingModel listing) {
    Color color = AppTheme.mediumGray;
    IconData icon = Icons.help_outline;
    String label = 'Status';

    if (!listing.isApproved) {
      color = Colors.orange;
      icon = Icons.pending_actions;
      label = 'Pending Approval';
    } else if (listing.rejectionReason != null) {
      color = Colors.red;
      icon = Icons.cancel_outlined;
      label = 'Needs Attention';
    } else {
      switch (listing.marketStatus) {
        case MarketStatus.forSale:
          color = AppTheme.lightGreen;
          icon = Icons.check_circle_outline;
          label = 'For Sale';
          break;
        case MarketStatus.pending:
          color = Colors.orange;
          icon = Icons.rule_folder_outlined;
          label = 'Under Contract';
          break;
        case MarketStatus.sold:
          color = Colors.teal;
          icon = Icons.verified_outlined;
          label = 'Sold';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildListingStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightGray.withOpacity(0.5),
            ),
          ),
          child: TextField(
            onChanged: (value) => controller.setSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Search by title, address, city...',
              prefixIcon: Icon(Icons.search, color: AppTheme.mediumGray),
              suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.mediumGray),
                      onPressed: () => controller.setSearchQuery(''),
                    )
                  : const SizedBox.shrink()),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Status Filter Chips
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                context,
                'All',
                controller.selectedStatusFilter == null,
                () => controller.setStatusFilter(null),
              ),
              _buildFilterChip(
                context,
                'For Sale',
                controller.selectedStatusFilter == MarketStatus.forSale,
                () => controller.setStatusFilter(MarketStatus.forSale),
              ),
              _buildFilterChip(
                context,
                'Pending',
                controller.selectedStatusFilter == MarketStatus.pending,
                () => controller.setStatusFilter(MarketStatus.pending),
              ),
              _buildFilterChip(
                context,
                'Sold',
                controller.selectedStatusFilter == MarketStatus.sold,
                () => controller.setStatusFilter(MarketStatus.sold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.lightGray.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.white : AppTheme.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNoFilterResults(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightGray.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off,
            size: 48,
            color: AppTheme.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'No listings match your filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => controller.clearFilters(),
            child: Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListingsState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightGray.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_outlined,
              size: 48,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No listings yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start building your portfolio by adding your first property listing. Showcase your properties to attract potential buyers.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Add Your First Listing',
            onPressed: () => Get.toNamed('/add-listing'),
            icon: Icons.add_circle_outline,
            width: double.infinity,
            height: 52,
          ),
        ],
      ),
    );
  }

  void _showBuySlotDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Buy Listing Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve used your 3 free listings. Additional listings cost \$${controller.additionalListingPrice.toStringAsFixed(2)} per listing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'One-Time Fee',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This one-time fee covers your listing until it sells. All agents can add listings, subscription not required.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.darkGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Process payment and then navigate to add listing
              controller.purchaseAdditionalListing().then((_) {
                Get.toNamed('/add-listing');
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Pay \$${controller.additionalListingPrice.toStringAsFixed(2)} & Add Listing',
            ),
          ),
        ],
      ),
    );
  }

  void _showEditListingDialog(BuildContext context, AgentListingModel listing) {
    // Create controllers with existing values
    final titleController = TextEditingController(text: listing.title);
    final descriptionController = TextEditingController(text: listing.description);
    final priceController = TextEditingController(text: (listing.priceCents / 100).toStringAsFixed(0));
    final addressController = TextEditingController(text: listing.address);
    final cityController = TextEditingController(text: listing.city);
    final stateController = TextEditingController(text: listing.state);
    final zipCodeController = TextEditingController(text: listing.zipCode);
    final bacPercentController = TextEditingController(text: listing.bacPercent.toString());
    
    final isListingAgent = listing.isListingAgent.obs;
    final dualAgencyAllowed = listing.dualAgencyAllowed.obs;
    final isLoading = false.obs;
    // Image management
    final currentImages = listing.photoUrls.toList().obs;
    final newImages = <File>[].obs;
    final ImagePicker imagePicker = ImagePicker();
    bool isDisposed = false;

    void disposeControllers() {
      if (!isDisposed) {
        isDisposed = true;
        titleController.dispose();
        descriptionController.dispose();
        priceController.dispose();
        addressController.dispose();
        cityController.dispose();
        stateController.dispose();
        zipCodeController.dispose();
        bacPercentController.dispose();
      }
    }

    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 700.w,
            maxHeight: Get.height * 0.92,
          ),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28.r),
                    topRight: Radius.circular(28.r),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: AppTheme.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Listing',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Update your property details',
                            style: TextStyle(
                              color: AppTheme.white.withOpacity(0.9),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppTheme.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(28.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Card
                      _buildEditSectionCard(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Basic Information',
                        children: [
                          SizedBox(height: 8.h),
                          CustomTextField(
                            controller: titleController,
                            labelText: 'Property Title',
                            hintText: 'e.g., Beautiful 3BR Condo',
                            prefixIcon: Icons.title_rounded,
                          ),
                          SizedBox(height: 20.h),
                          CustomTextField(
                            controller: descriptionController,
                            labelText: 'Description',
                            hintText: 'Describe your property in detail...',
                            maxLines: 5,
                            prefixIcon: Icons.description_rounded,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      
                      // Property Images Card
                      _buildEditSectionCard(
                        context,
                        icon: Icons.photo_library_rounded,
                        title: 'Property Images',
                        children: [
                          SizedBox(height: 8.h),
                          Obx(() => _buildImageManagementSection(
                            context,
                            currentImages,
                            newImages,
                            imagePicker,
                          )),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      
                      // Price Information Card
                      _buildEditSectionCard(
                        context,
                        icon: Icons.attach_money_rounded,
                        title: 'Pricing Details',
                        children: [
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: CustomTextField(
                                  controller: priceController,
                                  labelText: 'Price',
                                  hintText: 'e.g., 1250000',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.attach_money_rounded,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: CustomTextField(
                                  controller: bacPercentController,
                                  labelText: 'BAC %',
                                  hintText: '2.5',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.percent_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      
                      // Address Information Card
                      _buildEditSectionCard(
                        context,
                        icon: Icons.location_on_rounded,
                        title: 'Property Address',
                        children: [
                          SizedBox(height: 8.h),
                          CustomTextField(
                            controller: addressController,
                            labelText: 'Street Address',
                            hintText: 'e.g., 123 Main Street',
                            prefixIcon: Icons.home_rounded,
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: CustomTextField(
                                  controller: cityController,
                                  labelText: 'City',
                                  hintText: 'e.g., Los Angeles',
                                  prefixIcon: Icons.location_city_rounded,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: CustomTextField(
                                  controller: stateController,
                                  labelText: 'State',
                                  hintText: 'CA',
                                  prefixIcon: Icons.map_rounded,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: CustomTextField(
                                  controller: zipCodeController,
                                  labelText: 'ZIP Code',
                                  hintText: '90001',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.pin_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      
                      // Settings Card
                      _buildEditSectionCard(
                        context,
                        icon: Icons.settings_rounded,
                        title: 'Listing Settings',
                        children: [
                          SizedBox(height: 8.h),
                          Obx(() => _buildToggleSwitch(
                            context,
                            title: 'I am the Listing Agent',
                            subtitle: 'You are the listing agent for this property',
                            value: isListingAgent.value,
                            onChanged: (value) => isListingAgent.value = value,
                          )),
                          SizedBox(height: 16.h),
                          Obx(() => _buildToggleSwitch(
                            context,
                            title: 'Dual Agency Allowed',
                            subtitle: 'Allow representing both buyer and seller',
                            value: dualAgencyAllowed.value,
                            onChanged: (value) => dualAgencyAllowed.value = value,
                          )),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
              // Premium Footer
              Container(
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28.r),
                    bottomRight: Radius.circular(28.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 18.h),
                          side: BorderSide(color: AppTheme.mediumGray, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.darkGray,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 2,
                      child: Obx(() => Container(
                        decoration: BoxDecoration(
                          gradient: isLoading.value
                              ? null
                              : LinearGradient(
                                  colors: AppTheme.primaryGradient,
                                ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: isLoading.value
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading.value
                              ? null
                              : () async {
                                  // Validate fields
                                  if (titleController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a property title');
                                    return;
                                  }
                                  if (descriptionController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a description');
                                    return;
                                  }
                                  if (priceController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a price');
                                    return;
                                  }
                                  if (addressController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a street address');
                                    return;
                                  }
                                  if (cityController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a city');
                                    return;
                                  }
                                  if (stateController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a state');
                                    return;
                                  }
                                  if (zipCodeController.text.trim().isEmpty) {
                                    SnackbarHelper.showError('Please enter a ZIP code');
                                    return;
                                  }

                                  isLoading.value = true;
                                  
                                  try {
                                    await controller.updateListingViaAPI(
                                      listing.id,
                                      titleController.text.trim(),
                                      descriptionController.text.trim(),
                                      priceController.text.trim(),
                                      addressController.text.trim(),
                                      cityController.text.trim(),
                                      stateController.text.trim(),
                                      zipCodeController.text.trim(),
                                      bacPercentController.text.trim(),
                                      isListingAgent.value,
                                      dualAgencyAllowed.value,
                                      remainingImageUrls: currentImages.toList(),
                                      newImageFiles: newImages.toList(),
                                    );
                                    
                                    Get.back();
                                    
                                    // Wait for dialog to fully close before showing success
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    
                                    SnackbarHelper.showSuccess('Listing updated successfully!');
                                  } catch (e) {
                                    SnackbarHelper.showError('Failed to update listing: ${e.toString()}');
                                  } finally {
                                    isLoading.value = false;
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLoading.value
                                ? AppTheme.primaryBlue.withOpacity(0.6)
                                : Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18.h),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: isLoading.value
                              ? SizedBox(
                                  height: 22.h,
                                  width: 22.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Update Listing',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Dispose controllers after dialog is fully closed
      Future.delayed(const Duration(milliseconds: 300), () {
        disposeControllers();
      });
    });
  }

  Widget _buildEditSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.lightGray.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: value ? AppTheme.primaryBlue.withOpacity(0.3) : AppTheme.lightGray,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryBlue,
              activeTrackColor: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageManagementSection(
    BuildContext context,
    RxList<String> currentImages,
    RxList<File> newImages,
    ImagePicker imagePicker,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Images Grid
        if (currentImages.isNotEmpty || newImages.isNotEmpty) ...[
          Text(
            'Current Images (${currentImages.length + newImages.length})',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 120.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentImages.length + newImages.length,
              itemBuilder: (context, index) {
                if (index < currentImages.length) {
                  // Existing image from URL
                  final imageUrl = currentImages[index];
                  final processedUrl = ImageUrlHelper.buildImageUrl(imageUrl) ?? imageUrl;
                  
                  return Container(
                    width: 120.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.lightGray,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.network(
                            processedUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.lightGray,
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppTheme.mediumGray,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppTheme.lightGray,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                currentImages.removeAt(index);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // New image from file
                  final fileIndex = index - currentImages.length;
                  final imageFile = newImages[fileIndex];
                  
                  return Container(
                    width: 120.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.lightGreen,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            imageFile,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                newImages.removeAt(fileIndex);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 16.h),
        ],
        
        // Add Image Button
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final XFile? image = await imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              
              if (image != null) {
                newImages.add(File(image.path));
              }
            } catch (e) {
              SnackbarHelper.showError('Failed to pick image: ${e.toString()}');
            }
          },
          icon: Icon(Icons.add_photo_alternate_rounded, size: 20.sp),
          label: Text(
            'Add Image',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
            side: BorderSide(
              color: AppTheme.primaryBlue,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
        
        if (currentImages.isEmpty && newImages.isEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            'No images added yet. Tap "Add Image" to upload property photos.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.mediumGray,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AgentListingModel listing,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteListing(listing.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 12),
            const Expanded(child: Text('Logout')),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access your dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authController = Get.find<global.AuthController>();
              authController.logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilling(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscription Summary
          Obx(
            () => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Standard Pricing Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Standard Monthly Price',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.darkGray),
                        ),
                        Text(
                          '\$${controller.getStandardMonthlyPrice().toStringAsFixed(2)}/month',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w500,
                                decoration: controller.hasActivePromo
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Current Monthly Cost (with promo if applicable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Monthly Cost',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.darkGray),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${controller.calculateMonthlyCost().toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: controller.hasActivePromo
                                        ? Colors.green
                                        : AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (controller.hasActivePromo)
                              Text(
                                '70% OFF',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Promo Expiration Info
                    if (controller.hasActivePromo &&
                        controller.subscription?.promoExpiresAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Promo expires: ${controller.subscription!.promoExpiresAt!.toString().split(' ')[0]}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.mediumGray,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ZIP Codes Claimed',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.darkGray),
                        ),
                        Text(
                          '${controller.claimedZipCodes.length}/6',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Active Subscriptions List
          Text(
            'Active Subscriptions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Obx(() {
            final activeSubs = controller.activeSubscriptions;
            
            if (activeSubs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No active subscriptions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              );
            }

            return Column(
              children: activeSubs.map((subscription) {
                return _buildActiveSubscriptionCard(context, subscription);
              }).toList(),
            );
          }),

          const SizedBox(height: 20),

          // Promo Code Input Section
          Obx(
            () => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!controller.hasActivePromo) ...[
                      Text(
                        'Have a promo code?',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  controller.setPromoCodeInput(value),
                              decoration: InputDecoration(
                                hintText: 'Enter promo code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomButton(
                            text: 'Apply',
                            onPressed: () {
                              if (controller.promoCodeInput.isEmpty) {
                                SnackbarHelper.showError('Please enter a promo code');
                                return;
                              }
                              controller.applyPromoCode(
                                controller.promoCodeInput,
                              );
                            },
                            width: 80,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you have a promo code, please enter it above',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.mediumGray),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Generate Promo Code for Loan Officers
                    Text(
                      'Share with Loan Officers',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            color: AppTheme.black,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a promo code to share with loan officers. They\'ll get 6 months free!',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.mediumGray),
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: 'Generate Promo Code',
                      onPressed: () =>
                          controller.generatePromoCodeForLoanOfficer(),
                      isOutlined: true,
                      width: double.infinity,
                    ),

                    // Display Generated Codes
                    if (controller.generatedPromoCodes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Your Generated Codes:',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: AppTheme.darkGray,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...controller.generatedPromoCodes.map(
                        (promo) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        promo.code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryBlue,
                                            ),
                                      ),
                                      Text(
                                        promo.description ??
                                            '6 Months Free',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.mediumGray,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    // Copy to clipboard
                                    // Clipboard.setData(ClipboardData(text: promo.code));
                                    SnackbarHelper.showSuccess('Promo code copied to clipboard', title: 'Copied');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Payment History
          Text(
            'Payment History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Display subscriptions from API
          Obx(() {
            if (controller.subscriptions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No payment history available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              );
            }

            return Column(
              children: controller.subscriptions.map((subscription) {
                // Format date from createdAt or subscriptionStart
                final dateStr = subscription['createdAt']?.toString() ??
                    subscription['subscriptionStart']?.toString() ??
                    '';
                final date = DateTime.tryParse(dateStr);
                final monthYear = date != null
                    ? '${_getMonthName(date.month)} ${date.year}'
                    : 'Unknown Date';

                // Format amount
                final amount = subscription['amountPaid'] as double? ?? 0.0;
                final amountStr = '\$${amount.toStringAsFixed(2)}';

                // Format status
                final status = subscription['subscriptionStatus']?.toString() ?? '';
                final displayStatus = _formatSubscriptionStatus(status);

                // Payment History only shows payment records, no cancel buttons
                return _buildPaymentItem(
                  context,
                  monthYear,
                  amountStr,
                  displayStatus,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(
    BuildContext context,
    Map<String, dynamic> subscription,
  ) {
    // Format date from createdAt or subscriptionStart
    final dateStr = subscription['createdAt']?.toString() ??
        subscription['subscriptionStart']?.toString() ??
        '';
    final date = DateTime.tryParse(dateStr);
    final monthYear = date != null
        ? '${_getMonthName(date.month)} ${date.year}'
        : 'Unknown Date';

    // Format amount
    final amount = subscription['amountPaid'] as double? ?? 0.0;
    final amountStr = '\$${amount.toStringAsFixed(2)}';

    // Format status
    final status = subscription['subscriptionStatus']?.toString() ?? '';
    final displayStatus = _formatSubscriptionStatus(status);

    // Get stripe customer ID for cancellation
    final stripeCustomerId = subscription['stripeCustomerId']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthYear,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountStr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: displayStatus == 'Paid' || displayStatus == 'Active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: displayStatus == 'Paid' || displayStatus == 'Active'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (stripeCustomerId != null && stripeCustomerId.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelConfirmationForSubscription(
                    context,
                    stripeCustomerId,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel Subscription',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmationForSubscription(
    BuildContext context,
    String stripeCustomerId,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this subscription?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your subscription will remain active for 30 days from today. You can cancel anytime with 30 days\' notice.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.cancelSubscription(stripeCustomerId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    // Use the active subscription's stripeCustomerId if available
    final activeSub = controller.activeSubscriptionFromAPI;
    final stripeCustomerId = activeSub?['stripeCustomerId']?.toString();
    
    if (stripeCustomerId != null && stripeCustomerId.isNotEmpty) {
      _showCancelConfirmationForSubscription(context, stripeCustomerId);
    } else {
      // Fallback to old method if no stripeCustomerId
      Get.dialog(
        AlertDialog(
          title: const Text('Cancel Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel your subscription?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your subscription will remain active for 30 days from today. You can cancel anytime with 30 days\' notice.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Subscription'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.cancelSubscription();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Subscription'),
            ),
          ],
        ),
      );
    }
  }


  Widget _buildPaymentItem(
    BuildContext context,
    String month,
    String amount,
    String status, {
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        month,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (canCancel && onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Cancel Subscription',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper method to get month name from month number
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Unknown';
  }

  /// Helper method to format subscription status for display
  String _formatSubscriptionStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'active' || lowerStatus == 'paid') {
      return 'Paid';
    } else if (lowerStatus == 'canceled' || lowerStatus == 'cancelled') {
      return 'Canceled';
    } else if (lowerStatus == 'past_due' || lowerStatus == 'pastdue') {
      return 'Past Due';
    } else if (lowerStatus == 'unpaid') {
      return 'Unpaid';
    } else if (lowerStatus == 'trialing') {
      return 'Trialing';
    }
    // Capitalize first letter for unknown statuses
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Widget _buildStats(BuildContext context) {
    return Obx(() {
      // Ensure leads are loaded for stats
      if (controller.leads.isEmpty && !controller.isLoadingLeads) {
        Future.microtask(() => controller.fetchLeads());
      }

      // Get dynamic data from controller
      final totalLeads = controller.totalLeads;
      final conversions = controller.conversions;
      final closeRate = controller.closeRate;
      
      // Calculate month-over-month changes
      final leadsChange = controller.calculateMonthOverMonthChange('leads');
      final conversionsChange = controller.calculateMonthOverMonthChange('conversions');
      final closeRateChange = controller.calculateMonthOverMonthChange('closeRate');
      
      // Get monthly data
      final monthlyLeadsData = controller.getMonthlyLeadsData();
      final monthlyLeads = monthlyLeadsData['values'] as List<int>;
      final months = monthlyLeadsData['labels'] as List<String>;
      final monthsCount = monthlyLeadsData['count'] as int;
      final screenWidth = MediaQuery.of(context).size.width;
      final cardWidth = (screenWidth - 40 - 12) / 2;
      final now = DateTime.now();
      final monthLabel = _getMonthName(now.month);
      
      // Get activity breakdown
      final activityData = controller.getActivityBreakdown();

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Snapshot for $monthLabel ${now.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last 30 days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Stats
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildStatsCard(
                    context,
                    'Total Leads',
                    totalLeads.toString(),
                    Icons.people,
                    AppTheme.primaryBlue,
                    '$leadsChange vs last month',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatsCard(
                    context,
                    'Conversions',
                    conversions.toString(),
                    Icons.trending_up,
                    AppTheme.lightGreen,
                    '$conversionsChange vs last month',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatsCard(
                    context,
                    'Close Rate',
                    '${closeRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.orange,
                    '$closeRateChange vs last month',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Portfolio Snapshot
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard(
                            context,
                            'Active Listings',
                            controller.currentListingCount.toString(),
                            Icons.home_work_outlined,
                            AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStatCard(
                            context,
                            'Claimed ZIPs',
                            controller.claimedZipCodes.length.toString(),
                            Icons.place_outlined,
                            AppTheme.lightGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMiniStatCard(
                      context,
                      'Active Subscriptions',
                      controller.activeSubscriptions.length.toString(),
                      Icons.credit_card,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Monthly Leads Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Leads',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$monthsCount months',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (monthlyLeads.isNotEmpty)
                      _buildBarChart(monthlyLeads, months)
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No leads data available',
                            style: TextStyle(color: AppTheme.mediumGray),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

            // Activity Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatsActivityItem(
                      'Property Views',
                      activityData['Property Views'] ?? 0,
                      AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildStatsActivityItem(
                      'Inquiries',
                      activityData['Inquiries'] ?? 0,
                      AppTheme.lightGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildStatsActivityItem(
                      'Showings',
                      activityData['Showings'] ?? 0,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildStatsActivityItem(
                      'Offers',
                      activityData['Offers'] ?? 0,
                      Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final trimmedSubtitle = subtitle.trim();
    final isNegative = trimmedSubtitle.startsWith('-');
    final trendColor = isNegative ? Colors.redAccent : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (trimmedSubtitle.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trimmedSubtitle,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.black,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<int> data, List<String> labels) {
    if (data.isEmpty) {
      return const SizedBox(height: 200);
    }
    
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    
    // Prevent division by zero
    if (maxValue == 0) {
      return SizedBox(
        height: 200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(data.length, (index) {
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4.0, // Minimum height for visibility
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.3),
                          AppTheme.primaryBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.mediumGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data[index].toString(),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(data.length, (index) {
              final value = data[index];
              final height = ((value / maxValue) * 150).clamp(4.0, 150.0); // Clamp to prevent NaN and ensure minimum height

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryBlue.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsActivityItem(String label, int value, Color color) {
    final maxValue = 400;
    final progress = value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle, {
    String? infoMessage,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.people_outline,
                size: 64,
                color: AppTheme.primaryBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
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
            if (infoMessage != null) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        infoMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeads(BuildContext context) {
    // Fetch leads when this widget is built (when leads tab is opened)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedTab == 5 && !controller.isLoadingLeads) {
        // Check if leads are empty or if we should refresh
        if (controller.leads.isEmpty) {
          controller.refreshLeads();
        } else {
          // Even if leads exist, refresh to get latest data
          controller.refreshLeads();
        }
      }
    });
    
    return Obx(() {
      if (controller.isLoadingLeads && controller.leads.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Loading leads...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.leads.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => controller.refreshLeads(),
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEmptyState(
                    context,
                    'No Leads',
                    'No leads for this agent.',
                    infoMessage: 'Leads will appear here when buyers contact you',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe_down,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Swipe down to refresh and load new leads',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshLeads(),
        color: AppTheme.primaryBlue,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: controller.leads.length + 1, // +1 for the hint message
          itemBuilder: (context, index) {
            // Show hint message at the top
            if (index == 0) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe_down,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Swipe down to refresh and load new leads',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }
            // Show lead cards
            final lead = controller.leads[index - 1];
            return _buildLeadCard(context, lead);
          },
        ),
      );
    });
  }

  Widget _buildLeadCard(BuildContext context, LeadModel lead) {
    final buyerInfo = lead.buyerInfo;
    final isBuying = lead.isBuyingLead;
    final gradientColors = isBuying
        ? [AppTheme.primaryBlue, AppTheme.lightBlue, AppTheme.skyBlue]
        : [AppTheme.lightGreen, Color(0xFF34D399), Color(0xFF6EE7B7)];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                .withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                      .withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Buying/Selling Lead Badge
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBuying ? Icons.shopping_bag_rounded : Icons.sell_rounded,
                        color: Colors.white,
                          size: 16,
                      ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                        isBuying ? 'Buying Lead' : 'Selling Lead',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(width: 8),
                // Lead Status Badge
                if (lead.leadStatus != null && lead.leadStatus!.isNotEmpty) ...[
                  Flexible(
                    flex: 2,
                    child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                        color: lead.isCompleted
                            ? AppTheme.primaryBlue.withOpacity(0.95)
                            : lead.isAccepted 
                                ? AppTheme.lightGreen.withOpacity(0.95)
                                : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: (lead.isCompleted || lead.isAccepted)
                            ? Border.all(color: Colors.white, width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: (lead.isCompleted || lead.isAccepted)
                                ? Colors.black.withOpacity(0.15)
                                : Colors.transparent,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                            lead.isCompleted 
                                ? Icons.check_circle_outline
                                : lead.isAccepted 
                                    ? Icons.check_circle 
                                    : Icons.pending,
                        color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              lead.isCompleted 
                                  ? 'COMPLETED'
                                  : lead.leadStatus!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                      ),
                      const SizedBox(width: 6),
                ],
                // Date Badge
                Flexible(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                        lead.formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                              fontSize: 10,
                          fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lead Status Container (if accepted or completed)
                if (lead.isAccepted || lead.isCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: lead.isCompleted
                          ? AppTheme.primaryBlue.withOpacity(0.1)
                          : AppTheme.lightGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: lead.isCompleted
                            ? AppTheme.primaryBlue
                            : AppTheme.lightGreen,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lead.isCompleted
                              ? Icons.check_circle_outline
                              : Icons.check_circle,
                          color: lead.isCompleted
                              ? AppTheme.primaryBlue
                              : AppTheme.lightGreen,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.isCompleted ? 'Lead Completed' : 'Lead Accepted',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: lead.isCompleted
                                      ? AppTheme.primaryBlue
                                      : AppTheme.lightGreen,
                                ),
                              ),
                              if (lead.agentResponseNote != null && !lead.isCompleted) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  lead.agentResponseNote!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                // Enhanced Buyer Info Section
                if (buyerInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.lightGray,
                          Colors.white,
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
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.transparent,
                            backgroundImage: ImageUrlHelper.buildImageUrl(buyerInfo.profilePic) != null
                                ? NetworkImage(ImageUrlHelper.buildImageUrl(buyerInfo.profilePic)!)
                                : null,
                            child: buyerInfo.profilePic == null ||
                                    buyerInfo.profilePic!.isEmpty
                                ? Text(
                                    (buyerInfo.fullname ?? 'B')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                buyerInfo.fullname ?? 'Unknown Buyer',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.black,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              if (buyerInfo.email != null &&
                                  buyerInfo.email!.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: AppTheme.mediumGray,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        buyerInfo.email!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.mediumGray,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (buyerInfo.phone != null &&
                                  buyerInfo.phone!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: AppTheme.mediumGray,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        buyerInfo.phone!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.mediumGray,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                  const SizedBox(height: 20),
                ],

                // Property Information Section
                if (lead.propertyInformation != null &&
                    lead.propertyInformation!.fullAddress !=
                        'Address not provided') ...[
                  _buildEnhancedInfoCard(
                    context,
                    Icons.location_on_rounded,
                    'Property Location',
                    lead.propertyInformation!.fullAddress,
                    isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen,
                  ),
                  const SizedBox(height: 16),
                ],

                // Key Details Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (lead.propertyType != null && lead.propertyType!.isNotEmpty)
                      _buildDetailChip(
                        context,
                        Icons.home_rounded,
                        'Type',
                        lead.propertyType!,
                      ),
                    if (lead.priceRange != null && lead.priceRange!.isNotEmpty)
                      _buildDetailChip(
                        context,
                        Icons.attach_money_rounded,
                        'Price',
                        lead.priceRange!,
                      ),
                    if (lead.bedrooms != null)
                      _buildDetailChip(
                        context,
                        Icons.bed_rounded,
                        'Beds',
                        '${lead.bedrooms}',
                      ),
                    if (lead.bathrooms != null)
                      _buildDetailChip(
                        context,
                        Icons.bathtub_rounded,
                        'Baths',
                        '${lead.bathrooms}',
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Additional Info Section
                if ((lead.bestTime != null && lead.bestTime!.isNotEmpty) ||
                    (lead.preferredContact != null &&
                        lead.preferredContact!.isNotEmpty)) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.04),
                          AppTheme.lightGray.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (lead.bestTime != null && lead.bestTime!.isNotEmpty) ...[
                          _buildInfoRow(
                            context,
                            Icons.access_time_rounded,
                            'Best Time',
                            lead.bestTime!,
                          ),
                          if (lead.preferredContact != null &&
                              lead.preferredContact!.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        if (lead.preferredContact != null &&
                            lead.preferredContact!.isNotEmpty)
                          _buildInfoRow(
                            context,
                            Icons.phone_rounded,
                            'Preferred Contact',
                            lead.preferredContact!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Enhanced Comments Section
                if (lead.comments != null && lead.comments!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                              .withOpacity(0.05),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.format_quote_rounded,
                            size: 20,
                            color: isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lead.comments!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.darkGray,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons Row
                Row(
                  children: [
                    // Contact/Open Chat Button
                    Expanded(
                      child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.contactBuyerFromLead(lead),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      lead.isAccepted ? 'Open Chat' : 'Contact Buyer',
                                      style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                                  const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                    ),
                    // Complete Button (only show if lead is accepted but not completed)
                    if (lead.isAccepted && !lead.isCompleted) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.lightGreen,
                                AppTheme.lightGreen.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lightGreen.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => controller.markLeadComplete(lead),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Flexible(
                                      child: Text(
                                        'Complete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.03),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.2),
                  accentColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
              color: accentColor.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.06),
            AppTheme.lightGray.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for line chart
// Image Carousel Widget for Listing Images
class _ListingImageCarousel extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final List<String> photoUrls;

  const _ListingImageCarousel({
    required this.listingId,
    required this.listingTitle,
    required this.photoUrls,
  });

  @override
  State<_ListingImageCarousel> createState() => _ListingImageCarouselState();
}

class _ListingImageCarouselState extends State<_ListingImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.photoUrls.length;
    
    // Print image URLs for debugging
    if (kDebugMode && _currentPage == 0) {
      print('🖼️ ========== LISTING IMAGE NETWORK URL ==========');
      print('📋 Listing ID: ${widget.listingId}');
      print('📋 Listing Title: ${widget.listingTitle}');
      print('📊 Total Photos: $totalImages');
      print('📸 All Photo URLs:');
      for (int i = 0; i < widget.photoUrls.length; i++) {
        final url = widget.photoUrls[i];
        final processed = ImageUrlHelper.buildImageUrl(url) ?? url;
        print('   [$i] Original: $url');
        print('   [$i] Network URL: $processed');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Stack(
        children: [
          // Image Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: totalImages,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final originalUrl = widget.photoUrls[index];
              final processedUrl = ImageUrlHelper.buildImageUrl(originalUrl) ?? originalUrl;
              
              // Print current image URL when displayed
              if (kDebugMode) {
                print('🌐 Image [$index/$totalImages] in Image.network: $processedUrl');
              }
              
              return Image.network(
                processedUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.lightGray,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.lightGray,
                    child: Center(
                      child: SpinKitFadingCircle(
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          // Image Counter (e.g., "1/10")
          if (totalImages > 1)
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1}/$totalImages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          // Page Indicators (dots)
          if (totalImages > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalImages,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 8 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


