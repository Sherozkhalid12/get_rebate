import 'package:get/get.dart';
import 'package:getrebate/app/modules/auth/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthViewController>(() => AuthViewController());
  }
}
