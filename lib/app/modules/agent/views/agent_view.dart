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
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/notification_model.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/modules/agent_profile/views/agent_reviews_view.dart';
import 'package:getrebate/app/utils/image_url_helper.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';
import 'package:getrebate/app/widgets/notification_badge_icon.dart';
import 'package:getrebate/app/widgets/rebate_compliance_notice.dart';
import 'package:getrebate/app/services/rebate_states_service.dart';
import 'package:getrebate/app/services/user_service.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/modules/agent_checklist/bindings/agent_checklist_binding.dart';
import 'package:getrebate/app/modules/agent_checklist/views/agent_checklist_view.dart';
import 'package:getrebate/app/modules/agent/views/waiting_list_page.dart';
import 'package:getrebate/app/modules/agent/views/edit_agent_listing_view.dart';
import 'package:getrebate/app/modules/rebate_calculator/views/rebate_calculator_option_bottomsheet.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AgentView extends GetView<AgentController> {
  const AgentView({super.key});
  static final ScrollController _zipScrollController = ScrollController();

  void _scrollToAvailableZipSection(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    controller.setZipSectionTab(1);
  }

  /// Helper function to filter licensed states to only include rebate-allowed states
  Future<List<String>> _filterAllowedStates(List<String> licensedStates) async {
    try {
      final service = RebateStatesService();
      final allowedStates = await service.getAllowedStates();
      final allowedStatesSet = allowedStates.map((s) => s.toUpperCase()).toSet();
      
      // Normalize state names to codes for comparison
      // CRITICAL: Only include states where rebates are allowed
      final stateMap = {
        'Arizona': 'AZ', 'Arkansas': 'AR',
        'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE',
        'District of Columbia': 'DC',
        'Washington, D.C.': 'DC',
        'Washington D.C.': 'DC',
        'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI', 'Idaho': 'ID',
        'Illinois': 'IL', 'Indiana': 'IN',
        'Kentucky': 'KY', 'Maine': 'ME', 'Maryland': 'MD',
        'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN',
        'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
        'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY',
        'North Carolina': 'NC', 'Ohio': 'OH',
        'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
        'South Dakota': 'SD', 'Texas': 'TX', 'Utah': 'UT',
        'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
        'Wisconsin': 'WI', 'Wyoming': 'WY',
      };
      
      return licensedStates.where((state) {
        String stateCode;
        if (state.length == 2 && state == state.toUpperCase()) {
          stateCode = state.toUpperCase();
        } else {
          stateCode = (stateMap[state] ?? state).toUpperCase();
        }
        return allowedStatesSet.contains(stateCode);
      }).toList();
    } catch (e) {
      // On error, return all licensed states (fallback)
      return licensedStates;
    }
  }

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
          Obx(
            () => controller.showZipSelectionFirst
                ? TextButton(
                    onPressed: controller.skipZipSelection,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.message, color: AppTheme.white),
            onPressed: () => Get.toNamed('/messages'),
            tooltip: 'Messages',
          ),
          Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: const NotificationBadgeIcon(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          // firstZipCodeClaimed is pre-fetched during splash, so no loading needed here
          if (controller.showZipSelectionFirst) {
            return Column(
              children: [Expanded(child: _buildZipManagement(context))],
            );
          }
          return Column(
            children: [
              _buildTabs(context),
              Expanded(child: _buildContent(context)),
            ],
          );
        }),
      ),
      floatingActionButton: Obx(() {
        if (controller.selectedTab == 2) {
          // My Listings tab - Always allow adding listing (ZIP code selection happens in add_listing_view)
          return FloatingActionButton.extended(
            onPressed: () => _handleAddListing(context),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Listing',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                    'Agent Compliance Checklist',
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
              'Follow these step-by-step checklists to stay compliant in rebate transactions and keep your buyer/seller experience smooth from offer to closing.',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.lightGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Includes complete compliance checklists for both buying/building and selling transactions.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use these every time to handle disclosures correctly, coordinate with lenders/title, and protect your transaction compliance.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'View Complete Checklist',
              onPressed: () => Get.toNamed('/rebate-checklist'),
              icon: Icons.assignment_outlined,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Profile & Setup Guide',
              onPressed: () {
                Get.to(
                  () => const AgentChecklistView(),
                  binding: AgentChecklistBinding(),
                );
              },
              icon: Icons.lightbulb_outline,
              isOutlined: true,
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
              .fadeIn(
                duration: 250.ms,
                delay: (index * 50).ms,
                curve: Curves.easeOut,
              );
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
                  height: 60.h,
                  fontSize: 11.sp,
                  maxLines: 2,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'View Billing',
                  onPressed: () => controller.setSelectedTab(4),
                  icon: Icons.payment,
                  isOutlined: true,
                  height: 60.h,
                  fontSize: 11.sp,
                  maxLines: 2,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Compliance Checklist',
                  onPressed: () => Get.toNamed('/rebate-checklist'),
                  icon: Icons.assignment_outlined,
                  isOutlined: true,
                  height: 60.h,
                  fontSize: 11.sp,
                  maxLines: 2,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Rebate Calculator',
                  onPressed: () {
                    Get.bottomSheet(
                      const RebateCalculatorOptionsBottomSheet(),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  },
                  icon: Icons.calculate_outlined,
                  isOutlined: true,
                  height: 60.h,
                  fontSize: 11.sp,
                  maxLines: 2,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Profile',
                  onPressed: () => Get.toNamed(AppPages.AGENT_EDIT_PROFILE),
                  icon: Icons.person_outline_rounded,
                  isOutlined: true,
                  height: 56.h,
                  fontSize: 12.sp,
                  maxLines: 1,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'View Reviews',
                  onPressed: _openAgentReviewsPage,
                  icon: Icons.rate_review_outlined,
                  isOutlined: true,
                  height: 56.h,
                  fontSize: 12.sp,
                  maxLines: 1,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAgentReviewsPage() async {
    try {
      final authController = Get.find<global.AuthController>();
      final currentUser = authController.currentUser;
      if (currentUser == null) {
        SnackbarHelper.showError('Unable to load reviews. Please login again.');
        return;
      }

      final userService = UserService();
      final freshUser = await userService.getUserRawById(currentUser.id);

      final merged = <String, dynamic>{
        '_id': freshUser['_id']?.toString() ?? currentUser.id,
        'id': freshUser['id']?.toString() ?? currentUser.id,
        'fullname':
            freshUser['fullname']?.toString() ??
            freshUser['name']?.toString() ??
            currentUser.name,
        'email': freshUser['email']?.toString() ?? currentUser.email,
        'phone': freshUser['phone']?.toString() ?? currentUser.phone,
        ...freshUser,
      };

      final agent = AgentModel.fromJson(merged);
      Get.to(() => AgentReviewsView(agent: agent));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to open agent reviews page: $e');
      }
      SnackbarHelper.showError('Unable to open reviews right now.');
    }
  }

  Widget _buildRecentActivity(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      child: Obx(() {
        final notifications = controller.recentNotifications.take(3).toList();
        return Column(
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
            if (controller.isLoadingRecentActivity && notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SpinKitThreeBounce(
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                ),
              )
            else if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No recent activity yet. New leads and updates will appear here.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
              )
            else
              ...notifications.map(
                (notification) => _buildActivityItem(context, notification),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildActivityItem(BuildContext context, NotificationModel notification) {
    final iconColor = _notificationColor(notification.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _notificationIcon(notification.type),
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title.isNotEmpty
                      ? notification.title
                      : notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatNotificationTime(notification.createdAt),
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

  IconData _notificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lead':
        return Icons.person_add_rounded;
      case 'lead_response':
        return Icons.check_circle_rounded;
      case 'lead_completed':
        return Icons.done_all_rounded;
      case 'proposal':
        return Icons.description_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _notificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'lead':
        return AppTheme.primaryBlue;
      case 'lead_response':
        return AppTheme.lightGreen;
      case 'lead_completed':
        return Colors.orange;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _formatNotificationTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }

  Widget _buildZipManagement(BuildContext context) {
    final authController = Get.find<global.AuthController>();

    return CustomScrollView(
      controller: _zipScrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Info message at top of ZIP Codes tab
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'To begin receiving leads and unlock all features, you must claim at least one ZIP code. Follow the prompts below to get started.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.black,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Licensed States Section
              Obx(() {
                final licensedStates =
                    authController.currentUser?.licensedStates ?? [];
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'States you selected during sign up:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.mediumGray),
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
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      state,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
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

              // State Selector for ZIP Codes - Filtered to only show rebate-allowed states
              Obx(() {
                final licensedStates =
                    authController.currentUser?.licensedStates ?? [];
                
                return FutureBuilder<List<String>>(
                  future: _filterAllowedStates(licensedStates),
                  builder: (context, snapshot) {
                    final allowedStates = snapshot.data ?? [];
                    final uniqueStates = allowedStates.toSet().toList()
                      ..sort((a, b) => a.compareTo(b));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select State to View ZIP Codes',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (uniqueStates.isEmpty)
                              Container(
                                padding: EdgeInsets.zero,
                                child: Text(
                                  licensedStates.isEmpty
                                      ? 'No licensed states found. Please update your profile to add licensed states.'
                                      : 'None of your licensed states allow rebates. Please verify rebate eligibility in your states.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.mediumGray),
                                ),
                              )
                            else
                              Obx(() {
                                final currentValue = controller.selectedState;
                                final safeValue =
                                    uniqueStates.contains(currentValue)
                                    ? currentValue
                                    : null;

                                return DropdownButtonFormField<String>(
                                  value: safeValue,
                                  isExpanded: true,
                                  menuMaxHeight: 320,
                                  dropdownColor: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 8,
                                  decoration: InputDecoration(
                                    labelText: 'Select State',
                                    labelStyle: const TextStyle(
                                      color: AppTheme.mediumGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Select a state',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.only(left: 12, right: 8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.map_outlined,
                                        color: AppTheme.primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.primaryBlue.withOpacity(0.04),
                                  ),
                                  selectedItemBuilder: (context) {
                                    return [
                                      Text(
                                        'Select a state',
                                        style: TextStyle(
                                          color: AppTheme.mediumGray,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      ...uniqueStates.map((stateName) => Text(
                                        stateName,
                                        style: const TextStyle(
                                          color: AppTheme.darkGray,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                    ];
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          'Select a state',
                                          style: TextStyle(
                                            color: AppTheme.mediumGray,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...uniqueStates.map((stateName) {
                                      return DropdownMenuItem<String>(
                                        value: stateName,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlue,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                stateName,
                                                style: const TextStyle(
                                                  color: AppTheme.darkGray,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                                    width: 20,
                                    height: 20,
                                    child: SpinKitThreeBounce(
                                      color: AppTheme.primaryBlue,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loading ZIP codes...',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.mediumGray),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 20),

              // Compliance notice for rebate eligibility
              RebateComplianceNotice(
                accentColor: AppTheme.primaryBlue,
                showViewStatesButton: false,
              ),
              const SizedBox(height: 20),

              _buildZipTabInfoNote(
                context,
                'To appear in multiple states, zip codes must be secured separately in each eligible state.',
              ),
              const SizedBox(height: 20),

              // Search / verify ZIP (filter list or verify 5-digit)
              Obx(() {
                if (controller.selectedState == null)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CustomTextField(
                    controller: controller.zipSearchController,
                    labelText: 'Search or enter 5-digit ZIP',
                    hintText: 'Enter a ZIP code to begin your search',
                    prefixIcon: Icons.search,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    onChanged: (v) {
                      controller.onZipSearchChanged(v);
                      final q = v.trim();
                      if (q.length == 5 && RegExp(r'^\d{5}$').hasMatch(q)) {
                        _scrollToAvailableZipSection(context);
                      }
                    },
                    onSubmitted: (v) {
                      final q = v.trim();
                      if (q.length == 5 && RegExp(r'^\d{5}$').hasMatch(q)) {
                        _scrollToAvailableZipSection(context);
                      }
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.useCurrentLocationForZip();
                        _scrollToAvailableZipSection(context);
                      },
                    ),
                  ),
                );
              }),

              // Tab bar: Claimed | Available
              Obx(() {
                if (controller.selectedState == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 0),
                  child: _buildZipSectionTabBar(context),
                );
              }),
            ]),
          ),
        ),

        // ZIP section content: Claimed or Available (tabbed)
        Obx(() {
          if (controller.selectedState == null) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildEmptyState(
                  context,
                  'Select a State',
                  'Please select a state above to view ZIP codes',
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
                        SpinKitFadingCircle(
                          color: AppTheme.primaryBlue,
                          size: 44,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading ZIP codes...',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(controller.zipSectionTabIndex),
                child: controller.zipSectionTabIndex == 0
                    ? _buildClaimedZipContent(context)
                    : _buildAvailableZipContent(context),
              ),
            ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildZipSectionTabBar(BuildContext context) {
    return Obx(() {
      final index = controller.zipSectionTabIndex;
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildZipTabChip(
                context,
                label: 'Claimed (${controller.claimedZipCodes.length}/6)',
                icon: Icons.check_circle_outline,
                isSelected: index == 0,
                onTap: () => controller.setZipSectionTab(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildZipTabChip(
                context,
                label: 'Available',
                icon: Icons.add_location_alt_outlined,
                isSelected: index == 1,
                onTap: () => controller.setZipSectionTab(1),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildZipTabChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.white : AppTheme.mediumGray,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.white : AppTheme.darkGray,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimedZipContent(BuildContext context) {
    return Obx(() {
      if (controller.claimedZipCodes.isEmpty) {
        return _buildEmptyState(
          context,
          'No claimed ZIP codes',
          'Start by claiming a ZIP code from the Available tab',
          icon: Icons.location_on_outlined,
          infoMessage:
              'Claim ZIP codes in your licensed states to appear in buyer and seller searches.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Your Claimed ZIP Codes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...controller.claimedZipCodes.map(
            (zip) => RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildZipCodeCard(context, zip, true),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAvailableZipContent(BuildContext context) {
    return Obx(() {
      if (controller.availableZipCodes.isEmpty) {
        return _buildEmptyState(
          context,
          'No available ZIP codes',
          'All ZIP codes in ${controller.selectedState} are claimed',
          icon: Icons.location_off_outlined,
        );
      }
      final height = MediaQuery.of(context).size.height - 320;
      return SizedBox(
        height: height.clamp(280.0, 600.0),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 0, bottom: 16),
          itemCount: controller.availableZipCodes.length,
          itemBuilder: (context, index) {
            final zip = controller.availableZipCodes[index];
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildZipCodeCard(context, zip, false),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildZipTabInfoNote(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
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
                    zip.city != null && zip.city!.isNotEmpty
                        ? '${zip.zipCode} (${zip.city})'
                        : zip.zipCode,
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
            // AGENT: Only check claimedByAgent. Ignore claimedByOfficer - that's for loan officers.
            else if (zip.isClaimedByOtherAgent)
              _buildWaitingListControls(context, zip)
            else
              _buildClaimControls(context, zip),
          ],
        ),
      ),
    );
  }

  void _showPromoCodeEntrySheet(BuildContext context) {
    final textController = TextEditingController(
      text: controller.promoCodeInput,
    );

    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Promo code',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onChanged: controller.setPromoCodeInput,
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Apply',
              width: double.infinity,
              onPressed: () async {
                final code = textController.text.trim();
                if (code.isEmpty) {
                  SnackbarHelper.showError('Please enter a promo code');
                  return;
                }
                await controller.applyPromoCode(code);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Promo codes are optional. Apply before claiming to lock in 70% off.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildClaimControls(BuildContext context, ZipCodeModel zip) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }

  Widget _buildWaitingListControls(BuildContext context, ZipCodeModel zip) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Obx(() {
          final hasEntries = controller.hasWaitingListEntries(zip.zipCode);
          final isJoined = controller.hasJoinedWaitingList(zip.zipCode);
          final isProcessing = controller.isWaitingListProcessing(zip.zipCode);
          final showSeeWaitingList = isJoined && hasEntries;

          if (showSeeWaitingList) {
            return CustomButton(
              text: 'See waiting list',
              onPressed: () => Get.to(
                () => WaitingListPage(zipCode: zip),
                transition: Transition.rightToLeft,
              ),
              isOutlined: true,
            );
          }

          return CustomButton(
            text: isProcessing ? 'Joining...' : 'Join waiting list',
            onPressed: isProcessing
                ? null
                : () async {
                    final added = await controller.joinWaitingList(zip);
                    if (added) {
                      SnackbarHelper.showSuccess(
                        'Added to waiting list',
                        title: 'Success',
                      );
                    }
                  },
            isOutlined: true,
            isLoading: isProcessing,
          );
        }),
        const SizedBox(height: 4),
        Text(
          'Claimed by another agent',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
        ),
      ],
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
                Column(
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
                                'My Listings',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${controller.currentListingCount} listings across all ZIP codes',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.mediumGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Select ZIP code when creating listing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Add New Listing',
                  onPressed: () => _handleAddListing(context),
                  icon: Icons.add_circle_outline,
                  width: double.infinity,
                  height: 48,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can create up to 3 free listings per ZIP code. Additional listings cost \$${controller.additionalListingPrice.toStringAsFixed(2)} per listing. Select your ZIP code when creating the listing.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            if (controller.myListings.isEmpty &&
                controller.allListings.isNotEmpty) {
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

  void _handleAddListing(BuildContext context) {
    if (controller.claimedZipCodes.isEmpty) {
      SnackbarHelper.showInfo(
        'Claim a ZIP code before adding a listing.',
        title: 'ZIP code required',
      );
      controller.setSelectedTab(1);
      return;
    }

    Get.toNamed('/add-listing');
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
                'Pending',
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
            // Expanded(
            //   child: _buildStatCard(
            //     context,
            //     'Needs Update',
            //     controller.staleListingsCount.toString(),
            //     Icons.warning_amber_outlined,
            //     Colors.deepOrange,
            //     '60+ days For Sale',
            //   ),
            // ),
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
                ] else
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                  ),
                // Status chip (read-only)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusChip(context, listing, showDropdown: false),
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
                        onPressed: () => Get.to(
                          () => EditAgentListingView(listing: listing),
                          fullscreenDialog: true,
                        ),
                        icon: Icons.edit_outlined,
                        isOutlined: true,
                        height: 44,
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

  Widget _buildStatusChip(BuildContext context, AgentListingModel listing, {bool showDropdown = true}) {
    Color color = AppTheme.mediumGray;
    IconData icon = Icons.help_outline;
    String label = 'Status';

    // Use marketStatus from API as the primary display (For Sale, Pending, Sold)
    if (listing.rejectionReason != null) {
      color = Colors.red;
      icon = Icons.cancel_outlined;
      label = 'Needs Attention';
    } else if (listing.marketStatus == MarketStatus.sold) {
      color = Colors.teal;
      icon = Icons.verified_outlined;
      label = 'Sold';
    } else if (listing.marketStatus == MarketStatus.pending) {
      color = Colors.orange;
      icon = Icons.rule_folder_outlined;
      label = 'Pending';
    } else if (!listing.isApproved) {
      color = Colors.orange;
      icon = Icons.pending_actions;
      label = 'Pending Approval';
    } else {
      color = AppTheme.lightGreen;
      icon = Icons.check_circle_outline;
      label = 'For Sale';
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
          if (showDropdown) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: color, size: 16),
          ],
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
            border: Border.all(color: AppTheme.lightGray.withOpacity(0.5)),
          ),
          child: TextField(
            onChanged: (value) => controller.setSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Search by title, address, city...',
              prefixIcon: Icon(Icons.search, color: AppTheme.mediumGray),
              suffixIcon: Obx(
                () => controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.mediumGray),
                        onPressed: () => controller.setSearchQuery(''),
                      )
                    : const SizedBox.shrink(),
              ),
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
          color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
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
          Icon(Icons.filter_alt_off, size: 48, color: AppTheme.mediumGray),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
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
            onPressed: () => _handleAddListing(context),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Process payment and navigation is handled internally
              controller.purchaseAdditionalListing();
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
    final descriptionController = TextEditingController(
      text: listing.description,
    );
    final priceController = TextEditingController(
      text: (listing.priceCents / 100).toStringAsFixed(0),
    );
    final addressController = TextEditingController(text: listing.address);
    final cityController = TextEditingController(text: listing.city);
    final stateController = TextEditingController(text: listing.state);
    final zipCodeController = TextEditingController(text: listing.zipCode);
    final bacPercentController = TextEditingController(
      text: listing.bacPercent.toString(),
    );

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
                          Obx(
                            () => _buildImageManagementSection(
                              context,
                              currentImages,
                              newImages,
                              imagePicker,
                            ),
                          ),
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
                          Obx(
                            () => _buildToggleSwitch(
                              context,
                              title: 'I am the Listing Agent',
                              subtitle:
                                  'You are the listing agent for this property',
                              value: isListingAgent.value,
                              onChanged: (value) =>
                                  isListingAgent.value = value,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Obx(
                            () => _buildToggleSwitch(
                              context,
                              title: 'Dual Agency Allowed',
                              subtitle:
                                  'Allow representing both buyer and seller',
                              value: dualAgencyAllowed.value,
                              onChanged: (value) =>
                                  dualAgencyAllowed.value = value,
                            ),
                          ),
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
                          side: BorderSide(
                            color: AppTheme.mediumGray,
                            width: 1.5,
                          ),
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
                      child: Obx(
                        () => Container(
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
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.4,
                                      ),
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
                                      SnackbarHelper.showError(
                                        'Please enter a property title',
                                      );
                                      return;
                                    }
                                    if (descriptionController.text
                                        .trim()
                                        .isEmpty) {
                                      SnackbarHelper.showError(
                                        'Please enter a description',
                                      );
                                      return;
                                    }
                                    if (priceController.text.trim().isEmpty) {
                                      SnackbarHelper.showError(
                                        'Please enter a price',
                                      );
                                      return;
                                    }
                                    if (addressController.text.trim().isEmpty) {
                                      SnackbarHelper.showError(
                                        'Please enter a street address',
                                      );
                                      return;
                                    }
                                    if (cityController.text.trim().isEmpty) {
                                      SnackbarHelper.showError(
                                        'Please enter a city',
                                      );
                                      return;
                                    }
                                    if (stateController.text.trim().isEmpty) {
                                      SnackbarHelper.showError(
                                        'Please enter a state',
                                      );
                                      return;
                                    }
                                    if (zipCodeController.text.trim().isEmpty) {
                                      SnackbarHelper.showError(
                                        'Please enter a ZIP code',
                                      );
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
                                        remainingImageUrls: currentImages
                                            .toList(),
                                        newImageFiles: newImages.toList(),
                                      );

                                      Get.back();

                                      // Wait for dialog to fully close before showing success
                                      await Future.delayed(
                                        const Duration(milliseconds: 300),
                                      );

                                      SnackbarHelper.showSuccess(
                                        'Listing updated successfully!',
                                      );
                                    } catch (e) {
                                      SnackbarHelper.showError(
                                        'Failed to update listing: ${e.toString()}',
                                      );
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20.sp,
                                      ),
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
                        ),
                      ),
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
                    gradient: LinearGradient(colors: AppTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: AppTheme.white, size: 20.sp),
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
          color: value
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : AppTheme.lightGray,
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
                  style: TextStyle(fontSize: 12.sp, color: AppTheme.mediumGray),
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
                  final processedUrl =
                      ImageUrlHelper.buildImageUrl(imageUrl) ?? imageUrl;

                  return Container(
                    width: 120.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.lightGray, width: 1.5),
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
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
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
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
            side: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
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
        content: Text(
          'Confirm you really want to delete "${listing.title}". '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.deleteListing(listing.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listing deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Builds message icon with badge showing unread count
  Widget _buildMessageIconWithBadge(Widget icon, int unreadCount) {
    if (unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6.w,
            top: -6.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5.w),
              ),
              constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return icon;
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
          //
          // const SizedBox(height: 20),
          //
          // // Testing: Update end date - visible at top of Billing
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.orange.shade50,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.orange.shade200, width: 1.5),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.stretch,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(Icons.bug_report, color: Colors.orange.shade700, size: 22),
          //           const SizedBox(width: 8),
          //           Text(
          //             'Testing',
          //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //               color: Colors.orange.shade900,
          //               fontWeight: FontWeight.w700,
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 8),
          //       Text(
          //         'Update subscription end date (test endpoint)',
          //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //           color: Colors.orange.shade800,
          //         ),
          //       ),
          //       const SizedBox(height: 14),
          //       Material(
          //         color: Colors.orange.shade600,
          //         borderRadius: BorderRadius.circular(10),
          //         child: InkWell(
          //           onTap: () => controller.testUpdateEndDate(context),
          //           borderRadius: BorderRadius.circular(10),
          //           child: Padding(
          //             padding: const EdgeInsets.symmetric(vertical: 14),
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: [
          //                 Icon(Icons.date_range, color: Colors.white, size: 22),
          //                 const SizedBox(width: 10),
          //                 Text(
          //                   'Test: Pick Date & Update End Date',
          //                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //                     color: Colors.white,
          //                     fontWeight: FontWeight.w600,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
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

          // Payment History
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'All your subscription and payment records',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 16),

          Obx(() {
            if (controller.subscriptions.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppTheme.mediumGray,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No payment history yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: controller.subscriptions.map((subscription) {
                return _buildPaymentHistoryCard(context, subscription);
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
    final dateStr =
        subscription['createdAt']?.toString() ??
        subscription['subscriptionStart']?.toString() ??
        '';
    final date = DateTime.tryParse(dateStr);
    final monthYear = date != null
        ? '${_getMonthName(date.month)} ${date.year}'
        : 'Unknown Date';
    final fullDate = date != null
        ? '${_getMonthName(date.month)} ${date.day}, ${date.year}'
        : 'Unknown Date';

    final amount = (subscription['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final amountStr = '\$${amount.toStringAsFixed(2)}';

    final status = subscription['subscriptionStatus']?.toString() ?? '';
    final displayStatus = _formatSubscriptionStatus(status);

    final stripeCustomerId = subscription['stripeCustomerId']?.toString();

    final startStr = subscription['subscriptionStart']?.toString();
    final endStr = subscription['subscriptionEnd']?.toString();
    final periodText = startStr != null && endStr != null
        ? '${_formatShortDate(startStr)} – ${_formatShortDate(endStr)}'
        : null;

    final tier = subscription['subscriptionTier']?.toString();
    final population = subscription['population'];
    final zipcode = subscription['zipcode']?.toString();

    final isActive = displayStatus == 'Active' || displayStatus == 'Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.subscriptions_rounded,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active subscription',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthYear,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      if (periodText != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              periodText,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.mediumGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tier != null && tier.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tier,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (zipcode != null && zipcode.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ZIP: $zipcode',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountStr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.lightGreen.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppTheme.lightGreen
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (population != null && (population as int) > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Population covered: ${_formatNumber(population)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (stripeCustomerId != null && stripeCustomerId.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _isSubscriptionExpired(status)
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.mediumGray.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_outlined, size: 18, color: AppTheme.darkGray),
                          const SizedBox(width: 8),
                          Text(
                            'Expired',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelConfirmationForSubscription(
                          context,
                          stripeCustomerId,
                          subscription,
                        ),
                        icon: Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade600),
                        label: Text(
                          'Cancel subscription',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
    String stripeCustomerId, [
    Map<String, dynamic>? subscription,
  ]) {
    final amount = (subscription?['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final amountStr = '\$${amount.toStringAsFixed(2)}/month';
    final startStr = subscription?['subscriptionStart']?.toString();
    final endStr = subscription?['subscriptionEnd']?.toString();
    String? periodText;
    if (startStr != null && endStr != null) {
      final s = DateTime.tryParse(startStr);
      final e = DateTime.tryParse(endStr);
      if (s != null && e != null) {
        periodText = '${_getMonthName(s.month)} ${s.day}, ${s.year} – ${_getMonthName(e.month)} ${e.day}, ${e.year}';
      }
    }
    final tier = subscription?['subscriptionTier']?.toString();
    final zipcodeForDialog = subscription?['zipcode']?.toString();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.cancel_outlined, color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to cancel your subscription. Please review the details below before confirming.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription details',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCancelDialogDetailRow(context, 'Monthly amount', amountStr),
                    if (periodText != null)
                      _buildCancelDialogDetailRow(context, 'Current period', periodText),
                    if (tier != null && tier.isNotEmpty)
                      _buildCancelDialogDetailRow(context, 'Tier', tier),
                    if (zipcodeForDialog != null && zipcodeForDialog.isNotEmpty)
                      _buildCancelDialogDetailRow(
                        context,
                        'ZIP code',
                        zipcodeForDialog,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What happens when you cancel?',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• Your subscription will remain active for up to 30 days from today.\n'
                            '• You will retain full access until the end of your current billing period.\n'
                            '• Your claimed ZIP codes will remain yours until the period ends.\n'
                            '• No further charges will be applied after cancellation.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade800,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to proceed?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep subscription',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.cancelSubscription(stripeCustomerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, cancel subscription'),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelDialogDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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

  Widget _buildPaymentHistoryCard(
    BuildContext context,
    Map<String, dynamic> subscription,
  ) {
    final dateStr =
        subscription['createdAt']?.toString() ??
        subscription['subscriptionStart']?.toString() ??
        '';
    final date = DateTime.tryParse(dateStr);
    final monthYear = date != null
        ? '${_getMonthName(date.month)} ${date.year}'
        : 'Unknown Date';
    final fullDate = date != null
        ? '${_getMonthName(date.month)} ${date.day}, ${date.year}'
        : 'Unknown Date';

    final amount = (subscription['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final amountStr = '\$${amount.toStringAsFixed(2)}';

    final status = subscription['subscriptionStatus']?.toString() ?? '';
    final displayStatus = _formatSubscriptionStatus(status);

    final startStr = subscription['subscriptionStart']?.toString();
    final endStr = subscription['subscriptionEnd']?.toString();
    final periodText = startStr != null && endStr != null
        ? '${_formatShortDate(startStr)} – ${_formatShortDate(endStr)}'
        : null;

    final tier = subscription['subscriptionTier']?.toString();
    final population = subscription['population'];
    final zipcode = subscription['zipcode']?.toString();

    final isActive = displayStatus == 'Active' || displayStatus == 'Paid';
    final isCancelled = displayStatus == 'Canceled' || displayStatus == 'Cancelled';
    final isExpired = displayStatus == 'Expired';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCancelled ? Icons.cancel_outlined : Icons.payment_rounded,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthYear,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      if (periodText != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              periodText,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.mediumGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tier != null && tier.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tier,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (zipcode != null && zipcode.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ZIP: $zipcode',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountStr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.lightGreen.withOpacity(0.2)
                            : isCancelled
                                ? Colors.red.withOpacity(0.1)
                                : isExpired
                                    ? AppTheme.mediumGray.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppTheme.lightGreen
                              : isCancelled
                                  ? Colors.red.shade700
                                  : isExpired
                                      ? AppTheme.darkGray
                                      : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (population != null && (population as int) > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Population covered: ${_formatNumber(population)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
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

  String _formatShortDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${_getMonthName(d.month).substring(0, 3)} ${d.day}, ${d.year}';
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
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

  bool _isSubscriptionExpired(String status) {
    return (status.toLowerCase()) == 'expired';
  }

  /// Helper method to format subscription status for display
  String _formatSubscriptionStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'active' || lowerStatus == 'paid') {
      return 'Paid';
    } else if (lowerStatus == 'canceled' || lowerStatus == 'cancelled') {
      return 'Canceled';
    } else if (lowerStatus == 'expired') {
      return 'Expired';
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
      final conversionsChange = controller.calculateMonthOverMonthChange(
        'conversions',
      );
      final closeRateChange = controller.calculateMonthOverMonthChange(
        'closeRate',
      );

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
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
                    // const SizedBox(height: 12),
                    // _buildStatsActivityItem(
                    //   'Showings',
                    //   activityData['Showings'] ?? 0,
                    //   Colors.orange,
                    // ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                    style: TextStyle(fontSize: 10, color: AppTheme.mediumGray),
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
              final height = ((value / maxValue) * 150).clamp(
                4.0,
                150.0,
              ); // Clamp to prevent NaN and ensure minimum height

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.mediumGray),
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
                    infoMessage:
                        'Leads will appear here when buyers contact you',
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
    final isPending = !lead.isAccepted && !lead.isCompleted && !lead.isReported;
    final accent = isBuying ? AppTheme.primaryBlue : AppTheme.lightGreen;
    final statusLabel = lead.leadStatus?.isNotEmpty == true
        ? lead.leadStatus!.toUpperCase()
        : (isPending ? 'PENDING' : 'UPDATED');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBuying ? 'Buying Lead' : 'Selling Lead',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withOpacity(0.12)
                      : lead.isCompleted
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.lightGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPending
                        ? Colors.orange.shade700
                        : lead.isCompleted
                            ? AppTheme.primaryBlue
                            : AppTheme.lightGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                lead.formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withOpacity(0.12),
                backgroundImage:
                    ImageUrlHelper.buildImageUrl(buyerInfo?.profilePic) != null
                    ? NetworkImage(ImageUrlHelper.buildImageUrl(buyerInfo?.profilePic)!)
                    : null,
                child: (buyerInfo?.profilePic == null || buyerInfo!.profilePic!.isEmpty)
                    ? Text(
                        (buyerInfo?.fullname ?? 'B').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerInfo?.fullname ?? 'Unknown Buyer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (buyerInfo?.email != null && buyerInfo!.email!.isNotEmpty)
                      Text(
                        buyerInfo.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (lead.priceRange != null && lead.priceRange!.isNotEmpty)
                _leadMetaChip(context, Icons.attach_money, lead.priceRange!),
              if (lead.propertyType != null && lead.propertyType!.isNotEmpty)
                _leadMetaChip(context, Icons.home_work_outlined, lead.propertyType!),
              if (lead.bestTime != null && lead.bestTime!.isNotEmpty)
                _leadMetaChip(context, Icons.schedule, lead.bestTime!),
            ],
          ),
          if (lead.comments != null && lead.comments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                lead.comments!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.acceptLead(lead),
                    icon: Icon(Icons.check_circle_outline, color: accent, size: 18),
                    label: Text(
                      'Accept Lead',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withOpacity(0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.contactBuyerFromLead(lead),
                  icon: Icon(
                    lead.isAccepted ? Icons.chat_bubble_outline : Icons.call_outlined,
                    size: 18,
                  ),
                  label: Text(lead.isAccepted ? 'Open Chat' : 'Contact Buyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (lead.isAccepted && !lead.isCompleted) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.markLeadComplete(lead),
                    icon: const Icon(Icons.task_alt, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightGreen,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _leadMetaChip(BuildContext context, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.mediumGray),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.darkGray),
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
          child: Icon(icon, size: 16, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
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
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1.5),
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
            child: Icon(icon, size: 22, color: accentColor),
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
            child: Icon(icon, size: 16, color: AppTheme.primaryBlue),
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
              final processedUrl =
                  ImageUrlHelper.buildImageUrl(originalUrl) ?? originalUrl;

              // Print current image URL when displayed
              if (kDebugMode) {
                print(
                  '🌐 Image [$index/$totalImages] in Image.network: $processedUrl',
                );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
