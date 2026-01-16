import 'package:get/get.dart';
import 'package:getrebate/app/modules/buyer_lead_form_v2/controllers/buyer_lead_form_v2_controller.dart';

class BuyerLeadFormV2Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerLeadFormV2Controller>(() => BuyerLeadFormV2Controller());
  }
}
