import 'package:get/get.dart';
import 'package:getrebate/app/modules/buyer_lead_form/controllers/buyer_lead_form_controller.dart';

class BuyerLeadFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerLeadFormController>(() => BuyerLeadFormController());
  }
}
