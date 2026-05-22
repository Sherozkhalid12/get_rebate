import 'package:get/get.dart';
import 'package:getrebate/app/modules/auth/controllers/auth_controller.dart';

/// Registers [AuthViewController] for auth + complete-profile flows.
/// Permanent so it survives `offAll` navigation (non-permanent Put gets disposed).
class AuthViewBinding {
  static void ensureRegistered() {
    if (!Get.isRegistered<AuthViewController>()) {
      Get.put(AuthViewController(), permanent: true);
    }
  }

  static void disposeIfRegistered() {
    if (Get.isRegistered<AuthViewController>()) {
      Get.delete<AuthViewController>(force: true);
    }
  }
}
