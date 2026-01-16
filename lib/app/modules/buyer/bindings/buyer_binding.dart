import 'package:get/get.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';

class BuyerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerController>(() => BuyerController());
  }
}
