import 'package:get/get.dart';
import 'package:getrebate/app/modules/checklist/controllers/checklist_controller.dart';

class ChecklistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChecklistController>(() => ChecklistController());
  }
}

