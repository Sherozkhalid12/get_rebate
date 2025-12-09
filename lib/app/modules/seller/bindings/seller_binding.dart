import 'package:get/get.dart';
import 'package:getrebate/app/modules/seller/controllers/seller_controller.dart';

class SellerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerController>(() => SellerController());
  }
}
