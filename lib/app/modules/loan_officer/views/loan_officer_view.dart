import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer/controllers/loan_officer_controller.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/modules/loan_officer_edit_profile/views/loan_officer_edit_profile_view.dart';
import 'package:getrebate/app/modules/loan_officer_edit_profile/bindings/loan_officer_edit_profile_binding.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/models/loan_officer_zip_code_model.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/modules/checklist/controllers/checklist_controller.dart';
import 'package:getrebate/app/modules/rebate_checklist/bindings/rebate_checklist_binding.dart';
import 'package:getrebate/app/modules/rebate_checklist/controllers/rebate_checklist_controller.dart';
import 'package:getrebate/app/modules/rebate_checklist/views/rebate_checklist_view.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/modules/messages/views/messages_view.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/modules/loan_officer/views/waiting_list_page.dart';



class LoanOfficerView extends GetView<LoanOfficerController> {
  const LoanOfficerView({super.key});

  @override
  Widget build(BuildContext context) {
    // This controller holds the real loan officer profile from the backend
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : Get.put(CurrentLoanOfficerController(), permanent: true);

    debugPrint(
      '📊 LoanOfficerView.build: '
      'loanOfficer=${currentLoanOfficerController.currentLoanOfficer.value?.id}, '
      'isLoading=${currentLoanOfficerController.isLoading.value}',
    );

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
        title: Obx(() {
          final officer = currentLoanOfficerController.currentLoanOfficer.value;
          final loading = currentLoanOfficerController.isLoading.value;

          if (officer == null && loading) {
            debugPrint(
              '📊 LoanOfficerView: Waiting for current loan officer data...',
            );
          } else if (officer == null && !loading) {
            debugPrint(
              '⚠️ LoanOfficerView: currentLoanOfficer is null and not loading. Check fetchCurrentLoanOfficer call.',
            );
          } else if (officer != null) {
            debugPrint(
              '✅ LoanOfficerView: Showing data for loanOfficer=${officer.id}, name=${officer.name}',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Loan Officer Dashboard',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                officer != null
                    ? 'Welcome, ${officer.name}'
                    : loading
                    ? 'Loading your profile...'
                    : 'Profile not loaded',
                style: TextStyle(
                  color: AppTheme.white.withOpacity(0.9),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        }),
        centerTitle: true,
        actions: [
          Obx(() =>
            controller.showZipSelectionFirst
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
              children: [
                Expanded(child: _buildZipManagement(context)),
              ],
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
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildTab(context, 'Dashboard', 0, Icons.dashboard),
            ),
            Expanded(child: _buildTab(context, 'Messages', 1, Icons.message)),
            Expanded(
              child: _buildTab(context, 'ZIP Codes', 2, Icons.location_on),
            ),
            Expanded(child: _buildTab(context, 'Billing', 3, Icons.payment)),
            // COMMENTED OUT: Checklists tab
            // Expanded(child: _buildTab(context, 'Checklists', 4, Icons.checklist_rtl)),
            // COMMENTED OUT: Stats tab
            // Expanded(child: _buildTab(context, 'Stats', 5, Icons.analytics)),
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
              ? AppTheme.lightGreen.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.lightGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.lightGreen : AppTheme.mediumGray,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppTheme.lightGreen : AppTheme.mediumGray,
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
          return _buildMessages(context);
        case 2:
          return _buildZipManagement(context);
        case 3:
          return _buildBilling(context);
        // COMMENTED OUT: Checklists tab content
        // case 4:
        //   return _buildChecklists(context);
        // COMMENTED OUT: Stats tab content
        // case 5:
        //   return _buildStats(context);
        default:
          return _buildDashboard(context);
      }
    });
  }

  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsCards(context),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // Loan Officer Checklist Section
          _buildLoanOfficerChecklistSection(context),

          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    return const MessagesView();
  }

  Widget _buildStatsCards(BuildContext context) {
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : Get.put(CurrentLoanOfficerController(), permanent: true);

    return Obx(() {
      final officer = currentLoanOfficerController.currentLoanOfficer.value;
      final loading = currentLoanOfficerController.isLoading.value;

      if (officer == null) {
        if (loading) {
          debugPrint(
            '📊 _buildStatsCards: Waiting for current loan officer stats (still loading)...',
          );
        } else {
          debugPrint(
            '⚠️ _buildStatsCards: currentLoanOfficer is null, falling back to mock stats from LoanOfficerController.',
          );
        }

        // Fallback to existing mock stats if we don't have real data yet
        final stats = controller.getStatsData();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final stat = stats[index];

            return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stat['icon'],
                          color: AppTheme.lightGreen,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            stat['value'].toString(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            stat['label'],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.mediumGray,
                                  fontSize: 12,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .slideY(
                  begin: 0.3,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                  delay: (index * 100).ms,
                )
                .fadeIn(duration: 600.ms, delay: (index * 100).ms);
          },
        );
      }

      debugPrint(
        '✅ _buildStatsCards: Using real stats from LoanOfficerModel (id=${officer.id}).',
      );

      final realStats = [
        {
          'label': 'Searches Appeared In',
          'value': officer.searchesAppearedIn,
          'icon': Icons.search,
        },
        {
          'label': 'Profile Views',
          'value': officer.profileViews,
          'icon': Icons.visibility,
        },
        {'label': 'Contacts', 'value': officer.contacts, 'icon': Icons.phone},
        {
          'label': 'Rating (${officer.reviewCount} reviews)',
          'value': officer.rating.toStringAsFixed(1),
          'icon': Icons.star,
        },
      ];

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: realStats.length,
        itemBuilder: (context, index) {
          final stat = realStats[index];

          return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        color: AppTheme.lightGreen,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          stat['value'].toString(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.black,
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          stat['label'].toString(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.mediumGray,
                                fontSize: 12,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
                delay: (index * 100).ms,
              )
              .fadeIn(duration: 600.ms, delay: (index * 100).ms);
        },
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            Column(
              children: [
                CustomButton(
                  text: 'ZIP Codes',
                  onPressed: () => controller.setSelectedTab(2),
                  icon: Icons.location_on,
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Edit Profile',
                  onPressed: () {
                    Get.to(
                      () => const LoanOfficerEditProfileView(),
                      binding: LoanOfficerEditProfileBinding(),
                    );
                  },
                  icon: Icons.edit,
                  isOutlined: true,
                  width: double.infinity,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // COMMENTED OUT: Compliance Tutorial button row
            // const SizedBox(height: 12),
            // Row(
            //   children: [
            //     Expanded(
            //       child: CustomButton(
            //         text: 'Compliance Tutorial',
            //         onPressed: () {
            //           Get.snackbar('Info', 'Compliance tutorial coming soon!');
            //         },
            //         icon: Icons.school,
            //         isOutlined: true,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: CustomButton(
            //         text: 'Edit Profile',
            //         onPressed: () {
            //           Get.to(
            //             () => const LoanOfficerEditProfileView(),
            //             binding: LoanOfficerEditProfileBinding(),
            //           );
            //         },
            //         icon: Icons.edit,
            //         isOutlined: true,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanOfficerChecklistSection(BuildContext context) {
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
                    color: AppTheme.lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.checklist_rtl,
                    color: AppTheme.lightGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loan Officer Checklist',
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
              'Follow these step-by-step guidelines to maximize your success on the platform and work effectively with buyers and agents.',
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
                      'This platform provides opportunities. Most loan processing work happens outside the app through your mortgage application link.',
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
              text: 'View Complete Checklist',
              onPressed: () {
                Get.toNamed(AppPages.LOAN_OFFICER_CHECKLIST);
              },
              icon: Icons.assignment_outlined,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : Get.put(CurrentLoanOfficerController(), permanent: true);

    return Obx(() {
      final officer = currentLoanOfficerController.currentLoanOfficer.value;
      final loading = currentLoanOfficerController.isLoading.value;

      if (officer == null && loading) {
        debugPrint(
          '📊 _buildRecentActivity: Waiting for current loan officer activity data...',
        );
      } else if (officer == null && !loading) {
        debugPrint(
          '⚠️ _buildRecentActivity: currentLoanOfficer is null, showing placeholder activity.',
        );
      } else if (officer != null) {
        debugPrint(
          '✅ _buildRecentActivity: Showing recent activity for loanOfficer=${officer.id}',
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              if (officer == null && loading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ] else if (officer == null) ...[
                _buildActivityItem(
                  context,
                  'Activity data not loaded',
                  'Please check your connection or try again later.',
                  Icons.info_outline,
                ),
              ] else ...[
                _buildActivityItem(
                  context,
                  'Appeared in ${officer.searchesAppearedIn} searches',
                  'Includes all time searches on the platform.',
                  Icons.search,
                ),
                _buildActivityItem(
                  context,
                  'Profile viewed ${officer.profileViews} times',
                  'Buyers and agents who viewed your profile.',
                  Icons.visibility,
                ),
                _buildActivityItem(
                  context,
                  '${officer.contacts} contact requests received',
                  'Total contacts generated from your profile.',
                  Icons.phone,
                ),
              ],
            ],
          ),
        ),
      );
    });
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
              color: AppTheme.lightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.lightGreen, size: 20),
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

  // My Loans section commented out - loan officers don't need this, it's just a lead generation tool
  /*
  Widget _buildMyLoans(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'My Loans',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Loans List
              Obx(
                () => controller.loans.isEmpty
                    ? _buildEmptyLoans(context)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.loans.length,
                        itemBuilder: (context, index) {
                          final loan = controller.loans[index];
                          return _buildLoanCard(context, loan);
                        },
                      ),
              ),
            ],
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              Get.toNamed('/add-loan');
            },
            backgroundColor: AppTheme.lightGreen,
            child: const Icon(Icons.add, color: Colors.white),
            heroTag: 'add-loan-fab',
          ),
        ),
      ],
    );
  }

  Widget _buildLoanCard(BuildContext context, dynamic loan) {
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
                        loan.borrowerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.borrowerEmail ?? 'No email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Get.toNamed('/edit-loan', arguments: {'loan': loan});
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(context, loan);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLoanDetail(
                    context,
                    'Loan Amount',
                    '\$${(loan.loanAmount / 1000).toStringAsFixed(0)}K',
                  ),
                ),
                Expanded(
                  child: _buildLoanDetail(
                    context,
                    'Interest Rate',
                    '${loan.interestRate.toStringAsFixed(2)}%',
                  ),
                ),
                Expanded(
                  child: _buildLoanDetail(
                    context,
                    'Type',
                    loan.loanType.toUpperCase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(loan.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loan.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(loan.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${loan.termInMonths ~/ 12} years',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetail(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.lightGreen;
      case 'pending':
        return Colors.orange;
      case 'funded':
        return Colors.blue;
      case 'closed':
        return AppTheme.mediumGray;
      default:
        return AppTheme.primaryBlue;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, dynamic loan) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Loan'),
        content: Text(
          'Are you sure you want to delete the loan for ${loan.borrowerName}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteLoan(loan.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLoans(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No Loans Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first loan',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/add-loan');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add First Loan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

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
              constraints: BoxConstraints(
                minWidth: 16.w,
                minHeight: 16.h,
              ),
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

  Widget _buildZipManagement(BuildContext context) {
    final authController = Get.find<global.AuthController>();
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : Get.put(CurrentLoanOfficerController(), permanent: true);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Licensed States Section
              Obx(() {
                final loanOfficer =
                    currentLoanOfficerController.currentLoanOfficer.value;
                final licensedStates = loanOfficer?.licensedStates ?? [];
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

              // State Selector for ZIP Codes - Always show, but only show licensed states in dropdown
              Obx(() {
                final uniqueStates = controller.licensedStateCodes;

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
                              'No licensed states found. Please update your profile to add licensed states.',
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
                              decoration: InputDecoration(
                                labelText: 'Select State',
                                prefixIcon: Icon(
                                  Icons.map,
                                  color: AppTheme.primaryBlue,
                                ),
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
                                    style: TextStyle(
                                      color: AppTheme.mediumGray,
                                    ),
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
              }),
              const SizedBox(height: 20),

              _buildZipTabInfoNote(
                context,
                'To appear in multiple states, zip codes must be secured separately in each eligible state.',
              ),
              const SizedBox(height: 20),



              // Search / verify ZIP (filter list or verify 5-digit)
              Obx(() {
                if (controller.selectedState == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: CustomTextField(
                    controller: controller.zipSearchController,
                    labelText: 'Search or enter 5-digit ZIP',
                    hintText: 'Filter by prefix, or type 5 digits to validate & fetch',
                    prefixIcon: Icons.search,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    onChanged: (v) => controller.onZipSearchChanged(v),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.my_location, color: AppTheme.primaryBlue, size: 20),
                      onPressed: controller.useCurrentLocationForZip,
                    ),
                  ),
                );
              }),

              // Claimed ZIP Codes
              Obx(() {
                if (controller.claimedZipCodes.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'No claimed ZIP codes',
                    'Start by claiming a ZIP code below',
                    icon: Icons.location_on_outlined,
                    infoMessage:
                        'Claim ZIP codes in your licensed states to appear in buyer searches',
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
                    ...controller.claimedZipCodes.map(
                      (zip) => RepaintBoundary(
                        child: _buildZipCodeCard(context, zip, true),
                      ),
                    ),
                  ],
                );
              }),

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
        Obx(() {
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
        }),
      ],
    );
  }

  // Removed _buildZipCodeList - now using SliverList directly for better performance

  Widget _buildZipTabInfoNote(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.25),
          ),
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

  Widget _buildWaitingListControls(BuildContext context, LoanOfficerZipCodeModel zip) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 12),
        Obx(() {
          final showSeeWaitingList = controller.isCurrentUserInWaitingList(zip);
          final isProcessing = controller.isWaitingListProcessing(zip.postalCode);

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
          'Claimed by another loan officer',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
        ),
      ],
    );
  }

  Widget _buildZipCodeCard(

    BuildContext context,
    LoanOfficerZipCodeModel zip,
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
                    zip.postalCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${zip.city != null && zip.city!.isNotEmpty ? '${zip.city}, ' : ''}${zip.state} • Population: $formattedPopulation',
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
                  onPressed: controller.isZipCodeLoading(zip.postalCode)
                      ? null
                      : () => controller.releaseZipCode(zip),
                  isOutlined: true,
                  // Let button size itself; show loader per ZIP
                  isLoading: controller.isZipCodeLoading(zip.postalCode),
                ),
              )
            else if (zip.claimedByOfficer)
              _buildWaitingListControls(context, zip)
            else
              Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Claim',
                      onPressed: controller.isZipCodeLoading(zip.postalCode)
                          ? null
                          : () => controller.claimZipCode(zip),
                      isLoading: controller.isZipCodeLoading(zip.postalCode),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ),
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
          _buildSubscriptionSummaryCard(context),

          const SizedBox(height: 20),

          // Claimed ZIP Codes (manage from billing)
          Obx(() {
            if (controller.claimedZipCodes.isEmpty) {
              return _buildEmptyState(
                context,
                'No claimed ZIP codes',
                'Claim ZIP codes to appear in searches',
                icon: Icons.location_on_outlined,
                infoMessage:
                    'You can claim ZIP codes from the ZIP Management tab.',
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
                ...controller.claimedZipCodes.map(
                  (zip) => RepaintBoundary(
                    child: _buildZipCodeCard(context, zip, true),
                  ),
                ),
              ],
            );
          }),

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
          _buildPaymentHistorySection(context),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSummaryCard(BuildContext context) {
    return Obx(() {
      try {
        final hasActivePromo = controller.hasActivePromo;
        final subscription = controller.subscription;
        final standardPrice = controller.getStandardMonthlyPrice();
        final monthlyCost = controller.calculateMonthlyCost();
        final claimedCount = controller.claimedZipCodes.length;
        final promoExpiresAt = subscription?.promoExpiresAt;

        return Card(
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppTheme.darkGray),
                    ),
                    Text(
                      '\$${standardPrice.toStringAsFixed(2)}/month',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w500,
                        decoration: hasActivePromo
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppTheme.darkGray),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${monthlyCost.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: hasActivePromo
                                    ? Colors.green
                                    : AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (hasActivePromo)
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
                if (hasActivePromo && promoExpiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Promo expires: ${promoExpiresAt.toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppTheme.darkGray),
                    ),
                    Text(
                      '$claimedCount/6',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('❌ Error building subscription summary card: $e');
          print('   Stack trace: $stackTrace');
        }
        // Return error card
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading subscription data',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try refreshing the page',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildPlanStatusBadge(BuildContext context) {
    return Obx(() {
      if (controller.isCancelled) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cancellation Scheduled',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      } else if (controller.isInFreePeriod) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Free Trial Active',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.lightGreen, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppTheme.lightGreen, size: 16),
              const SizedBox(width: 6),
              Text(
                'Active',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildPlanDetails(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // ZIP Codes Claimed
          _buildDetailRow(
            context,
            Icons.location_on,
            'ZIP Codes Claimed',
            '${controller.claimedZipCodes.length}/6',
          ),
          const SizedBox(height: 12),

          // Base Price
          _buildDetailRow(
            context,
            Icons.attach_money,
            'Base Monthly Price',
            '\$${controller.getStandardMonthlyPrice().toStringAsFixed(2)}/month',
            showStrikethrough: controller.isInFreePeriod,
          ),
        ],
      );
    });
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool showStrikethrough = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkGray,
            fontWeight: FontWeight.w600,
            decoration: showStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: AppTheme.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildRenewalDate(BuildContext context) {
    return Obx(() {
      final subscription = controller.subscription;
      if (subscription == null) return const SizedBox.shrink();

      // Calculate next billing date
      DateTime nextBillingDate;
      if (controller.isInFreePeriod && subscription.freePeriodEndsAt != null) {
        nextBillingDate = subscription.freePeriodEndsAt!;
      } else {
        // Next billing is typically 30 days from start date or last billing
        final lastBilling = subscription.updatedAt;
        nextBillingDate = lastBilling.add(const Duration(days: 30));
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isInFreePeriod
                        ? 'Free Period Ends'
                        : 'Next Billing Date',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(nextBillingDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPaymentMethodCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppTheme.lightGreen, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Payment method info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.mediumGray.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: AppTheme.mediumGray, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No payment method on file',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add a payment method to continue your subscription',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.snackbar(
                        'Info',
                        'Payment method management coming soon',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: Text(
                      'Add',
                      style: TextStyle(color: AppTheme.primaryBlue),
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

  Widget _buildPaymentHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Obx(() {
          if (controller.subscriptions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No payment history available',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
              ),
            );
          }

          return Column(
            children: controller.subscriptions.map((subscription) {
              final dateStr =
                  subscription['createdAt']?.toString() ??
                  subscription['subscriptionStart']?.toString() ??
                  '';
              final date = DateTime.tryParse(dateStr);
              final monthYear = date != null
                  ? '${_getMonthName(date.month)} ${date.year}'
                  : 'Unknown Date';

              final amount = subscription['amountPaid'] as double? ?? 0.0;
              final amountStr = '\$${amount.toStringAsFixed(2)}';

              final status =
                  subscription['subscriptionStatus']?.toString() ?? '';
              final displayStatus = _formatSubscriptionStatus(status);

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

    final amount = subscription['amountPaid'] as double? ?? 0.0;
    final amountStr = '\$${amount.toStringAsFixed(2)}';

    final status = subscription['subscriptionStatus']?.toString() ?? '';
    final displayStatus = _formatSubscriptionStatus(status);

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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                        color:
                            displayStatus == 'Paid' || displayStatus == 'Active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              displayStatus == 'Paid' ||
                                  displayStatus == 'Active'
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

  String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showCancelConfirmation(BuildContext context) {
    final activeSub = controller.activeSubscriptionFromAPI;
    final stripeCustomerId = activeSub?['stripeCustomerId']?.toString();

    if (stripeCustomerId != null && stripeCustomerId.isNotEmpty) {
      _showCancelConfirmationForSubscription(context, stripeCustomerId);
      return;
    }

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
    if (month < 1 || month > 12) return 'Unknown';
    return months[month - 1];
  }

  String _formatSubscriptionStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.isEmpty) return 'Unknown';

    if (lowerStatus == 'active' ||
        lowerStatus == 'paid' ||
        lowerStatus == 'trialing') {
      return 'Active';
    } else if (lowerStatus == 'past_due' || lowerStatus == 'unpaid') {
      return 'Past Due';
    } else if (lowerStatus == 'canceled' || lowerStatus == 'cancelled') {
      return 'Cancelled';
    }
    return status;
  }

  Widget _buildPaymentItem(
    BuildContext context,
    String month,
    String amount,
    String status,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
                ),
              ],
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
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final currentLoanOfficerController =
        Get.isRegistered<CurrentLoanOfficerController>()
        ? Get.find<CurrentLoanOfficerController>()
        : Get.put(CurrentLoanOfficerController(), permanent: true);

    return Obx(() {
      final officer = currentLoanOfficerController.currentLoanOfficer.value;
      final loading = currentLoanOfficerController.isLoading.value;

      if (officer == null && loading) {
        debugPrint(
          '📊 _buildStats: Waiting for current loan officer analytics data...',
        );
      } else if (officer == null && !loading) {
        debugPrint(
          '⚠️ _buildStats: currentLoanOfficer is null, showing placeholder analytics.',
        );
      } else if (officer != null) {
        debugPrint(
          '✅ _buildStats: Showing analytics for loanOfficer=${officer.id}',
        );
      }

      // Simple derived metrics from LoanOfficerModel
      final totalContacts = officer?.contacts ?? 0;
      final totalSearches = officer?.searchesAppearedIn ?? 0;
      final totalViews = officer?.profileViews ?? 0;
      final avgRating = officer?.rating ?? 0.0;
      final reviewCount = officer?.reviewCount ?? 0;

      // Build some lightweight trend data from the aggregate stats
      // (until the backend provides time-series analytics)
      final monthlyApplications = [
        (totalContacts * 0.4).round(),
        (totalContacts * 0.6).round(),
        (totalContacts * 0.5).round(),
        (totalContacts * 0.7).round(),
        (totalContacts * 0.8).round(),
        (totalContacts * 0.9).round(),
        totalContacts,
      ];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

      final loanVolume = [
        (totalViews * 0.2 / 1000).toDouble(),
        (totalViews * 0.4 / 1000).toDouble(),
        (totalViews * 0.35 / 1000).toDouble(),
        (totalViews * 0.5 / 1000).toDouble(),
        (totalViews * 0.6 / 1000).toDouble(),
        (totalViews * 0.7 / 1000).toDouble(),
        (totalViews * 0.8 / 1000).toDouble(),
      ]; // pseudo volume in "millions"

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Summary Stats (now based on real data where available)
            Row(
              children: [
                Expanded(
                  child: _buildLoanStatsCard(
                    context,
                    'Total Contacts',
                    totalContacts.toString(),
                    Icons.description,
                    AppTheme.lightGreen,
                    officer != null
                        ? 'Total contact requests generated from your profile.'
                        : 'Contacts from your profile (data not loaded).',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLoanStatsCard(
                    context,
                    'Avg. Rating',
                    reviewCount > 0
                        ? '${avgRating.toStringAsFixed(1)} ★'
                        : 'No reviews',
                    Icons.check_circle,
                    Colors.teal,
                    reviewCount > 0
                        ? '$reviewCount ${reviewCount == 1 ? "review" : "reviews"} from buyers.'
                        : 'You do not have any reviews yet.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLoanStatsCard(
                    context,
                    'Search Impressions',
                    totalSearches.toString(),
                    Icons.search,
                    AppTheme.lightGreen,
                    'Times you appeared in buyer/agent searches.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLoanStatsCard(
                    context,
                    'Profile Views',
                    totalViews.toString(),
                    Icons.visibility,
                    Colors.blue,
                    'Total profile views from buyers and agents.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly Applications Chart (derived from contacts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Monthly Contacts (derived)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Last 7 months (approximate)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.mediumGray),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLoanBarChart(monthlyApplications, months),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loan Volume Chart (pseudo volume based on profile views)
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
                          'Engagement Volume (relative)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Trend only',
                            style: TextStyle(
                              color: AppTheme.lightGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLoanLineChart(loanVolume),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Application Breakdown (derived from contacts/views)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engagement Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLoanActivityItem(
                      'Searches',
                      totalSearches,
                      AppTheme.lightGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildLoanActivityItem(
                      'Profile Views',
                      totalViews,
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    _buildLoanActivityItem(
                      'Contacts',
                      totalContacts,
                      Colors.blue,
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

  Widget _buildLoanStatsCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanBarChart(List<int> data, List<String> labels) {
    if (data.isEmpty || labels.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    // Prevent division by zero and NaN heights
    final safeMax = maxValue > 0 ? maxValue : 1;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(data.length, (index) {
              final value = data[index];
              final height = (value / safeMax) * 150;

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
                            AppTheme.lightGreen,
                            AppTheme.lightGreen.withOpacity(0.7),
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

  Widget _buildLoanLineChart(List<double> data) {
    return Container(
      height: 150,
      child: Stack(
        children: [
          // Dotted grid lines
          Column(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.lightGray,
                        width: 0.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Data line
          CustomPaint(
            size: Size.infinite,
            painter: LoanLineChartPainter(data: data),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanActivityItem(String label, int value, Color color) {
    final maxValue = 200;
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
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        infoMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          height: 1.4,
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

  Widget _buildChecklists(BuildContext context) {
    final checklistController = Get.put(ChecklistController());
    final rebateChecklistController = Get.put(RebateChecklistController());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklists',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View the checklists that buyers and agents see, so you know what they\'re working with.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
          ),
          const SizedBox(height: 24),

          // Buyer/Building - Agent Version
          _buildChecklistCard(
            context,
            'Real Estate Agent Rebate Checklist – Buying/Building',
            rebateChecklistController.getRebateChecklistForBuying(),
            Icons.shopping_bag,
            AppTheme.primaryBlue,
            isAgentVersion: true,
          ),

          const SizedBox(height: 24),

          // Buyer Checklist (for consumers)
          _buildChecklistCard(
            context,
            'Homebuyer Checklist (with Rebate!)',
            checklistController.getBuyerChecklist(),
            Icons.checklist_rtl,
            AppTheme.lightGreen,
            isConsumerVersion: true,
            actionLabel: 'View Buyer Version',
            onAction: () => Get.toNamed(
              AppPages.CHECKLIST,
              arguments: {
                'type': 'buyer',
                'title': 'Homebuyer Checklist (with Rebate!)',
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color, {
    bool isAgentVersion = false,
    bool isConsumerVersion = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAgentVersion) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Agent Version',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (isConsumerVersion) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Consumer Version',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isAgentVersion) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Follow these steps to ensure compliance when working with a buyer who will receive a real estate commission rebate.\n\n(Continue providing your standard services—such as MLS searches, showings, negotiations, and client support—as usual.)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...List.generate(items.length, (index) {
            final stepNumber = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[index],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.open_in_new, color: color),
                label: Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Custom painter for loan officer line chart
class LoanLineChartPainter extends CustomPainter {
  final List<double> data;

  LoanLineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    // Prevent division by zero and NaN positions
    final safeMax = maxValue > 0 ? maxValue : 1.0;
    final paint = Paint()
      ..color = AppTheme.lightGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pointPaint = Paint()
      ..color = AppTheme.lightGreen
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : (size.width / (data.length - 1)) * i;
      final y = size.height - (data[i] / safeMax) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw points
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
