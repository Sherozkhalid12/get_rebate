import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/proposals/controllers/proposal_controller.dart';
import 'package:getrebate/app/models/proposal_model.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:intl/intl.dart';

class ProposalsView extends GetView<ProposalController> {
  const ProposalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text(
          'My Proposals',
          style: TextStyle(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(context),
          
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.proposals.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitFadingCircle(
                        color: AppTheme.primaryBlue,
                        size: 50.0,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Loading your leads and proposals...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                );
              }

              // Access displayItems directly - it's already reactive
              final displayItems = controller.displayItems;

              if (displayItems.isEmpty && !controller.isLoading) {
                return _buildEmptyState(context);
              }

              return _buildProposalsList(context, displayItems);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalsList(BuildContext context, List<ProposalModel> displayItems) {
    // Create ScrollController only once per build
    final ScrollController scrollController = ScrollController();
    
    // Handle scrolling to highlighted item and showing dialogs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScrollToHighlighted(scrollController, displayItems);
      _handlePendingDialogs(displayItems);
    });

    return RefreshIndicator(
      onRefresh: controller.loadProposals,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.only(top: 10.h, left: 20.w, right: 20.w, bottom: 20.h),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final proposal = displayItems[index];
          final isHighlighted = controller.highlightedProposalId == proposal.id ||
                                controller.highlightedLeadId == proposal.id;
          return _buildProposalCard(context, proposal, index, isHighlighted: isHighlighted)
              .animate()
              .fadeIn(duration: 400.ms, delay: (index * 50).ms)
              .slideY(begin: 0.2, duration: 400.ms, delay: (index * 50).ms, curve: Curves.easeOut);
        },
      ),
    );
  }

  void _handleScrollToHighlighted(ScrollController scrollController, List<ProposalModel> displayItems) {
    final highlightedProposalId = controller.highlightedProposalId;
    final highlightedLeadId = controller.highlightedLeadId;
    final highlightedId = highlightedProposalId ?? highlightedLeadId;
    
    if (highlightedId != null && scrollController.hasClients) {
      final index = displayItems.indexWhere((p) => p.id == highlightedId);
      if (index != -1) {
        // Calculate approximate position (card height + margin + tab height)
        final cardHeight = 200.0;
        final margin = 16.0;
        final tabHeight = 60.0;
        final position = index * (cardHeight + margin) + tabHeight;
        scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _handlePendingDialogs(List<ProposalModel> displayItems) {
    if (displayItems.isEmpty) return;

    // Get context from current route
    final context = Get.context;
    if (context == null) return;

    // Check for pending review dialog
    final reviewProposalId = controller.pendingReviewProposalId;
    if (reviewProposalId != null && !controller.isLoading) {
      final proposal = displayItems.firstWhere(
        (p) => p.id == reviewProposalId,
        orElse: () => displayItems.first,
      );
      controller.clearDialogFlags();
      // Use Future.microtask to ensure dialog shows after current frame
      Future.microtask(() => _showReviewDialog(context, proposal));
      return;
    }

    // Check for pending report dialog
    final reportProposalId = controller.pendingReportProposalId;
    if (reportProposalId != null && !controller.isLoading) {
      final proposal = displayItems.firstWhere(
        (p) => p.id == reportProposalId,
        orElse: () => displayItems.first,
      );
      controller.clearDialogFlags();
      // Use Future.microtask to ensure dialog shows after current frame
      Future.microtask(() => _showReportDialog(context, proposal));
    }
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final selectedFilter = controller.selectedFilter;
          return Row(
            children: [
              _buildFilterTab(
                context,
                label: 'All',
                count: controller.allCount,
                filter: 'all',
                isSelected: selectedFilter == 'all',
              ),
              SizedBox(width: 12.w),
              _buildFilterTab(
                context,
                label: 'Pending',
                count: controller.pendingCount,
                filter: 'pending',
                isSelected: selectedFilter == 'pending',
              ),
              SizedBox(width: 12.w),
              _buildFilterTab(
                context,
                label: 'Accepted',
                count: controller.acceptedCount,
                filter: 'accepted',
                isSelected: selectedFilter == 'accepted',
              ),
              SizedBox(width: 12.w),
              _buildFilterTab(
                context,
                label: 'Completed',
                count: controller.completedCount,
                filter: 'completed',
                isSelected: selectedFilter == 'completed',
              ),
              SizedBox(width: 12.w),
              _buildFilterTab(
                context,
                label: 'Reported',
                count: controller.reportedCount,
                filter: 'reported',
                isSelected: selectedFilter == 'reported',
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context, {
    required String label,
    required int count,
    required String filter,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(18.r),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.white : AppTheme.darkGray,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.white.withOpacity(0.25) 
                    : AppTheme.mediumGray.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.white : AppTheme.darkGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Access reactive values directly since we're already inside Obx
    if (controller.error != null && controller.proposals.isEmpty && !controller.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40.sp,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Error Loading Leads',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                controller.error ?? 'An error occurred',
                style: TextStyle(
                  color: AppTheme.mediumGray,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: controller.loadProposals,
                icon: Icon(Icons.refresh, size: 16.sp),
                label: Text('Retry', style: TextStyle(fontSize: 13.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get context-aware empty state based on selected filter
    final selectedFilter = controller.selectedFilter;
    String title;
    String message;
    IconData icon;
    
    switch (selectedFilter) {
      case 'pending':
        title = 'No Pending Proposals';
        message = 'You don\'t have any pending proposals at the moment.';
        icon = Icons.pending_outlined;
        break;
      case 'accepted':
        title = 'No Accepted Proposals';
        message = 'You don\'t have any accepted proposals yet.';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        title = 'No Completed Proposals';
        message = 'Your completed proposals will appear here.';
        icon = Icons.task_alt_outlined;
        break;
      case 'reported':
        title = 'No Reported Issues';
        message = 'You haven\'t reported any proposals.';
        icon = Icons.flag_outlined;
        break;
      default:
        title = 'No Leads or Proposals';
        message = 'Your leads and proposals will appear here once you start working with agents or loan officers.';
        icon = Icons.description_outlined;
    }

    // Compact empty state
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40.sp,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 13.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard(
    BuildContext context,
    ProposalModel proposal,
    int index, {
    bool isHighlighted = false,
  }) {
    // Check if this is a lead (by checking if lead exists for this proposal ID)
    final lead = controller.getLead(proposal.id);
    final isLead = lead != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(
                color: AppTheme.primaryBlue,
                width: 2.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppTheme.primaryBlue.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: isHighlighted ? 20 : 10,
            offset: const Offset(0, 4),
            spreadRadius: isHighlighted ? 3 : 0,
          ),
        ],
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLead && lead != null) {
                // Navigate to lead detail
                _navigateToLeadDetail(context, lead);
              } else {
                // Show proposal details
                _showProposalDetails(context, proposal);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status and type badge
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge for leads
                            if (isLead)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_search_outlined,
                                      size: 12,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Lead',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isLead) const SizedBox(height: 8),
                            Text(
                              proposal.professionalName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              proposal.professionalType == 'agent'
                                  ? 'Real Estate Agent'
                                  : 'Loan Officer',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.mediumGray,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(context, proposal.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Message preview
                  if (proposal.message != null && proposal.message!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLead)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, top: 2),
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              proposal.message!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.darkGray,
                                    height: 1.4,
                                  ),
                              maxLines: isLead ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Property info if available
                  if (proposal.propertyAddress != null && proposal.propertyAddress!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          isLead ? Icons.home_outlined : Icons.location_on,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            proposal.propertyAddress!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Price info if available
                  if (proposal.propertyPrice != null && proposal.propertyPrice!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          proposal.propertyPrice!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Action buttons based on status
                  _buildActionButtons(context, proposal),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ProposalStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case ProposalStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        icon = Icons.pending;
        break;
      case ProposalStatus.accepted:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        icon = Icons.check_circle_outline;
        break;
      case ProposalStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        break;
      case ProposalStatus.inProgress:
        backgroundColor = AppTheme.primaryBlue.withOpacity(0.1);
        textColor = AppTheme.primaryBlue;
        icon = Icons.work_outline;
        break;
      case ProposalStatus.completed:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case ProposalStatus.reported:
        backgroundColor = Colors.deepOrange.withOpacity(0.1);
        textColor = Colors.deepOrange.shade700;
        icon = Icons.report_problem_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProposalModel proposal) {
    if (proposal.status == ProposalStatus.inProgress) {
      return _buildInProgressActions(context, proposal);
    } else if (proposal.status == ProposalStatus.completed) {
      return _buildCompletedActions(context, proposal);
    } else if (proposal.status == ProposalStatus.reported) {
      return _buildReportedActions(context, proposal);
    } else if (proposal.status == ProposalStatus.accepted) {
      // Show only "Report Issue" button for accepted proposals (no "Complete Service")
      return _buildAcceptedActions(context, proposal);
    } else if (proposal.status == ProposalStatus.rejected) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }

  Widget _buildInProgressActions(BuildContext context, ProposalModel proposal) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteServiceDialog(context, proposal),
            icon: Icon(Icons.check_circle_outline, size: 18.sp),
            label: Text(
              'Complete Service',
              style: TextStyle(fontSize: 14.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (!proposal.userHasReviewed) ...[
          SizedBox(height: 8.h),
          TextButton.icon(
            onPressed: () => _showReportDialog(context, proposal),
            icon: Icon(Icons.flag_outlined, size: 16.sp),
            label: Text(
              'Report Issue',
              style: TextStyle(fontSize: 13.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAcceptedActions(BuildContext context, ProposalModel proposal) {
    // Hide report button if review has been given
    if (proposal.userHasReviewed) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showReportDialog(context, proposal),
          icon: Icon(Icons.flag_outlined, size: 16.sp),
          label: Text(
            'Report Issue',
            style: TextStyle(fontSize: 13.sp),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          ),
        ),
      ],
    );
  }

  Widget _buildReportedActions(BuildContext context, ProposalModel proposal) {
    // Get lead to check if it's a reported lead
    final lead = controller.getLead(proposal.id);
    final isLead = lead != null;

    return Column(
      children: [
        const Divider(),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.deepOrange.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.report_problem_outlined, color: Colors.deepOrange.shade700, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue Reported',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.deepOrange.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'This lead has been reported. Please contact support if needed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.deepOrange.shade600,
                            fontSize: 12.sp,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (proposal.reportReason != null && proposal.reportReason!.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Reason:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mediumGray,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  proposal.reportReason!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedActions(BuildContext context, ProposalModel proposal) {
    // Get lead to check if it's completed
    final lead = controller.getLead(proposal.id);
    final isLead = lead != null;

    if (proposal.userHasReviewed) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Review submitted successfully',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Divider(),
        SizedBox(height: 16.h),
        // Review Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showReviewDialog(context, proposal),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 18.sp, color: AppTheme.white),
                    SizedBox(width: 8.w),
                    Text(
                      'Give Review to Agent',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!proposal.userHasReviewed) ...[
          SizedBox(height: 12.h),
          // Report Issue Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReportDialog(context, proposal),
              icon: Icon(Icons.flag_outlined, size: 18.sp, color: Colors.red.shade600),
              label: Text(
                'Report an Issue',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                side: BorderSide(color: Colors.red.shade600, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCreateProposalDialog(BuildContext context) {
    // This would navigate to a screen where user selects agent/loan officer
    // For now, show a placeholder
    Get.snackbar(
      'Create Proposal',
      'Navigate to agent/loan officer profile to create a proposal',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.primaryBlue,
      colorText: AppTheme.white,
    );
  }

  void _showProposalDetails(BuildContext context, ProposalModel proposal) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Proposal Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Status', proposal.status.label),
            _buildDetailRow('Professional', proposal.professionalName),
            _buildDetailRow('Type', proposal.professionalType == 'agent' ? 'Agent' : 'Loan Officer'),
            if (proposal.message != null) _buildDetailRow('Message', proposal.message!),
            if (proposal.propertyAddress != null)
              _buildDetailRow('Property', proposal.propertyAddress!),
            _buildDetailRow('Created', _formatDate(proposal.createdAt)),
            if (proposal.acceptedAt != null)
              _buildDetailRow('Accepted', _formatDate(proposal.acceptedAt!)),
            if (proposal.completedAt != null)
              _buildDetailRow('Completed', _formatDate(proposal.completedAt!)),
            if (proposal.rejectionReason != null)
              _buildDetailRow('Rejection Reason', proposal.rejectionReason!),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteServiceDialog(BuildContext context, ProposalModel proposal) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Service',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mark this service as completed? You\'ll be able to submit a review afterward.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        final success = await controller.completeService(proposal.id);
                        if (success) {
                          _showReviewDialog(context, proposal);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Complete'),
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

  void _showReviewDialog(BuildContext context, ProposalModel proposal) {
    final ratingController = 0.obs;
    final reviewController = TextEditingController();
    final reviewText = ''.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400.w,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppTheme.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Rate Your Experience',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.white, size: 20.sp),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Star rating
                        Center(
                          child: Obx(() => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  final isSelected = index < ratingController.value;
                                  return GestureDetector(
                                    onTap: () => ratingController.value = index + 1,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                                      child: Icon(
                                        isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isSelected 
                                            ? Colors.amber.shade600
                                            : AppTheme.mediumGray.withOpacity(0.4),
                                        size: 36.sp,
                                      ),
                                    ),
                                  );
                                }),
                              )),
                        ),
                        SizedBox(height: 8.h),
                        Center(
                          child: Obx(() => Text(
                                ratingController.value == 0
                                    ? 'Tap to rate'
                                    : '${ratingController.value} ${ratingController.value == 1 ? 'Star' : 'Stars'}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.mediumGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                        ),
                        SizedBox(height: 16.h),
                        // Review text
                        Text(
                          'Your Review',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppTheme.mediumGray.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: reviewController,
                            maxLines: 4,
                            style: TextStyle(fontSize: 13.sp),
                            decoration: InputDecoration(
                              hintText: 'Write your review here...',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.mediumGray.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12.w),
                            ),
                            onChanged: (value) => reviewText.value = value,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                // Action buttons
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray.withOpacity(0.3),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.darkGray,
                            side: BorderSide(
                              color: AppTheme.mediumGray.withOpacity(0.3),
                              width: 1,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                              onPressed: controller.isLoading || 
                                      ratingController.value == 0 || 
                                      reviewText.value.trim().isEmpty
                                  ? null
                                  : () async {
                                      Get.back();
                                      await controller.submitReview(
                                        proposalId: proposal.id,
                                        professionalId: proposal.professionalId,
                                        professionalType: proposal.professionalType,
                                        rating: ratingController.value,
                                        review: reviewText.value.trim(),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: AppTheme.white,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                elevation: 0,
                              ),
                              child: controller.isLoading
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                      ),
                                    )
                                  : Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
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
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  void _showReportDialog(BuildContext context, ProposalModel proposal) {
    final descriptionController = TextEditingController();
    final selectedReason = Rxn<String>();
    final descriptionText = ''.obs;

    final reasons = [
      {'label': 'Service failure', 'icon': Icons.build_circle_outlined},
      {'label': 'Behavioral issues', 'icon': Icons.person_off_outlined},
      {'label': 'Delays', 'icon': Icons.access_time_outlined},
      {'label': 'Unmet expectations', 'icon': Icons.highlight_off_outlined},
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.red.shade100,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: Colors.red.shade600,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Report an Issue',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20.sp, color: AppTheme.mediumGray),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reason selection
                        Text(
                          'Select a reason',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Obx(() => Column(
                              children: reasons.map((reasonData) {
                                final reason = reasonData['label'] as String;
                                final icon = reasonData['icon'] as IconData;
                                final isSelected = selectedReason.value == reason;
                                return GestureDetector(
                                  onTap: () => selectedReason.value = reason,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: EdgeInsets.only(bottom: 8.h),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.red.shade50
                                          : AppTheme.lightGray,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.red.shade600
                                            : AppTheme.mediumGray.withOpacity(0.2),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          color: isSelected
                                              ? Colors.red.shade600
                                              : AppTheme.mediumGray,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Text(
                                            reason,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.red.shade700
                                                  : AppTheme.darkGray,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.red.shade600,
                                            size: 18.sp,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            )),
                        SizedBox(height: 20.h),
                        // Description
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppTheme.mediumGray.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            style: TextStyle(fontSize: 13.sp),
                            onChanged: (value) => descriptionText.value = value,
                            decoration: InputDecoration(
                              hintText: 'Describe the issue...',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.mediumGray,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12.w),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action buttons
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.lightGray,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.darkGray,
                            side: BorderSide(
                              color: AppTheme.mediumGray.withOpacity(0.3),
                              width: 1,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                              onPressed: controller.isLoading ||
                                      selectedReason.value == null ||
                                      descriptionText.value.trim().isEmpty
                                  ? null
                                  : () async {
                                      Navigator.pop(context);
                                      await controller.submitReport(
                                        proposalId: proposal.id,
                                        reportedUserId: proposal.professionalId,
                                        reason: selectedReason.value!,
                                        description: descriptionText.value.trim(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: AppTheme.white,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: controller.isLoading
                                        ? SizedBox(
                                            width: 18.w,
                                            height: 18.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                            ),
                                          )
                                        : Text(
                                            'Submit',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                            )),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Navigate to lead detail view
  void _navigateToLeadDetail(BuildContext context, LeadModel lead) {
    Get.toNamed('/lead-detail', arguments: {'lead': lead});
  }
}

