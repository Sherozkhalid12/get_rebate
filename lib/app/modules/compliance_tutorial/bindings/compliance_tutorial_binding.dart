import 'package:get/get.dart';
import 'package:getrebate/app/modules/compliance_tutorial/controllers/compliance_tutorial_controller.dart';

class ComplianceTutorialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ComplianceTutorialController>(() => ComplianceTutorialController());
  }
}

