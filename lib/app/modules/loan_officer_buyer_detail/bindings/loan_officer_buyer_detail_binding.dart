import 'package:get/get.dart';
import 'package:getrebate/app/modules/loan_officer_buyer_detail/controllers/loan_officer_buyer_detail_controller.dart';

class LoanOfficerBuyerDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanOfficerBuyerDetailController>(
      () => LoanOfficerBuyerDetailController(),
    );
  }
}


