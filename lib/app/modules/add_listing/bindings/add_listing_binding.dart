import 'package:get/get.dart';
import '../controllers/add_listing_controller.dart';

class AddListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddListingController>(() => AddListingController());
  }
}

