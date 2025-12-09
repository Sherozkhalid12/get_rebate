import 'package:get/get.dart';
import 'package:getrebate/app/modules/seller_lead_form/controllers/seller_lead_form_controller.dart';

class SellerLeadFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerLeadFormController>(() => SellerLeadFormController());
  }
}
