import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/storage_keys.dart';
import 'package:getrebate/app/widgets/guest_auth_dialog.dart';

/// Reusable guard for actions that require a signed-in account.
class GuestAuthGuard {
  GuestAuthGuard._();

  static final _storage = GetStorage();

  /// True when the user has a real account (not browsing as guest).
  static bool get hasAccount {
    if (!Get.isRegistered<AuthController>()) return false;
    return Get.find<AuthController>().hasAccount;
  }

  /// Blocks [action] when the user is a guest or unsigned.
  /// Returns `true` if the action may proceed.
  static bool requireAuth({
    String? featureDescription,
    void Function()? onAuthenticated,
  }) {
    if (hasAccount) {
      onAuthenticated?.call();
      return true;
    }
    GuestAuthDialog.show(featureDescription: featureDescription);
    return false;
  }

  /// Marks that post-login navigation should keep the current screen.
  static void markPreserveRouteOnNextAuth() {
    _storage.write(kGuestAuthPreserveRouteKey, true);
  }

  static bool consumePreserveRouteFlag() {
    final preserve = _storage.read(kGuestAuthPreserveRouteKey) == true;
    if (preserve) {
      _storage.remove(kGuestAuthPreserveRouteKey);
    }
    return preserve;
  }

  static void navigateToLogin() {
    markPreserveRouteOnNextAuth();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    Get.toNamed(
      AppPages.AUTH,
      arguments: const {'mode': 'login'},
    );
  }

  static void navigateToSignUp() {
    markPreserveRouteOnNextAuth();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    Get.toNamed(
      AppPages.AUTH,
      arguments: const {'mode': 'signup'},
    );
  }
}
