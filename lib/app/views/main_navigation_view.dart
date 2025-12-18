import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // If we're not on the home screen (index 0), go back to home
          if (controller.currentIndex != 0) {
            controller.changeIndex(0);
          } else {
            // If we're on home screen, allow app to exit
            // You can add an exit confirmation dialog here if needed
            Navigator.of(context).pop();
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
