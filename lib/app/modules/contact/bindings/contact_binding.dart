import 'package:get/get.dart';
import 'package:getrebate/app/modules/contact/controllers/contact_controller.dart';

class ContactBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map<String, dynamic>?;
    Get.lazyPut<ContactController>(
      () => ContactController(
        userId: args?['userId'] ?? '',
        userName: args?['userName'] ?? 'User',
        userProfilePic: args?['userProfilePic'],
        userRole: args?['userRole'] ?? 'user',
      ),
    );
  }
}

