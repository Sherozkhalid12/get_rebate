import 'package:get/get.dart';
import 'package:getrebate/app/modules/loan_officer_edit_profile/controllers/loan_officer_edit_profile_controller.dart';

import '../views/loan_officer_edit_profile_view.dart';

class LoanOfficerEditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanOfficerEditProfileController>(
          () => LoanOfficerEditProfileController(),
    );
  }
}



