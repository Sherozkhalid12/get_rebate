import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/modules/proposals/controllers/lead_detail_controller.dart';

class LeadDetailView extends GetView<LeadDetailController> {
  const LeadDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text(
          'Lead Details',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        iconTheme: const IconThemeData(color: AppTheme.white),
        actions: [
          Obx(() {
            if (controller.lead != null) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refresh,
                tooltip: 'Refresh',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        // Loading state with SpinKit
        if (controller.isLoading) {
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
                  'Loading lead details...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                ),
              ],
            ),
          );
        }

        // Error state
        if (controller.error != null || controller.lead == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 60.sp,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Error Loading Lead',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    controller.error ?? 'Lead not found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final args = Get.arguments as Map<String, dynamic>?;
                      final leadId = args?['leadId']?.toString();
                      if (leadId != null && leadId.isNotEmpty) {
                        await controller.findLeadById(leadId);
                      } else {
                        Get.back();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Lead data display
        final lead = controller.lead!;
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Hero Header Section
                _buildHeroHeader(context, lead)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, duration: 300.ms),
                
                // Content Section
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // Contact Information Section
                      if (_hasContactInfo(lead))
                        _buildSectionCard(
                          context,
                          title: 'Contact Information',
                          icon: Icons.contact_phone_outlined,
                          color: Colors.blue,
                          children: _buildContactInfo(context, lead),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideY(begin: 0.2, duration: 400.ms, delay: 100.ms),
                      
                      if (_hasContactInfo(lead)) SizedBox(height: 16.h),
                      
                      // Property Information Section
                      if (_hasPropertyInfo(lead))
                        _buildSectionCard(
                          context,
                          title: 'Property Information',
                          icon: Icons.home_outlined,
                          color: Colors.green,
                          children: _buildPropertyInfo(context, lead),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),
                      
                      if (_hasPropertyInfo(lead)) SizedBox(height: 16.h),
                      
                      // Requirements & Preferences Section
                      if (_hasRequirements(lead))
                        _buildSectionCard(
                          context,
                          title: 'Requirements & Preferences',
                          icon: Icons.checklist_outlined,
                          color: Colors.orange,
                          children: _buildRequirements(context, lead),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 300.ms)
                            .slideY(begin: 0.2, duration: 400.ms, delay: 300.ms),
                      
                      if (_hasRequirements(lead)) SizedBox(height: 16.h),
                      
                      // Additional Details Section
                      if (_hasAdditionalDetails(lead))
                        _buildSectionCard(
                          context,
                          title: 'Additional Details',
                          icon: Icons.info_outline,
                          color: Colors.purple,
                          children: _buildAdditionalDetails(context, lead),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 400.ms)
                            .slideY(begin: 0.2, duration: 400.ms, delay: 400.ms),
                      
                      if (_hasAdditionalDetails(lead)) SizedBox(height: 16.h),
                      
                      // Assigned Agent Section
                      if (lead.agentId != null && lead.agentId!.id.isNotEmpty)
                        _buildSectionCard(
                          context,
                          title: 'Assigned Agent',
                          icon: Icons.person_outline,
                          color: Colors.teal,
                          children: _buildAgentInfo(context, lead),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 500.ms)
                            .slideY(begin: 0.2, duration: 400.ms, delay: 500.ms),
                      
                      if (lead.agentId != null && lead.agentId!.id.isNotEmpty) 
                        SizedBox(height: 16.h),
                      
                      // Comments Section
                      if (lead.comments != null && lead.comments!.isNotEmpty)
                        _buildCommentsCard(context, lead)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 600.ms)
                            .slideY(begin: 0.2, duration: 400.ms, delay: 600.ms),
                      
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeroHeader(BuildContext context, LeadModel lead) {
    final leadType = lead.isBuyingLead ? 'Buying Lead' : 'Selling Lead';
    final leadColor = lead.isBuyingLead ? Colors.green : Colors.orange;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lead Type Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lead.isBuyingLead ? Icons.home_outlined : Icons.sell_outlined,
                  size: 18.sp,
                  color: AppTheme.white,
                ),
                SizedBox(width: 8.w),
                Text(
                  leadType,
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Lead Name/Title
          Text(
            lead.fullName ?? 'Lead',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          // Date and Status
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16.sp,
                color: AppTheme.white.withOpacity(0.9),
              ),
              SizedBox(width: 8.w),
              Text(
                lead.formattedDate,
                style: TextStyle(
                  color: AppTheme.white.withOpacity(0.9),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 16.w),
              if (lead.agentId != null && lead.agentId!.id.isNotEmpty) ...[
                Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.green.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Assigned',
                  style: TextStyle(
                    color: Colors.green.shade200,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.orange.shade200,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24.sp,
                    color: color,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContactInfo(BuildContext context, LeadModel lead) {
    final items = <Widget>[];
    
    if (lead.fullName != null && lead.fullName!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Full Name',
        value: lead.fullName!,
        icon: Icons.person_outlined,
      ));
    }
    
    if (lead.email != null && lead.email!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Email',
        value: lead.email!,
        icon: Icons.email_outlined,
        isEmail: true,
      ));
    }
    
    if (lead.phone != null && lead.phone!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Phone',
        value: lead.phone!,
        icon: Icons.phone_outlined,
        isPhone: true,
      ));
    }
    
    if (lead.preferredContact != null && lead.preferredContact!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Preferred Contact',
        value: lead.preferredContact!,
        icon: Icons.contact_support_outlined,
      ));
    }
    
    if (lead.bestTime != null && lead.bestTime!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Best Time to Reach',
        value: lead.bestTime!,
        icon: Icons.access_time_outlined,
      ));
    }
    
    return items.isEmpty ? [_buildEmptyState('No contact information available')] : items;
  }

  List<Widget> _buildPropertyInfo(BuildContext context, LeadModel lead) {
    final items = <Widget>[];
    
    if (lead.propertyInformation != null) {
      final propInfo = lead.propertyInformation!;
      if (propInfo.fullAddress.isNotEmpty && propInfo.fullAddress != 'Address not provided') {
        items.add(_buildDetailRow(
          context,
          label: 'Property Address',
          value: propInfo.fullAddress,
          icon: Icons.location_on_outlined,
        ));
      }
      if (propInfo.squareFeet != null && propInfo.squareFeet!.isNotEmpty) {
        items.add(_buildDetailRow(
          context,
          label: 'Square Feet',
          value: '${propInfo.squareFeet} sq ft',
          icon: Icons.square_foot_outlined,
        ));
      }
      if (propInfo.yearBuilt != null && propInfo.yearBuilt!.isNotEmpty) {
        items.add(_buildDetailRow(
          context,
          label: 'Year Built',
          value: propInfo.yearBuilt!,
          icon: Icons.calendar_today_outlined,
        ));
      }
    }
    
    if (lead.propertyType != null && lead.propertyType!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Property Type',
        value: lead.propertyType!,
        icon: Icons.category_outlined,
      ));
    }
    
    if (lead.priceRange != null && lead.priceRange!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Price Range',
        value: lead.priceRange!,
        icon: Icons.attach_money_outlined,
        isImportant: true,
      ));
    }
    
    if (lead.idealSellingPrice != null && lead.idealSellingPrice!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Ideal Selling Price',
        value: lead.idealSellingPrice!,
        icon: Icons.attach_money_outlined,
        isImportant: true,
      ));
    }
    
    if (lead.bedrooms != null) {
      items.add(_buildDetailRow(
        context,
        label: 'Bedrooms',
        value: lead.bedrooms.toString(),
        icon: Icons.bed_outlined,
      ));
    }
    
    if (lead.bathrooms != null) {
      items.add(_buildDetailRow(
        context,
        label: 'Bathrooms',
        value: lead.bathrooms.toString(),
        icon: Icons.bathtub_outlined,
      ));
    }
    
    if (lead.planningArea != null && lead.planningArea!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Planning Area',
        value: lead.planningArea!,
        icon: Icons.map_outlined,
      ));
    }
    
    return items.isEmpty ? [_buildEmptyState('No property information available')] : items;
  }

  List<Widget> _buildRequirements(BuildContext context, LeadModel lead) {
    final items = <Widget>[];
    
    if (lead.buyingOrBuilding != null && lead.buyingOrBuilding!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Looking For',
        value: lead.buyingOrBuilding!.toUpperCase(),
        icon: Icons.search_outlined,
        isImportant: true,
      ));
    }
    
    if (lead.timeFrame != null && lead.timeFrame!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Time Frame',
        value: lead.timeFrame!,
        icon: Icons.schedule_outlined,
      ));
    }
    
    if (lead.preApproved != null && lead.preApproved!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Pre-Approved',
        value: lead.preApproved!,
        icon: Icons.check_circle_outline,
      ));
    }
    
    if (lead.mustHaveFeatures != null && lead.mustHaveFeatures!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Must Have Features',
        value: lead.mustHaveFeatures!,
        icon: Icons.star_outlined,
        isImportant: true,
      ));
    }
    
    if (lead.workingWithAgent != null) {
      items.add(_buildDetailRow(
        context,
        label: 'Currently Working with Agent',
        value: lead.workingWithAgent! ? 'Yes' : 'No',
        icon: Icons.person_outline,
      ));
    }
    
    if (lead.rebateAwareness != null && lead.rebateAwareness!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Rebate Awareness',
        value: lead.rebateAwareness!,
        icon: Icons.info_outline,
      ));
    }
    
    if (lead.howHeard != null && lead.howHeard!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'How Did You Hear About Us',
        value: lead.howHeard!,
        icon: Icons.hearing_outlined,
      ));
    }
    
    if (lead.loanOfficerRebate != null && lead.loanOfficerRebate!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Loan Officer Rebate',
        value: lead.loanOfficerRebate!,
        icon: Icons.account_balance_outlined,
      ));
    }
    
    if (lead.autoMlsSearch != null) {
      items.add(_buildDetailRow(
        context,
        label: 'Auto MLS Search',
        value: lead.autoMlsSearch! ? 'Enabled' : 'Disabled',
        icon: Icons.search_outlined,
      ));
    }
    
    return items.isEmpty ? [_buildEmptyState('No requirements specified')] : items;
  }

  List<Widget> _buildAdditionalDetails(BuildContext context, LeadModel lead) {
    final items = <Widget>[];
    
    if (lead.currentlyLiving != null && lead.currentlyLiving!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Currently Living',
        value: lead.currentlyLiving!,
        icon: Icons.home_outlined,
      ));
    }
    
    if (lead.renovation != null && lead.renovation!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Renovation Plans',
        value: lead.renovation!,
        icon: Icons.construction_outlined,
      ));
    }
    
    if (lead.whenPlanningSell != null && lead.whenPlanningSell!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'When Planning to Sell',
        value: lead.whenPlanningSell!,
        icon: Icons.calendar_today_outlined,
      ));
    }
    
    if (lead.howMotivatedToSell != null && lead.howMotivatedToSell!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Motivation to Sell',
        value: lead.howMotivatedToSell!,
        icon: Icons.trending_up_outlined,
      ));
    }
    
    if (lead.mostImportantToYou != null && lead.mostImportantToYou!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Most Important',
        value: lead.mostImportantToYou!,
        icon: Icons.priority_high_outlined,
        isImportant: true,
      ));
    }
    
    if (lead.howMuchRebateCouldBe != null && lead.howMuchRebateCouldBe!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Expected Rebate',
        value: lead.howMuchRebateCouldBe!,
        icon: Icons.monetization_on_outlined,
        isImportant: true,
      ));
    }
    
    if (lead.isPropertyListed != null) {
      items.add(_buildDetailRow(
        context,
        label: 'Property Listed',
        value: lead.isPropertyListed! ? 'Yes' : 'No',
        icon: Icons.list_alt_outlined,
      ));
    }
    
    return items.isEmpty ? [_buildEmptyState('No additional details available')] : items;
  }

  List<Widget> _buildAgentInfo(BuildContext context, LeadModel lead) {
    final agent = lead.agentId!;
    final items = <Widget>[];
    
    if (agent.fullname != null && agent.fullname!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Agent Name',
        value: agent.fullname!,
        icon: Icons.person,
        isImportant: true,
      ));
    }
    
    if (agent.email != null && agent.email!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Email',
        value: agent.email!,
        icon: Icons.email,
        isEmail: true,
      ));
    }
    
    if (agent.phone != null && agent.phone!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Phone',
        value: agent.phone!,
        icon: Icons.phone,
        isPhone: true,
      ));
    }
    
    if (agent.role != null && agent.role!.isNotEmpty) {
      items.add(_buildDetailRow(
        context,
        label: 'Role',
        value: agent.role!,
        icon: Icons.badge_outlined,
      ));
    }
    
    return items.isEmpty ? [_buildEmptyState('No agent information available')] : items;
  }

  Widget _buildCommentsCard(BuildContext context, LeadModel lead) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.comment_outlined,
                    size: 24.sp,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Comments & Notes',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                lead.comments!,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppTheme.darkGray,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isImportant = false,
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: isImportant ? AppTheme.primaryBlue : AppTheme.mediumGray,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () {
                    if (isEmail && value.isNotEmpty) {
                      // Open email
                    } else if (isPhone && value.isNotEmpty) {
                      // Make phone call
                    }
                  },
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: isImportant ? AppTheme.primaryBlue : AppTheme.darkGray,
                      fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.mediumGray,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  bool _hasContactInfo(LeadModel lead) {
    return (lead.fullName != null && lead.fullName!.isNotEmpty) ||
           (lead.email != null && lead.email!.isNotEmpty) ||
           (lead.phone != null && lead.phone!.isNotEmpty) ||
           (lead.preferredContact != null && lead.preferredContact!.isNotEmpty) ||
           (lead.bestTime != null && lead.bestTime!.isNotEmpty);
  }

  bool _hasPropertyInfo(LeadModel lead) {
    return lead.propertyInformation != null ||
           (lead.propertyType != null && lead.propertyType!.isNotEmpty) ||
           (lead.priceRange != null && lead.priceRange!.isNotEmpty) ||
           (lead.idealSellingPrice != null && lead.idealSellingPrice!.isNotEmpty) ||
           lead.bedrooms != null ||
           lead.bathrooms != null ||
           (lead.planningArea != null && lead.planningArea!.isNotEmpty);
  }

  bool _hasRequirements(LeadModel lead) {
    return (lead.buyingOrBuilding != null && lead.buyingOrBuilding!.isNotEmpty) ||
           (lead.timeFrame != null && lead.timeFrame!.isNotEmpty) ||
           (lead.preApproved != null && lead.preApproved!.isNotEmpty) ||
           (lead.mustHaveFeatures != null && lead.mustHaveFeatures!.isNotEmpty) ||
           lead.workingWithAgent != null ||
           (lead.rebateAwareness != null && lead.rebateAwareness!.isNotEmpty) ||
           (lead.howHeard != null && lead.howHeard!.isNotEmpty) ||
           (lead.loanOfficerRebate != null && lead.loanOfficerRebate!.isNotEmpty) ||
           lead.autoMlsSearch != null;
  }

  bool _hasAdditionalDetails(LeadModel lead) {
    return (lead.currentlyLiving != null && lead.currentlyLiving!.isNotEmpty) ||
           (lead.renovation != null && lead.renovation!.isNotEmpty) ||
           (lead.whenPlanningSell != null && lead.whenPlanningSell!.isNotEmpty) ||
           (lead.howMotivatedToSell != null && lead.howMotivatedToSell!.isNotEmpty) ||
           (lead.mostImportantToYou != null && lead.mostImportantToYou!.isNotEmpty) ||
           (lead.howMuchRebateCouldBe != null && lead.howMuchRebateCouldBe!.isNotEmpty) ||
           lead.isPropertyListed != null;
  }
}
