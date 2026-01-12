import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/notifications/controllers/notifications_controller.dart';

class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    // Get or create notifications controller - make it permanent so it persists
    NotificationsController? controller;
    try {
      controller = Get.find<NotificationsController>();
    } catch (e) {
      controller = Get.put(NotificationsController(), permanent: true);
    }

    return Obx(() {
      final unreadCount = controller?.unreadCount ?? 0;

      return GestureDetector(
        onTap: () {
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

