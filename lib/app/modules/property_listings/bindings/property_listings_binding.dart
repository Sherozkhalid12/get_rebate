import 'package:get/get.dart';
import 'package:getrebate/app/modules/property_listings/controllers/property_listings_controller.dart';

class PropertyListingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyListingsController>(() => PropertyListingsController());
  }
}
