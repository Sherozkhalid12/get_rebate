import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

/// Centralized network error handler
/// Provides user-friendly error messages with retry functionality
class NetworkErrorHandler {
  /// Checks if error is a network connectivity issue
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    return false;
  }

  /// Gets user-friendly error message based on error type
  static String getUserFriendlyMessage(dynamic error, {String? defaultMessage}) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection and try again.';
        
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Please check your internet connection.';
        
        case DioExceptionType.unknown:
          // Check if it's a network error
          if (error.message?.contains('SocketException') == true ||
              error.message?.contains('Network is unreachable') == true ||
              error.message?.contains('Failed host lookup') == true) {
            return 'No internet connection. Please check your network settings and try again.';
          }
          return defaultMessage ?? 'An unexpected error occurred. Please try again.';
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 404) {
            return 'The requested resource was not found.';
          } else if (statusCode == 401) {
            return 'Your session has expired. Please log in again.';
          } else if (statusCode == 403) {
            return 'You do not have permission to perform this action.';
          } else if (statusCode == 500) {
            return 'Server error. Please try again later.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }
          return defaultMessage ?? 'Failed to load data. Please try again.';
        
        default:
          return defaultMessage ?? 'An error occurred. Please try again.';
      }
    }
    
    // Handle other error types
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('internet')) {
      return 'No internet connection. Please check your network settings and try again.';
    }
    
    return defaultMessage ?? 'An error occurred. Please try again.';
  }

  /// Shows user-friendly error message with retry option
  static void showNetworkError(
    dynamic error, {
    String? defaultMessage,
    VoidCallback? onRetry,
    BuildContext? context,
  }) {
    final message = getUserFriendlyMessage(error, defaultMessage: defaultMessage);
    final isNetworkIssue = isNetworkError(error);
    
    if (isNetworkIssue) {
      // Show network error with retry option
      SnackbarHelper.showError(
        message,
        title: 'No Internet Connection',
        context: context,
        duration: const Duration(seconds: 5),
      );
    } else {
      // Show regular error
      SnackbarHelper.showError(
        message,
        context: context,
        duration: const Duration(seconds: 4),
      );
    }
    
    if (kDebugMode) {
      print('❌ Network Error Handler:');
      print('   Error: $error');
      print('   Type: ${error is DioException ? error.type : error.runtimeType}');
      print('   Message: $message');
      print('   Is Network Error: $isNetworkIssue');
    }
  }

  /// Handles error and shows appropriate message
  /// Returns true if error was handled, false otherwise
  static bool handleError(
    dynamic error, {
    String? defaultMessage,
    VoidCallback? onRetry,
    BuildContext? context,
    bool showMessage = true,
  }) {
    if (showMessage) {
      showNetworkError(
        error,
        defaultMessage: defaultMessage,
        onRetry: onRetry,
        context: context,
      );
    }
    return true;
  }
}

