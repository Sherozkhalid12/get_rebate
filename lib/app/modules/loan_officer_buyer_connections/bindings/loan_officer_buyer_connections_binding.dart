import 'package:get/get.dart';
import 'package:getrebate/app/modules/loan_officer_buyer_connections/controllers/loan_officer_buyer_connections_controller.dart';

class LoanOfficerBuyerConnectionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanOfficerBuyerConnectionsController>(
      () => LoanOfficerBuyerConnectionsController(),
    );
  }
}


