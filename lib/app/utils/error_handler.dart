import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

/// Professional error handler for consistent, user-friendly error messages
/// Handles network errors, timeouts, and other exceptions gracefully
class ErrorHandler {
  ErrorHandler._();

  /// Handles any error and shows a professional, user-friendly message
  /// 
  /// [error] - The error object (can be DioException, Exception, or any other error)
  /// [defaultMessage] - Default message to show if error cannot be parsed
  /// [showSnackbar] - Whether to show a snackbar (default: true)
  /// [context] - Optional BuildContext for snackbar
  static String handleError(
    dynamic error, {
    String? defaultMessage,
    bool showSnackbar = true,
  }) {
    String userFriendlyMessage = _getUserFriendlyMessage(error, defaultMessage);

    if (showSnackbar) {
      SnackbarHelper.showError(userFriendlyMessage);
    }

    // Log technical details in debug mode
    if (kDebugMode) {
      print('❌ Error Handler: ${error.runtimeType}');
      print('   Technical: ${error.toString()}');
      print('   User-friendly: $userFriendlyMessage');
    }

    return userFriendlyMessage;
  }

  /// Converts technical errors to user-friendly messages
  static String _getUserFriendlyMessage(dynamic error, String? defaultMessage) {
    // Handle DioException (network errors)
    if (error is DioException) {
      return _handleDioError(error, defaultMessage);
    }

    // Handle Exception
    if (error is Exception) {
      final errorStr = error.toString().toLowerCase();
      
      // Check for common error patterns
      if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        return 'Connection timed out. Please check your internet connection and try again.';
      }
      
      if (errorStr.contains('connection') || errorStr.contains('network')) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }
      
      if (errorStr.contains('failed to load') || errorStr.contains('failed to fetch')) {
        return 'Unable to load data. Please check your connection and try again.';
      }
      
      if (errorStr.contains('socket') || errorStr.contains('host lookup')) {
        return 'Connection issue. Please check your internet connection and try again.';
      }
      
      // Remove "Exception: " prefix for cleaner messages
      String message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      message = message.replaceFirst(RegExp(r'^.*Exception:\s*'), '');
      
      // If message is still technical, use default
      if (message.contains('failed to load') || 
          message.contains('failed to fetch') ||
          message.contains('network error') ||
          message.contains('connection error')) {
        return defaultMessage ?? 'Unable to complete this action. Please try again later.';
      }
      
      return message.isNotEmpty ? message : (defaultMessage ?? 'An error occurred. Please try again.');
    }

    // Handle String errors
    if (error is String) {
      final errorStr = error.toLowerCase();
      
      if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        return 'Connection timed out. Please check your internet connection and try again.';
      }
      
      if (errorStr.contains('connection') || errorStr.contains('network')) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }
      
      if (errorStr.contains('failed to load') || errorStr.contains('failed to fetch')) {
        return 'Unable to load data. Please check your connection and try again.';
      }
      
      // Return the string as-is if it's already user-friendly
      return error;
    }

    // Default fallback
    return defaultMessage ?? 'Something went wrong. Please try again later.';
  }

  /// Handles DioException and extracts appropriate user-friendly error message
  static String _handleDioError(DioException error, String? defaultMessage) {
    // First, try to extract message from response
    if (error.response != null) {
      final responseData = error.response?.data;
      
      if (responseData is Map) {
        final message = responseData['message']?.toString();
        if (message != null && message.isNotEmpty) {
          // Check if it's already user-friendly
          final msgLower = message.toLowerCase();
          if (!msgLower.contains('failed to load') && 
              !msgLower.contains('network error') &&
              !msgLower.contains('connection error')) {
            return message;
          }
        }
      }
    }

    // Handle specific DioException types
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection and try again.';

      case DioExceptionType.connectionError:
        return 'Unable to connect. Please check your internet connection and try again.';

      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please try again later.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        
        // Handle specific HTTP status codes
        switch (statusCode) {
          case 400:
            return 'Invalid request. Please check your input and try again.';
          case 401:
            return 'Session expired. Please sign in again.';
          case 403:
            return 'Access denied. Please check your permissions.';
          case 404:
            return 'Resource not found. Please try again later.';
          case 408:
            return 'Request timed out. Please check your connection and try again.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          case 500:
          case 502:
          case 503:
          case 504:
            return 'Server error. Please try again later.';
          default:
            return defaultMessage ?? 'Unable to complete this action. Please try again.';
        }

      case DioExceptionType.unknown:
        // Check error message for more context
        if (error.message != null) {
          final msg = error.message!.toLowerCase();
          if (msg.contains('timeout') || msg.contains('timed out')) {
            return 'Connection timed out. Please check your internet connection and try again.';
          }
          if (msg.contains('connection') || msg.contains('network')) {
            return 'Unable to connect. Please check your internet connection and try again.';
          }
          if (msg.contains('host lookup') || msg.contains('socket')) {
            return 'Connection issue. Please check your internet connection and try again.';
          }
        }
        return defaultMessage ?? 'Network error. Please check your connection and try again.';
    }
  }

  /// Shows a professional error message for common scenarios
  static void showNetworkError({String? customMessage}) {
    SnackbarHelper.showError(
      customMessage ?? 'Unable to connect. Please check your internet connection and try again.',
    );
  }

  /// Shows a professional error message for timeout scenarios
  static void showTimeoutError({String? customMessage}) {
    SnackbarHelper.showError(
      customMessage ?? 'Connection timed out. Please check your internet connection and try again.',
    );
  }

  /// Shows a professional error message for data loading failures
  static void showLoadError({String? customMessage, String? itemName}) {
    final message = customMessage ?? 
        (itemName != null 
            ? 'Unable to load $itemName. Please check your connection and try again.'
            : 'Unable to load data. Please check your connection and try again.');
    SnackbarHelper.showError(message);
  }

  /// Shows a professional error message for server errors
  static void showServerError({String? customMessage}) {
    SnackbarHelper.showError(
      customMessage ?? 'Server error. Please try again later.',
    );
  }
}
