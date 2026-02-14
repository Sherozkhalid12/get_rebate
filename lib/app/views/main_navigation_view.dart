import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppTheme.primaryBlue, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Leave app?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to leave the app? Your progress may not be saved.',
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.5,
            color: AppTheme.mediumGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Stay',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGray,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Leave app', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // If we're not on the home screen (index 0), go back to home
          if (controller.currentIndex != 0) {
            controller.changeIndex(0);
            // Ensure navbar is visible when going back to home
            controller.showNavBar();
          } else {
            // If we're on home screen, show exit confirmation dialog
            _showExitConfirmationDialog(context);
          }
        }
      },
      child: Scaffold(
        body: Obx(
          () {
            final currentIndex = controller.currentIndex.clamp(0, controller.pages.length - 1);
            if (kDebugMode && currentIndex != controller.currentIndex) {
              print('⚠️ Clamped index from ${controller.currentIndex} to $currentIndex');
            }
            return IndexedStack(
              index: currentIndex,
              children: controller.pages,
            );
          },
        ),
        bottomNavigationBar: Obx(
          () => controller.isNavBarVisible
              ? controller.buildBottomNavigationBar()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
