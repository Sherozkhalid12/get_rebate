import 'package:get/get.dart';
import 'package:getrebate/app/modules/notifications/controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    // Make it permanent so it persists across pages and updates globally
    Get.put<NotificationsController>(NotificationsController(), permanent: true);
  }
}

