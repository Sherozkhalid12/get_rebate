import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/controllers/theme_controller.dart';
import 'package:getrebate/app/modules/splash/controllers/splash_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ThemeController>(ThemeController());
    Get.put<LocationController>(LocationController());
    Get.put<AuthController>(AuthController());
    Get.put<SplashController>(SplashController());
  }
}
