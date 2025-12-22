import 'package:get/get.dart';
import 'package:getrebate/app/modules/terms_of_service/controllers/terms_of_service_controller.dart';

class TermsOfServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TermsOfServiceController>(() => TermsOfServiceController());
  }
}




