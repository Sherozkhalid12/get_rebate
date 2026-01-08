import 'package:get/get.dart';
import 'package:getrebate/app/modules/proposals/controllers/proposal_controller.dart';

class ProposalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProposalController>(() => ProposalController());
  }
}



