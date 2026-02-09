import 'package:get/get.dart';
import 'package:getrebate/app/modules/about_legal/controllers/about_legal_controller.dart';

class AboutLegalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AboutLegalController>(() => AboutLegalController());
  }
}
