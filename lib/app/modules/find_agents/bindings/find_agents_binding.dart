import 'package:get/get.dart';
import 'package:getrebate/app/modules/find_agents/controllers/find_agents_controller.dart';

class FindAgentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FindAgentsController>(() => FindAgentsController());
  }
}

