import 'package:get/get.dart';
import 'package:getrebate/app/modules/create_listing/controllers/create_listing_controller.dart';

class CreateListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateListingController>(() => CreateListingController());
  }
}
