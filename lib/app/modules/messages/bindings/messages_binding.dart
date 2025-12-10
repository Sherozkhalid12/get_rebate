import 'package:get/get.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';

class MessagesBinding extends Bindings {
  @override
  void dependencies() {
    // Use put instead of lazyPut so controller is available immediately if preloaded
    if (!Get.isRegistered<MessagesController>()) {
      Get.put<MessagesController>(MessagesController(), permanent: true);
    }
  }
}
