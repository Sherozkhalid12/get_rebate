import 'package:get/get.dart';
import 'package:getrebate/app/modules/edit_listing/controllers/edit_listing_controller.dart';

class EditListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditListingController>(() => EditListingController());
  }
}
