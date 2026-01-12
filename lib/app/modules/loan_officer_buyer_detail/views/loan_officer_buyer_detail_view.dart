import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/loan_officer_buyer_detail/controllers/loan_officer_buyer_detail_controller.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';
import 'package:intl/intl.dart';

class LoanOfficerBuyerDetailView extends GetView<LoanOfficerBuyerDetailController> {
  const LoanOfficerBuyerDetailView({super.key});

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
          'Buyer Details',
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
        child: Obx(() {
          final connection = controller.buyerConnection;
          
          if (connection == null) {
            return Center(
              child: Text(
                'No buyer information available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGray,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buyer Info Card
                GradientCard(
                  gradientColors: AppTheme.cardGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.lightGreen.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.lightGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connection.buyerName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildStatusBadge(context, connection.status),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        context,
                        Icons.calendar_today_outlined,
                        'Selected Date',
                        DateFormat('MMMM d, yyyy').format(connection.selectedAt),
                      ),
                      if (connection.buyerEmail != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.email_outlined,
                          'Email',
                          connection.buyerEmail!,
                        ),
                      ],
                      if (connection.buyerPhone != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.phone_outlined,
                          'Phone',
                          connection.buyerPhone!,
                        ),
                      ],
                      if (connection.preferredContactMethod != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          Icons.contact_mail_outlined,
                          'Preferred Contact Method',
                          connection.preferredContactMethod!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Checklist Status Card
                GradientCard(
                  gradientColors: AppTheme.cardGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checklist Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            connection.checklistCompleted
                                ? Icons.check_circle
                                : Icons.pending_outlined,
                            size: 32,
                            color: connection.checklistCompleted
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connection.checklistCompleted
                                      ? 'Checklist Completed'
                                      : 'Checklist Pending',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (connection.checklistCompletedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed on ${DateFormat('MMMM d, yyyy').format(connection.checklistCompletedAt!)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'The buyer has not completed the checklist yet.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Note Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have limited access to buyer information. Financial documents and detailed personal data are not available through this platform.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkGray,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
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
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.lightGreen,
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
          fontSize: 11,
        ),
      ),
    );
  }
}


