import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/notifications/controllers/notifications_controller.dart';

class NotificationBadgeIcon extends StatefulWidget {
  const NotificationBadgeIcon({super.key});

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  late final NotificationsController _controller;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<NotificationsController>();
    } catch (e) {
      _controller = Get.put(NotificationsController(), permanent: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount = _controller.unreadCount;

      return GestureDetector(
        onTap: () {
          _controller.fetchNotifications();
          Get.toNamed('/notifications');
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: AppTheme.white,
              size: 24.sp,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Builder(
                  builder: (context) {
                    final badge = Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: unreadCount > 9 ? 5.w : 6.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        minHeight: 20.h,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );

                    return badge
                        .animate()
                        .scale(
                          duration: 200.ms,
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .shake(
                          duration: 300.ms,
                          hz: 4,
                        );
                  },
                ),
              ),
          ],
        )
            .animate()
            .scale(
              duration: 200.ms,
              curve: Curves.easeOut,
            ),
      );
    });
  }
}

