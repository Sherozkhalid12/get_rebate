import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/models/notification_model.dart';
import 'package:getrebate/app/services/notification_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/error_handler.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/proposals/controllers/proposal_controller.dart';
import 'package:getrebate/app/routes/app_pages.dart';

class NotificationsController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  final AuthController _authController = Get.find<AuthController>();

  // Observable state
  final _notifications = <NotificationModel>[].obs;
  final _isLoading = false.obs;
  final _unreadCount = 0.obs;
  final _total = 0.obs;
  final _error = Rxn<String>();

  // Getters
  List<NotificationModel> get notifications => _notifications.toList();
  bool get isLoading => _isLoading.value;
  int get unreadCount => _unreadCount.value;
  int get total => _total.value;
  String? get error => _error.value;

  // Get unread notifications
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Get read notifications
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// Fetches notifications for the current user
  Future<void> fetchNotifications() async {
    final userId = _authController.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _error.value = 'User not logged in';
      return;
    }

    _isLoading.value = true;
    _error.value = null;

    try {
      final response = await _notificationService.getNotifications(userId);
      _notifications.value = response.notifications;
      _unreadCount.value = response.unreadCount;
      _total.value = response.total;

      if (kDebugMode) {
        print('✅ Notifications fetched successfully');
        print('   Total: ${response.total}');
        print('   Unread: ${response.unreadCount}');
      }
    } catch (e) {
      _error.value = e.toString();
      if (kDebugMode) {
        print('❌ Error fetching notifications: $e');
      }
      ErrorHandler.handleError(e, defaultMessage: 'Unable to load notifications. Please try again later.');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Marks a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markNotificationAsRead(notificationId);
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          // Recalculate unread count
          _unreadCount.value = _notifications.where((n) => !n.isRead).length;
        }

        if (kDebugMode) {
          print('✅ Notification marked as read: $notificationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking notification as read: $e');
      }
      ErrorHandler.handleError(e, defaultMessage: 'Unable to update notification. Please try again.');
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _authController.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      SnackbarHelper.showError('User not logged in');
      return;
    }

    try {
      final success = await _notificationService.markAllNotificationsAsRead(userId);
      if (success) {
        // Update local state
        _notifications.value = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _unreadCount.value = 0;

        if (kDebugMode) {
          print('✅ All notifications marked as read');
        }
        SnackbarHelper.showSuccess('All notifications marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking all notifications as read: $e');
      }
      SnackbarHelper.showError('Failed to mark all notifications as read');
    }
  }

  /// Refreshes notifications
  Future<void> refresh() async {
    await fetchNotifications();
  }

  /// Handles notification tap - marks as read and navigates if needed
  Future<void> handleNotificationTap(NotificationModel notification) async {
    // Check current state in the list (may have been marked as read already)
    final matchingNotifications = _notifications.where(
      (n) => n.id == notification.id,
    );
    
    // Mark as read if still unread
    if (matchingNotifications.isNotEmpty) {
      final currentNotification = matchingNotifications.first;
      if (!currentNotification.isRead) {
        await markAsRead(notification.id);
      }
    }

    // Handle navigation based on notification type
    final type = notification.type.toLowerCase();
    
    // Check if it's a lead-related notification (accepted lead/proposal)
    if (type.contains('lead') || type.contains('proposal')) {
      // Check for leadId first (for lead acceptance notifications)
      // The leadId field contains a LeadInfo object, so extract the ID
      String? leadId = notification.leadId?.id;
      
      // If leadId not found in leadId object, try to extract from message
      if (leadId == null || leadId.isEmpty) {
        final message = notification.message;
        // Try multiple patterns to extract lead ID
        var leadIdMatch = RegExp(r'lead[_\s]?id[:\s]+([a-zA-Z0-9]+)', caseSensitive: false)
            .firstMatch(message);
        if (leadIdMatch == null) {
          leadIdMatch = RegExp(r'lead[:\s]+([a-zA-Z0-9]{24})', caseSensitive: false)
              .firstMatch(message);
        }
        if (leadIdMatch != null) {
          leadId = leadIdMatch.group(1);
        }
      }
      
      // Check for proposalId (for proposal acceptance notifications)
      String? proposalId = notification.proposalId;
      
      if (proposalId == null || proposalId.isEmpty) {
        final message = notification.message;
        var proposalIdMatch = RegExp(r'proposal[_\s]?id[:\s]+([a-zA-Z0-9]+)', caseSensitive: false)
            .firstMatch(message);
        if (proposalIdMatch == null) {
          proposalIdMatch = RegExp(r'proposal[:\s]+([a-zA-Z0-9]{24})', caseSensitive: false)
              .firstMatch(message);
        }
        if (proposalIdMatch != null) {
          proposalId = proposalIdMatch.group(1);
        }
      }
      
      if (kDebugMode) {
        print('🔔 Notification tap - Type: $type');
        print('   LeadId: $leadId');
        print('   ProposalId: $proposalId');
        print('   AgentData: ${notification.agentData?.fullname}');
      }
      
      // Handle completed lead notification - show bottom sheet with Review and Report options
      if (type.contains('completed') && leadId != null && leadId.isNotEmpty) {
        if (kDebugMode) {
          print('✅ Handling completed lead notification: $leadId');
          print('   AgentData: ${notification.agentData?.fullname} (${notification.agentData?.id})');
        }
        // Show completed lead bottom sheet with agent data
        _showCompletedLeadBottomSheet(notification);
        return;
      }
      
      // If lead is accepted (agent accepted the lead), navigate directly to lead detail
      if ((type.contains('accept') || type.contains('accepted')) && leadId != null && leadId.isNotEmpty) {
        if (kDebugMode) {
          print('   Navigating to lead detail with leadId: $leadId');
        }
        // Navigate directly to lead detail - controller will fetch the lead
        Get.toNamed('/lead-detail', arguments: {'leadId': leadId});
      } 
      // If proposal is accepted, navigate to proposals screen with proposal ID
      else if ((type.contains('accept') || type.contains('accepted')) && proposalId != null && proposalId.isNotEmpty) {
        if (kDebugMode) {
          print('   Navigating to proposals with proposalId: $proposalId');
        }
        Get.toNamed('/proposals', arguments: {'proposalId': proposalId});
      }
      // Otherwise, just navigate to proposals screen
      else {
        if (kDebugMode) {
          print('   Navigating to proposals (no ID found)');
        }
        Get.toNamed('/proposals');
      }
      return;
    }
    
    // Handle other notification types here if needed
  }

  /// Show bottom sheet for completed lead with Review and Report options
  void _showCompletedLeadBottomSheet(NotificationModel notification) {
    final agentData = notification.agentData;
    final leadId = notification.leadId;
    
    if (kDebugMode) {
      print('📋 Showing completed lead bottom sheet');
      print('   Lead ID: ${leadId?.id}');
      print('   Lead Name: ${leadId?.fullName}');
      print('   Agent ID: ${agentData?.id}');
      print('   Agent Name: ${agentData?.fullname}');
      print('   Agent Email: ${agentData?.email}');
    }

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
            
            // Header with gradient background
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100.withOpacity(0.5),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Success Icon
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.white,
                      size: 32.sp,
                    ),
                  ).animate()
                    .scale(duration: 400.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 300.ms),
                  
                  SizedBox(width: 16.w),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead Completed!',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkGray,
                            letterSpacing: -0.5,
                          ),
                        ).animate(delay: 100.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.2, duration: 400.ms),
                        SizedBox(height: 4.h),
                        Text(
                          'Your lead has been successfully completed',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.mediumGray,
                            height: 1.4,
                          ),
                        ).animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.2, duration: 400.ms),
                      ],
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20.sp,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ).animate(delay: 300.ms)
                    .fadeIn(duration: 300.ms)
                    .scale(duration: 300.ms),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent Info Card (Most Important - Show First)
                    if (agentData != null) ...[
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue.withOpacity(0.08),
                              AppTheme.primaryBlue.withOpacity(0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              blurRadius: 10,
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
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.badge_outlined,
                                    size: 24.sp,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Agent Information',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.darkGray,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Completed by',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppTheme.mediumGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            _buildModernInfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Name',
                              value: agentData.fullname ?? 'N/A',
                            ),
                            if (agentData.email != null && agentData.email!.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              _buildModernInfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: agentData.email!,
                              ),
                            ],
                            if (agentData.phone != null && agentData.phone!.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              _buildModernInfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: agentData.phone!,
                              ),
                            ],
                          ],
                        ),
                      ).animate(delay: 400.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut),
                      
                      SizedBox(height: 20.h),
                    ],
                    
                    // Lead Info Card
                    if (leadId != null) ...[
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppTheme.mediumGray.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mediumGray.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 24.sp,
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Text(
                                  'Lead Information',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            _buildModernInfoRow(
                              icon: Icons.account_circle_outlined,
                              label: 'Name',
                              value: leadId.fullName,
                            ),
                            SizedBox(height: 12.h),
                            _buildModernInfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: leadId.email,
                            ),
                          ],
                        ),
                      ).animate(delay: 500.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut),
                      
                      SizedBox(height: 32.h),
                    ],
                    
                    // Action Buttons
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
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Get.back();
                            if (leadId != null) {
                              Get.toNamed(AppPages.PROPOSALS, arguments: {
                                'leadId': leadId.id,
                                'showReview': true,
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.white,
                                  size: 18.sp,
                                ),
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
                    ).animate(delay: 600.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                      .scale(delay: 600.ms + 200.ms, duration: 300.ms, begin: const Offset(0.95, 0.95)),
                    
                    SizedBox(height: 16.h),
                    
                    // Report Issue Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.red.shade400,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Get.back();
                            if (leadId != null) {
                              Get.toNamed(AppPages.PROPOSALS, arguments: {
                                'leadId': leadId.id,
                                'showReport': true,
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  color: Colors.red.shade600,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Report an Issue',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: 700.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                      .scale(delay: 700.ms + 200.ms, duration: 300.ms, begin: const Offset(0.95, 0.95)),
                    
                    SizedBox(height: 16.h),
                    
                    // View Details Button
                    Container(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                          if (leadId != null) {
                            Get.toNamed(AppPages.LEAD_DETAIL, arguments: {'leadId': leadId.id});
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16.sp,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'View Lead Details',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 800.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, duration: 400.ms),
                    
                    SizedBox(height: 8.h), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      )
        .animate()
        .slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms),
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.5),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.mediumGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: AppTheme.primaryBlue,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mediumGray,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGray,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void onClose() {
    _notificationService.dispose();
    super.onClose();
  }
}

