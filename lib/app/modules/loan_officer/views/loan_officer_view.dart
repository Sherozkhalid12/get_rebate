import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer/controllers/loan_officer_controller.dart';
import 'package:getrebate/app/modules/loan_officer_profile/views/loan_officer_profile_edit_view.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/modules/checklist/controllers/checklist_controller.dart';
import 'package:getrebate/app/modules/rebate_checklist/controllers/rebate_checklist_controller.dart';
import 'package:getrebate/app/routes/app_pages.dart';

class LoanOfficerView extends GetView<LoanOfficerController> {
  const LoanOfficerView({super.key});

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
          'Loan Officer Dashboard',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
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
            // My Loans tab commented out - loan officers don't need this, it's just a lead generation tool
            // Expanded(
            //   child: _buildTab(context, 'My Loans', 1, Icons.account_balance),
            // ),
            Expanded(
              child: _buildTab(context, 'ZIP Codes', 1, Icons.location_on),
            ),
            Expanded(child: _buildTab(context, 'Billing', 2, Icons.payment)),
            Expanded(child: _buildTab(context, 'Checklists', 3, Icons.checklist_rtl)),
            Expanded(child: _buildTab(context, 'Stats', 4, Icons.analytics)),
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
        // My Loans section commented out - loan officers don't need this, it's just a lead generation tool
        // case 1:
        //   return _buildMyLoans(context);
        case 1:
          return _buildZipManagement(context);
        case 2:
          return _buildBilling(context);
        case 3:
          return _buildChecklists(context);
        case 4:
          return _buildStats(context);
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
                      Icon(stat['icon'], color: AppTheme.lightGreen, size: 22),
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
                    onPressed: () => controller.setSelectedTab(2),
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
                      Get.snackbar('Info', 'Compliance tutorial coming soon!');
                    },
                    icon: Icons.school,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Edit Profile',
                    onPressed: () {
                      Get.to(() => const LoanOfficerProfileEditView());
                    },
                    icon: Icons.edit,
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
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
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteLoan(loan.id);
              Get.back();
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
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          CustomTextField(
            controller: TextEditingController(),
            labelText: 'Search ZIP codes',
            prefixIcon: Icons.search,
            onChanged: (value) => controller.searchZipCodes(value),
          ),

          const SizedBox(height: 20),

          // Claimed ZIP Codes
          Obx(
            () => Text(
              'Your Claimed ZIP Codes (${controller.claimedZipCodes.length}/6)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Obx(
            () => controller.claimedZipCodes.isEmpty
                ? _buildEmptyState(
                    context,
                    'No claimed ZIP codes',
                    'Start by claiming a ZIP code below',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.claimedZipCodes.length,
                    itemBuilder: (context, index) {
                      final zip = controller.claimedZipCodes[index];
                      return _buildZipCodeCard(context, zip, true);
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // Available ZIP Codes
          Text(
            'Available ZIP Codes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Obx(
            () => controller.availableZipCodes.isEmpty
                ? _buildEmptyState(
                    context,
                    'No available ZIP codes',
                    'All ZIP codes in your area are claimed',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.availableZipCodes.length,
                    itemBuilder: (context, index) {
                      final zip = controller.availableZipCodes[index];
                      return _buildZipCodeCard(context, zip, false);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildZipCodeCard(
    BuildContext context,
    ZipCodeModel zip,
    bool isClaimed,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zip.zipCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${zip.state} • Population: ${zip.population.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  Text(
                    '\$${zip.calculatedPrice.toStringAsFixed(2)}/month',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isClaimed)
              CustomButton(
                text: 'Release',
                onPressed: () => controller.releaseZipCode(zip),
                isOutlined: true,
                width: 90,
              )
            else
              CustomButton(
                text: 'Claim',
                onPressed: () => controller.claimZipCode(zip),
                width: 90,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilling(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Subscription
          Obx(() => Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Subscription',
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w500,
                          decoration: controller.isInFreePeriod 
                              ? TextDecoration.lineThrough 
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Current Monthly Cost (with free period if applicable)
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
                            controller.isInFreePeriod 
                                ? 'FREE' 
                                : '\$${controller.calculateMonthlyCost().toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: controller.isInFreePeriod 
                                  ? Colors.green 
                                  : AppTheme.lightGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (controller.isInFreePeriod)
                            Text(
                              '6 Months Free',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Free Period Info
                  if (controller.isInFreePeriod && controller.freePeriodEndsAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.celebration, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Free period ends: ${controller.freePeriodEndsAt!.toString().split(' ')[0]}. After that, you can continue at the normal subscription rate.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  Obx(
                    () => Row(
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
                  ),
                  
                  // Cancellation Status
                  if (controller.isCancelled)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
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
                                'Subscription will be cancelled in ${controller.daysUntilCancellation} days',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Promo Code Input Section
                  if (!controller.isInFreePeriod)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Have a promo code from an agent?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) => controller.setPromoCodeInput(value),
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
                                  Get.snackbar('Error', 'Please enter a promo code');
                                  return;
                                }
                                controller.applyPromoCode(controller.promoCodeInput);
                              },
                              width: 80,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter a promo code from an agent to get 6 months free. After that, you can choose to continue at the normal subscription rate.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  
                  CustomButton(
                    text: controller.isCancelled ? 'Cancellation Scheduled' : 'Cancel Subscription',
                    onPressed: controller.isCancelled 
                        ? null 
                        : () => _showCancelConfirmation(context),
                    isOutlined: true,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          )),

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

          _buildPaymentItem(context, 'December 2024', '\$199.99', 'Paid'),
          _buildPaymentItem(context, 'November 2024', '\$199.99', 'Paid'),
          _buildPaymentItem(context, 'October 2024', '\$199.99', 'Paid'),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
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
            onPressed: () => Get.back(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelSubscription();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
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
                color: AppTheme.lightGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    // Dummy data for loan officer
    final monthlyApplications = [28, 35, 32, 42, 48, 55, 51];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    final loanVolume = [2.5, 3.2, 2.8, 4.1, 4.8, 5.5, 5.0]; // in millions

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

          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _buildLoanStatsCard(
                  context,
                  'Total Applications',
                  '298',
                  Icons.description,
                  AppTheme.lightGreen,
                  '+18% from last month',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLoanStatsCard(
                  context,
                  'Approval Rate',
                  '78%',
                  Icons.check_circle,
                  Colors.teal,
                  '+5% from last month',
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
                  'Loan Volume',
                  '\$27.9M',
                  Icons.account_balance,
                  AppTheme.lightGreen,
                  '+22% from last month',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLoanStatsCard(
                  context,
                  'Avg. Interest Rate',
                  '6.2%',
                  Icons.trending_down,
                  Colors.blue,
                  '-0.3% from last month',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Monthly Applications Chart
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
                        'Monthly Applications',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '7 months',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
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

          // Loan Volume Chart
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
                        'Loan Volume (Millions)',
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
                          '+22%',
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

          // Application Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLoanActivityItem(
                    'Pre-Approvals',
                    187,
                    AppTheme.lightGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildLoanActivityItem('In Process', 89, Colors.teal),
                  const SizedBox(height: 12),
                  _buildLoanActivityItem('Approved', 67, Colors.blue),
                  const SizedBox(height: 12),
                  _buildLoanActivityItem('Funded', 23, Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(data.length, (index) {
              final value = data[index];
              final height = (value / maxValue) * 150;

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

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 64, color: AppTheme.mediumGray),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
            ),
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
    final paint = Paint()
      ..color = AppTheme.lightGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pointPaint = Paint()
      ..color = AppTheme.lightGreen
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - (data[i] / maxValue) * size.height;

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
