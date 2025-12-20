import 'package:get/get.dart';
import 'package:getrebate/app/modules/help_support/controllers/help_support_controller.dart';

class HelpSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpSupportController>(() => HelpSupportController());
  }
}


