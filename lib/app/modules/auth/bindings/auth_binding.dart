import 'package:get/get.dart';
import 'package:getrebate/app/modules/auth/bindings/auth_view_binding.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    AuthViewBinding.ensureRegistered();
  }
}
