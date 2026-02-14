import 'package:get/get.dart';
import 'package:getrebate/app/modules/agent_checklist/controllers/agent_checklist_controller.dart';

class AgentChecklistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgentChecklistController>(() => AgentChecklistController());
  }
}
