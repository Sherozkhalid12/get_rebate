import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Utility class for handling network errors consistently across the app
class NetworkErrorHandler {
  const NetworkErrorHandler._();

  /// Handles network errors and displays appropriate error messages
  /// 
  /// [error] - The error object (can be DioException, Exception, or any other error)
  /// [defaultMessage] - Default message to show if error cannot be parsed
  static void handleError(
    dynamic error, {
    String? defaultMessage,
  }) {
    String errorMessage = defaultMessage ?? 'An unexpected error occurred. Please try again.';

    if (error is DioException) {
      errorMessage = _handleDioError(error, defaultMessage);
    } else if (error is Exception) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } else if (error != null) {
      errorMessage = error.toString();
    }

    if (kDebugMode) {
      print('❌ Network Error: $errorMessage');
      print('   Original error: $error');
    }

    Get.snackbar(
      'Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// Handles DioException and extracts appropriate error message
  static String _handleDioError(DioException error, String? defaultMessage) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final responseData = error.response!.data;

      // Try to extract message from response
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString() ?? 
                       responseData['error']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      } else if (responseData is String && responseData.isNotEmpty) {
        return responseData;
      }

      // Fallback to status code messages
      switch (statusCode) {
        case 400:
          return 'Invalid request. Please check your input and try again.';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access forbidden. You do not have permission to perform this action.';
        case 404:
          return 'Resource not found. Please try again.';
        case 500:
          return 'Server error. Please try again later.';
        case 502:
        case 503:
        case 504:
          return 'Service temporarily unavailable. Please try again later.';
        default:
          return defaultMessage ?? 'Request failed with status code $statusCode.';
      }
    }

    // Handle connection errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try again.';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return defaultMessage ?? 'Invalid response from server. Please try again.';
      case DioExceptionType.unknown:
        if (error.message != null && error.message!.isNotEmpty) {
          return error.message!;
        }
        return defaultMessage ?? 'Network error. Please try again.';
    }
  }
}



