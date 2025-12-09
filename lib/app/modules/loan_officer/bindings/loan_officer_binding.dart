import 'package:get/get.dart';
import 'package:getrebate/app/modules/loan_officer/controllers/loan_officer_controller.dart';
import 'package:getrebate/app/modules/checklist/controllers/checklist_controller.dart';
import 'package:getrebate/app/modules/rebate_checklist/controllers/rebate_checklist_controller.dart';

class LoanOfficerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanOfficerController>(() => LoanOfficerController());
    Get.lazyPut<ChecklistController>(() => ChecklistController());
    Get.lazyPut<RebateChecklistController>(() => RebateChecklistController());
  }
}
