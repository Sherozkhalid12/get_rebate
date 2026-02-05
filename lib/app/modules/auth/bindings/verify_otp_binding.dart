import 'package:get/get.dart';
import 'package:getrebate/app/modules/auth/controllers/verify_otp_controller.dart';

class VerifyOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyOtpController>(
      () => VerifyOtpController(),
      fenix: true,
    );
  }
}
