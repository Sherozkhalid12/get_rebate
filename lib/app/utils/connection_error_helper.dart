import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/widgets/connection_error_dialog.dart';

/// Helper to detect connection/timeout errors and show the professional dialog.
class ConnectionErrorHelper {
  ConnectionErrorHelper._();

  /// Returns true if the error is a connection/timeout/internet-related error.
  static bool isConnectionError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          return error.response?.statusCode == 408; // Request Timeout
        case DioExceptionType.unknown:
          final msg = (error.message ?? '').toLowerCase();
          return msg.contains('timeout') ||
              msg.contains('connection') ||
              msg.contains('network') ||
              msg.contains('host lookup') ||
              msg.contains('socket');
        default:
          return false;
      }
    }

    if (error is Exception || error is String) {
      final str = error.toString().toLowerCase();
      return str.contains('timeout') ||
          str.contains('timed out') ||
          str.contains('connection') ||
          str.contains('network') ||
          str.contains('failed to load') ||
          str.contains('failed to fetch') ||
          str.contains('host lookup') ||
          str.contains('socket');
    }

    // Service exceptions with connection-related messages
    final str = error.toString().toLowerCase();
    return str.contains('timeout') ||
        str.contains('connection') ||
        str.contains('network') ||
        str.contains('internet');
  }

  /// Shows the connection error dialog with optional retry.
  /// Safe to call from onInit – uses addPostFrameCallback to avoid overlay issues.
  static void showDialog({
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    ConnectionErrorDialog.show(
      title: title ?? 'Connection Issue',
      message: message ??
          'We\'re unable to connect right now. Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }
}
