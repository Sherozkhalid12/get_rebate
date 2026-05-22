import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/modules/auth/bindings/auth_view_binding.dart';
import 'package:getrebate/app/modules/auth/controllers/auth_controller.dart';

class CompleteProfileBinding extends Bindings {
  @override
  void dependencies() {
    AuthViewBinding.ensureRegistered();
    // initCompleteProfileMode updates Obx values — must not run during route build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<AuthViewController>()) return;
      Get.find<AuthViewController>().initCompleteProfileMode();
    });
  }
}
