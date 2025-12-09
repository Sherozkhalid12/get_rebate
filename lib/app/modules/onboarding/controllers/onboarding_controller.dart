import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/routes/app_pages.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final _currentPage = 0.obs;

  int get currentPage => _currentPage.value;

  void nextPage() {
    if (_currentPage.value < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.toNamed(AppPages.AUTH);
    }
  }

  void previousPage() {
    if (_currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int index) {
    _currentPage.value = index;
  }

  void skipOnboarding() {
    Get.toNamed(AppPages.AUTH);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
