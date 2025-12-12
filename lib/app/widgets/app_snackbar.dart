import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class AppSnackbar {
  /// Show a validation/info snackbar with app theme blue color
  static void showValidation(String message) {
    if (kDebugMode) {
      print('📢 Showing validation snackbar: $message');
    }
    
    try {
      // Try direct call first
      Get.snackbar(
        'Missing Information',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primaryBlue,
        colorText: AppTheme.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
        icon: const Icon(
          Icons.info_outline,
          color: AppTheme.white,
          size: 24,
        ),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
        animationDuration: const Duration(milliseconds: 300),
        snackStyle: SnackStyle.FLOATING,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing validation snackbar: $e');
      }
      // Fallback: try with postFrameCallback
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          Get.snackbar(
            'Missing Information',
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.primaryBlue,
            colorText: AppTheme.white,
            margin: const EdgeInsets.all(16),
          );
        } catch (e2) {
          if (kDebugMode) {
            print('❌ Fallback snackbar also failed: $e2');
          }
        }
      });
    }
  }

  /// Show a success snackbar with app theme green color
  static void showSuccess(String title, String message) {
    if (kDebugMode) {
      print('📢 Showing success snackbar: $title - $message');
    }
    
    try {
      // Try direct call first
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.lightGreen,
        colorText: AppTheme.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(
          Icons.check_circle,
          color: AppTheme.white,
          size: 24,
        ),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
        animationDuration: const Duration(milliseconds: 300),
        snackStyle: SnackStyle.FLOATING,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing success snackbar: $e');
      }
      // Fallback: try with postFrameCallback
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          Get.snackbar(
            title,
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.lightGreen,
            colorText: AppTheme.white,
            margin: const EdgeInsets.all(16),
          );
        } catch (e2) {
          if (kDebugMode) {
            print('❌ Fallback snackbar also failed: $e2');
          }
        }
      });
    }
  }

  /// Show an error snackbar with red color
  static void showError(String message) {
    if (kDebugMode) {
      print('📢 Showing error snackbar: $message');
    }
    
    try {
      // Try direct call first
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: AppTheme.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(
          Icons.error_outline,
          color: AppTheme.white,
          size: 24,
        ),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
        animationDuration: const Duration(milliseconds: 300),
        snackStyle: SnackStyle.FLOATING,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing error snackbar: $e');
      }
      // Fallback: try with postFrameCallback
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          Get.snackbar(
            'Error',
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade600,
            colorText: AppTheme.white,
            margin: const EdgeInsets.all(16),
          );
        } catch (e2) {
          if (kDebugMode) {
            print('❌ Fallback snackbar also failed: $e2');
          }
        }
      });
    }
  }
}

