import 'package:get/get.dart';
import 'package:getrebate/app/modules/property_detail/controllers/property_detail_controller.dart';

class PropertyDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyDetailController>(() => PropertyDetailController());
  }
}
