import 'package:get/get.dart';
import 'package:getrebate/app/modules/loan_officer_profile/controllers/loan_officer_profile_controller.dart';

class LoanOfficerProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanOfficerProfileController>(
      () => LoanOfficerProfileController(),
    );
  }
}
