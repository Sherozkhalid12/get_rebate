import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
          'Notifications',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.unreadCount > 0) {
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: TextButton.icon(
                  onPressed: controller.markAllAsRead,
                  icon: Icon(
                    Icons.done_all,
                    size: 18.sp,
                    color: AppTheme.white,
                  ),
                  label: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppTheme.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.notifications.isEmpty) {
          return Center(
            child: SpinKitFadingCircle(
              color: AppTheme.primaryBlue,
              size: 40,
            ),
          );
        }

        if (controller.error != null && controller.notifications.isEmpty) {
          return _buildErrorState(context);
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primaryBlue,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationTile(
                context,
                notification,
                isUnread: !notification.isRead,
                index: index,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification, {
    required bool isUnread,
    required int index,
  }) {
    return InkWell(
      onTap: () async {
        await controller.handleNotificationTap(notification);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isUnread ? 12 : 8,
              offset: const Offset(0, 2),
              spreadRadius: isUnread ? 1 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator bar
              if (isUnread)
                Container(
                  width: 4.w,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              // Icon
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: isUnread
                      ? _getNotificationColor(notification.type)
                          .withOpacity(0.15)
                      : _getNotificationColor(notification.type)
                          .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: isUnread
                      ? Border.all(
                          color: _getNotificationColor(notification.type)
                              .withOpacity(0.3),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 14.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isUnread
                                  ? AppTheme.darkGray
                                  : AppTheme.mediumGray,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isUnread
                            ? AppTheme.darkGray.withOpacity(0.8)
                            : AppTheme.mediumGray,
                        height: 1.5,
                        fontWeight: isUnread ? FontWeight.w400 : FontWeight.normal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.leadId != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16.sp,
                              color: AppTheme.mediumGray,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                notification.leadId!.fullName,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
            curve: Curves.easeOut,
          )
          .slideX(
            begin: 0.2,
            duration: 300.ms,
            delay: (index * 50).ms,
            curve: Curves.easeOut,
          ),
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
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 50.sp,
                color: AppTheme.primaryBlue,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            SizedBox(height: 24.h),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),
            SizedBox(height: 8.h),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.mediumGray,
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
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off,
                size: 50.sp,
                color: Colors.red.shade400,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            SizedBox(height: 24.h),
            Text(
              'Unable to Load Notifications',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),
            SizedBox(height: 12.h),
            Text(
              controller.error ?? 'Please check your internet connection and try again.',
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
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: controller.refresh,
              icon: Icon(Icons.refresh, size: 20.sp),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .scale(duration: 300.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'lead':
        return Icons.person_add;
      case 'lead_response':
        return Icons.check_circle;
      case 'lead_completed':
        return Icons.done_all;
      default:
        return Icons.notifications;
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
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

