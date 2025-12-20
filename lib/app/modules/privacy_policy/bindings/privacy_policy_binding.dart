import 'package:get/get.dart';
import 'package:getrebate/app/modules/privacy_policy/controllers/privacy_policy_controller.dart';

class PrivacyPolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyPolicyController>(() => PrivacyPolicyController());
  }
}


