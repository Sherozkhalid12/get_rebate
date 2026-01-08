import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:getrebate/app/models/notification_model.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.darkGray,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.darkGray,
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading && controller.notifications.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryBlue,
            ),
          );
        }

        if (controller.error != null && controller.notifications.isEmpty) {
          return _buildErrorState(context);
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            // Header with unread count and mark all read button
            _buildHeader(context),
            
            // Notifications list
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppTheme.primaryBlue,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: controller.notifications.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return _buildNotificationCard(
                      context,
                      notification,
                      isUnread: !notification.isRead,
                      index: index,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            final unreadCount = controller.unreadCount;
            if (unreadCount > 0) {
              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount unread',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.mediumGray,
              ),
            );
          }),
          Obx(() {
            if (controller.unreadCount > 0) {
              return TextButton.icon(
                onPressed: controller.markAllAsRead,
                icon: Icon(
                  Icons.done_all_rounded,
                  size: 18.sp,
                  color: AppTheme.primaryBlue,
                ),
                label: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification, {
    required bool isUnread,
    required int index,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Mark as read immediately for visual feedback
          if (isUnread) {
            controller.markAsRead(notification.id); // Fire and forget for instant UI update
          }
          // Then handle navigation
          await controller.handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread ? Colors.white : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: isUnread
                ? Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    width: 1.5,
                  )
                : Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread indicator dot
                if (isUnread)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    margin: EdgeInsets.only(right: 12.w, top: 6.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  SizedBox(width: 4.w),
                
                // Icon container
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? _getNotificationColor(notification.type)
                            .withOpacity(0.12)
                        : _getNotificationColor(notification.type)
                            .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with timestamp
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isUnread
                                    ? AppTheme.darkGray
                                    : AppTheme.darkGray.withOpacity(0.7),
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 6.h),
                      
                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isUnread
                              ? AppTheme.darkGray.withOpacity(0.8)
                              : AppTheme.mediumGray,
                          height: 1.4,
                          fontWeight: isUnread
                              ? FontWeight.w400
                              : FontWeight.w300,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Lead info if available
                      if (notification.leadId != null) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14.sp,
                                color: AppTheme.mediumGray,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  notification.leadId!.fullName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.darkGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: (index * 30).ms,
          curve: Curves.easeOut,
        )
        .slideX(
          begin: 0.1,
          duration: 300.ms,
          delay: (index * 30).ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 56.sp,
                color: AppTheme.primaryBlue.withOpacity(0.6),
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            SizedBox(height: 24.h),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),
            SizedBox(height: 8.h),
            Text(
              'You\'re all caught up!\nNew notifications will appear here.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.2, duration: 400.ms, delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48.sp,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Error loading notifications',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.error ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.refresh,
              icon: Icon(Icons.refresh_rounded, size: 18.sp),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
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

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'lead':
        return Icons.person_add_rounded;
      case 'lead_response':
        return Icons.check_circle_rounded;
      case 'lead_completed':
        return Icons.done_all_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'lead':
        return AppTheme.primaryBlue;
      case 'lead_response':
        return AppTheme.lightGreen;
      case 'lead_completed':
        return Colors.orange;
      default:
        return AppTheme.mediumGray;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
