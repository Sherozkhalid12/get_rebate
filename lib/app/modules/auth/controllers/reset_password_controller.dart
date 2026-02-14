import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/connectivity_helper.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class ResetPasswordController extends GetxController {
  global.AuthController get _authController => Get.find<global.AuthController>();

  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _isLoading = false.obs;
  final _obscurePassword = true.obs;
  final _obscureConfirm = true.obs;
  final _isResending = false.obs;
  final _resendCountdown = 0.obs;
  Timer? _resendTimer;

  bool get isLoading => _isLoading.value;
  bool get obscurePassword => _obscurePassword.value;
  bool get obscureConfirm => _obscureConfirm.value;
  bool get isResending => _isResending.value;
  int get resendCountdown => _resendCountdown.value;
  bool get canResend => _resendCountdown.value <= 0;

  String email = '';

  static const int _resendCooldownSeconds = 60;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      email = (args['email'] as String).trim();
    }
    if (email.isEmpty) {
      if (kDebugMode) print('❌ ResetPasswordController: No email, going back');
      Future.microtask(() => Get.back());
      return;
    }
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendCountdown.value = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCountdown.value > 0) {
        _resendCountdown.value--;
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  void togglePasswordVisibility() => _obscurePassword.value = !_obscurePassword.value;
  void toggleConfirmVisibility() => _obscureConfirm.value = !_obscureConfirm.value;

  /// Unfocus text fields, dismiss keyboard, then navigate to avoid RenderObject 'attached' assertion
  void _unfocusAndNavigateToAuth() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Get.offAllNamed(AppPages.AUTH);
      });
    });
  }

  Future<void> resendCode() async {
    if (!canResend || _isResending.value) return;

    try {
      await ConnectivityHelper.ensureConnectivity();
    } catch (e) {
      SnackbarHelper.showError(ConnectivityHelper.noInternetMessage);
      return;
    }

    try {
      _isResending.value = true;
      await _authController.sendForgotPasswordOtp(email);
      SnackbarHelper.showSuccess('Reset code sent! Check your email.');
      _startResendCountdown();
    } catch (e) {
      if (kDebugMode) print('❌ resendForgotPasswordOtp: $e');
      SnackbarHelper.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isResending.value = false;
    }
  }

  Future<void> resetPassword() async {
    final otp = otpController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (otp.isEmpty) {
      SnackbarHelper.showError('Please enter the verification code');
      return;
    }
    if (otp.length < 4) {
      SnackbarHelper.showError('Please enter a valid 6-digit code');
      return;
    }
    if (password.isEmpty) {
      SnackbarHelper.showError('Please enter your new password');
      return;
    }
    if (password.length < 6) {
      SnackbarHelper.showError('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      SnackbarHelper.showError('Passwords do not match');
      return;
    }

    try {
      await ConnectivityHelper.ensureConnectivity();
    } catch (e) {
      SnackbarHelper.showError(ConnectivityHelper.noInternetMessage);
      return;
    }

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      _isLoading.value = true;
      // Step 1: Verify OTP
      await _authController.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );
      // Step 2: Reset password
      await _authController.resetPassword(
        email: email,
        newPassword: password,
      );
      SnackbarHelper.showSuccess('Password reset successfully! Please sign in.');
      _unfocusAndNavigateToAuth();
    } catch (e) {
      if (kDebugMode) print('❌ resetPassword: $e');
      SnackbarHelper.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        otpController.dispose();
        passwordController.dispose();
        confirmPasswordController.dispose();
      } catch (_) {}
    });
    super.onClose();
  }
}
