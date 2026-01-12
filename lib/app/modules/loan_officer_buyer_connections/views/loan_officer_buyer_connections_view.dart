import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer_buyer_connections/controllers/loan_officer_buyer_connections_controller.dart';
import 'package:getrebate/app/modules/loan_officer_buyer_detail/views/loan_officer_buyer_detail_view.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class LoanOfficerBuyerConnectionsView extends GetView<LoanOfficerBuyerConnectionsController> {
  const LoanOfficerBuyerConnectionsView({super.key});

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
          'Buyer Connections',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Filter
            _buildStatusFilter(context),
            
            // Connections List
            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.buyerConnections.isEmpty) {
                  return const Center(
                    child: SpinKitFadingCircle(
                      color: AppTheme.lightGreen,
                      size: 40,
                    ),
                  );
                }

                final filteredConnections = controller.filteredConnections;

                if (filteredConnections.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshConnections,
                  color: AppTheme.lightGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredConnections.length,
                    itemBuilder: (context, index) {
                      final connection = filteredConnections[index];
                      return _buildConnectionCard(context, connection);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              context,
              'All',
              'all',
              controller.selectedStatus == 'all',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              context,
              'Active',
              'active',
              controller.selectedStatus == 'active',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              context,
              'Removed',
              'removed',
              controller.selectedStatus == 'removed',
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => controller.setStatusFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightGreen : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.lightGreen : AppTheme.mediumGray,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.white : AppTheme.darkGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppPages.LOAN_OFFICER_BUYER_DETAIL,
            arguments: {'buyerConnection': connection},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.lightGreen.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.lightGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.buyerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selected ${_formatDate(connection.selectedAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, connection.status),
                ],
              ),
              const SizedBox(height: 12),
              if (connection.preferredContactMethod != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.contact_mail_outlined,
                      size: 16,
                      color: AppTheme.mediumGray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Preferred: ${connection.preferredContactMethod}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    connection.checklistCompleted
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    size: 16,
                    color: connection.checklistCompleted
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    connection.checklistCompleted
                        ? 'Checklist Completed'
                        : 'Checklist Pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: connection.checklistCompleted
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isActive ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No Buyer Connections',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buyers who select you as their loan officer will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}


