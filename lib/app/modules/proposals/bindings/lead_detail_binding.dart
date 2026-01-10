import 'package:get/get.dart';
import 'package:getrebate/app/modules/proposals/controllers/lead_detail_controller.dart';

class LeadDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeadDetailController>(() => LeadDetailController());
  }
}
