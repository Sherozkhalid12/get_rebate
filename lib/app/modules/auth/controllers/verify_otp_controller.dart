import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/controllers/auth_controller.dart' as global;
import 'package:getrebate/app/controllers/auth_controller.dart' show EmailAlreadyExistsException;
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/modules/auth/services/pending_signup_store.dart';
import 'package:getrebate/app/modules/auth/controllers/auth_controller.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

import '../../../utils/connectivity_helper.dart';

class VerifyOtpController extends GetxController {
  global.AuthController get _authController => Get.find<global.AuthController>();

  final otpController = TextEditingController();

  final _isLoading = false.obs;
  final _isResending = false.obs;
  final _resendCountdown = 0.obs;
  Timer? _resendTimer;

  bool get isLoading => _isLoading.value;
  bool get isResending => _isResending.value;
  int get resendCountdown => _resendCountdown.value;
  bool get canResend => _resendCountdown.value <= 0;

  String email = '';
  PendingSignUpData? payload;
  final _isReady = false.obs;
  bool get isReady => _isReady.value;

  static const int _resendCooldownSeconds = 60;

  @override
  void onInit() {
    super.onInit();
    payload = PendingSignUpStore.instance.take();
    if (payload != null) {
      email = payload!.email;
    } else {
      final args = Get.arguments;
      if (args is Map && args['email'] != null) {
        email = (args['email'] as String).trim();
      }
    }
    if (kDebugMode) {
      print('🔐 VerifyOtpController.onInit: email=$email, hasPayload=${payload != null}');
    }
    if (email.isEmpty || payload == null) {
      if (kDebugMode) print('❌ VerifyOtpController: Invalid args or no payload, going back');
      Future.microtask(() => Get.back());
      return;
    }
    _startResendCountdown();
    _isReady.value = true;
    if (kDebugMode) print('✅ VerifyOtpController: Ready, countdown started');
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

  Future<void> verifyOtp() async {
    if (payload == null) {
      if (kDebugMode) print('❌ verifyOtp: payload is null');
      return;
    }
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      SnackbarHelper.showError('Please enter the verification code');
      return;
    }
    if (otp.length < 4) {
      SnackbarHelper.showError('Please enter a valid 6-digit code');
      return;
    }

    try {
      await ConnectivityHelper.ensureConnectivity();
    } catch (e) {
      SnackbarHelper.showError(ConnectivityHelper.noInternetMessage);
      return;
    }

    if (kDebugMode) print('🔐 verifyOtp: Calling API for email=$email');
    try {
      _isLoading.value = true;
      await _authController.verifyOtp(email, otp);
      if (kDebugMode) print('✅ verifyOtp: Success, completing signup');
      SnackbarHelper.showSuccess('Email verified! Completing registration...');
      await _completeSignUp();
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ verifyOtp exception: $e');
        print('   Stack: $stack');
      }
      SnackbarHelper.showError(e.toString());
      // Do not navigate - stay on verify screen so user can retry
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _completeSignUp() async {
    final p = payload;
    if (p == null) return;

    try {
      await ConnectivityHelper.ensureConnectivity();
    } catch (e) {
      SnackbarHelper.showError(ConnectivityHelper.noInternetMessage);
      return;
    }

    if (kDebugMode) print('📝 _completeSignUp: Calling signUp API');
    try {
      _isLoading.value = true;
      await _authController.signUp(
        email: p.email,
        password: p.password,
        name: p.name,
        role: p.role,
        phone: p.phone,
        licensedStates: p.licensedStates,
        additionalData: p.additionalData,
        profilePic: p.profilePic,
        companyLogo: p.companyLogo,
        video: p.video,
        skipNavigation: true,
      );
      // Only navigate after signUp succeeds - never navigate on exception (no internet, etc.)
      switch (p.role) {
        case UserRole.agent:
          Get.offAllNamed(AppPages.AGENT);
          break;
        case UserRole.loanOfficer:
          Get.offAllNamed(AppPages.LOAN_OFFICER);
          break;
        case UserRole.buyerSeller:
        default:
          Get.offAllNamed(AppPages.MAIN);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ _completeSignUp exception: $e');
        print('   Exception type: ${e.runtimeType}');
      }
      
      // Check if error indicates email already exists
      String errorMessage = e.toString();
      bool isEmailExists = false;
      
      // First check: Is it the custom EmailAlreadyExistsException?
      if (e is EmailAlreadyExistsException) {
        isEmailExists = true;
        errorMessage = e.message;
        if (kDebugMode) {
          print('✅ Caught EmailAlreadyExistsException in signup: $errorMessage');
        }
      } else if (errorMessage.contains('EmailAlreadyExistsException')) {
        isEmailExists = true;
        if (errorMessage.contains('EmailAlreadyExistsException: ')) {
          errorMessage = errorMessage.split('EmailAlreadyExistsException: ').last.trim();
        }
      } else if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 400 || statusCode == 409) {
          isEmailExists = true;
        }
        
        if (responseData is Map) {
          final msg = responseData['message']?.toString().toLowerCase() ?? '';
          if (msg.contains('already exists') ||
              msg.contains('email already') ||
              msg.contains('user already') ||
              msg.contains('account already') ||
              msg.contains('user with this email')) {
            isEmailExists = true;
            errorMessage = responseData['message']?.toString() ?? errorMessage;
          }
        }
      } else {
        final lowerError = errorMessage.toLowerCase();
        if (lowerError.contains('already exists') ||
            lowerError.contains('email already') ||
            lowerError.contains('user already') ||
            lowerError.contains('account already') ||
            lowerError.contains('an account with this email') ||
            lowerError.contains('user with this email')) {
          isEmailExists = true;
        }
      }
      
      if (isEmailExists) {
        if (kDebugMode) {
          print('🚫 Email already exists during signup - navigating back and showing dialog');
        }
        // Navigate back to signup and show dialog
        // Use Get.back() to go back to auth screen
        Get.back();
        // Wait a bit for navigation to complete, then show dialog
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            final authViewController = Get.find<AuthViewController>();
            authViewController.showAccountExistsDialog(p.email);
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not find AuthViewController, showing snackbar instead');
            }
            SnackbarHelper.showError(
              'An account with this email already exists. Please sign in instead.',
            );
          }
        });
      } else {
        SnackbarHelper.showError(errorMessage);
      }
      // DO NOT navigate - prevent entry into app if email exists
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend || _isResending.value) return;

    if (kDebugMode) print('📧 resendOtp: Calling API for email=$email');
    try {
      _isResending.value = true;
      await _authController.resendVerificationEmail(email);
      if (kDebugMode) print('✅ resendOtp: Success, countdown restarted');
      SnackbarHelper.showSuccess('Verification code sent! Check your email.');
      _startResendCountdown();
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ resendOtp exception: $e');
        print('   Stack: $stack');
      }
      SnackbarHelper.showError(e.toString());
    } finally {
      _isResending.value = false;
    }
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}
