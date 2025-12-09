import 'package:get/get.dart';
import 'package:getrebate/app/modules/rebate_checklist/controllers/rebate_checklist_controller.dart';

class RebateChecklistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RebateChecklistController>(() => RebateChecklistController());
  }
}

