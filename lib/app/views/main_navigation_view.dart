import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex,
          children: controller.pages,
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isNavBarVisible
            ? controller.buildBottomNavigationBar()
            : const SizedBox.shrink(),
      ),
    );
  }
}
