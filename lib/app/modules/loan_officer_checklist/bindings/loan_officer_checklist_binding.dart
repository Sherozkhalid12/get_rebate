import 'package:get/get.dart';
import 'package:getrebate/app/modules/loan_officer_checklist/controllers/loan_officer_checklist_controller.dart';

class LoanOfficerChecklistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanOfficerChecklistController>(
      () => LoanOfficerChecklistController(),
    );
  }
}
