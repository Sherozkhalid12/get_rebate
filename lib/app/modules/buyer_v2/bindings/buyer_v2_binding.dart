import 'package:get/get.dart';
import 'package:getrebate/app/modules/buyer_v2/controllers/buyer_v2_controller.dart';

class BuyerV2Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerV2Controller>(() => BuyerV2Controller());
  }
}
