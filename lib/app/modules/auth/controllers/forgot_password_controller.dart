import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/utils/connectivity_helper.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class ForgotPasswordController extends GetxController {
  global.AuthController get _authController => Get.find<global.AuthController>();

  final emailController = TextEditingController();

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onClose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        emailController.dispose();
      } catch (_) {}
    });
    super.onClose();
  }

  Future<void> sendResetCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      SnackbarHelper.showError('Please enter your email');
      return;
    }
    if (!GetUtils.isEmail(email)) {
      SnackbarHelper.showError('Please enter a valid email');
      return;
    }

    try {
      await ConnectivityHelper.ensureConnectivity();
    } catch (e) {
      SnackbarHelper.showError(ConnectivityHelper.noInternetMessage);
      return;
    }

    try {
      _isLoading.value = true;
      await _authController.sendForgotPasswordOtp(email);
      SnackbarHelper.showSuccess('Reset code sent! Check your email.');
      Get.offNamed(AppPages.RESET_PASSWORD, arguments: {'email': email});
    } catch (e) {
      if (kDebugMode) print('❌ sendForgotPasswordOtp: $e');
      SnackbarHelper.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isLoading.value = false;
    }
  }
}
