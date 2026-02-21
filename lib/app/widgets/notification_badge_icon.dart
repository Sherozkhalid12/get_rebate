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
        child: SizedBox(
          width: 24.w,
          height: 24.h,
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
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4757).withOpacity(0.4),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 220.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 180.ms),
                ),
            ],
          ),
        ),
      );
    });
  }
}

