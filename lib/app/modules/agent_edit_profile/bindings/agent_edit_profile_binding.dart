import 'package:get/get.dart';
import '../controllers/agent_edit_profile_controller.dart';

class AgentEditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgentEditProfileController>(() => AgentEditProfileController());
  }
}
