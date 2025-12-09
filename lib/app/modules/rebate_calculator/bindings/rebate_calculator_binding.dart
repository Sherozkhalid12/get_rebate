import 'package:get/get.dart';
import 'package:getrebate/app/modules/rebate_calculator/controllers/rebate_calculator_controller.dart';

class RebateCalculatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RebateCalculatorController>(() => RebateCalculatorController());
  }
}
