import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/notification_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for notification service errors
class NotificationServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NotificationServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling notification-related API calls
class NotificationService {
  late final Dio _dio;

  NotificationService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...ApiConstants.ngrokHeaders,
        },
      ),
    );

    // Add interceptors for error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    );
  }

  /// Handles Dio errors and converts them to NotificationServiceException
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Notification Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Fetches notifications for a given user ID
  /// 
  /// Throws [NotificationServiceException] if the request fails
  Future<NotificationResponse> getNotifications(String userId) async {
    if (userId.isEmpty) {
      throw NotificationServiceException(
        message: 'User ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      if (kDebugMode) {
        print('📡 Fetching notifications for userId: $userId');
        print('   URL: ${ApiConstants.getNotificationsEndpoint(userId)}');
      }

        final response = await _dio.get(
          ApiConstants.getNotificationsEndpoint(userId),
          options: Options(
            headers: ApiConstants.ngrokHeaders,
          ),
        );

      if (kDebugMode) {
        print('✅ Notifications response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final notificationResponse =
            NotificationResponse.fromJson(response.data as Map<String, dynamic>);

        if (kDebugMode) {
          print('✅ Successfully parsed ${notificationResponse.notifications.length} notifications');
          print('   Unread Count: ${notificationResponse.unreadCount}');
          print('   Total: ${notificationResponse.total}');
        }

        return notificationResponse;
      } else {
        throw NotificationServiceException(
          message: 'Failed to fetch notifications: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      int? statusCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          statusCode = 408;
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot connect to server. Please ensure the server is running.';
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Notifications endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 403) {
            errorMessage = 'Access forbidden.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ??
                e.response?.data?['error']?.toString() ??
                'Failed to fetch notifications.';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
          errorMessage = 'Network error. Please try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }

      throw NotificationServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is NotificationServiceException) {
        rethrow;
      }

      throw NotificationServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Marks a notification as read
  /// 
  /// Throws [NotificationServiceException] if the request fails
  Future<bool> markNotificationAsRead(String notificationId) async {
    if (notificationId.isEmpty) {
      throw NotificationServiceException(
        message: 'Notification ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      if (kDebugMode) {
        print('📡 Marking notification as read');
        print('   Notification ID: $notificationId');
        print('   URL: ${ApiConstants.getMarkNotificationReadEndpoint(notificationId)}');
      }

      final response = await _dio.post(
        ApiConstants.getMarkNotificationReadEndpoint(notificationId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Mark as read response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw NotificationServiceException(
          message: 'Failed to mark notification as read: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      int? statusCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          statusCode = 408;
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot connect to server. Please ensure the server is running.';
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Mark as read endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ??
                e.response?.data?['error']?.toString() ??
                'Failed to mark notification as read.';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
          errorMessage = 'Network error. Please try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }

      throw NotificationServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is NotificationServiceException) {
        rethrow;
      }

      throw NotificationServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Marks all notifications as read for a user
  /// 
  /// Throws [NotificationServiceException] if the request fails
  Future<bool> markAllNotificationsAsRead(String userId) async {
    if (userId.isEmpty) {
      throw NotificationServiceException(
        message: 'User ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      if (kDebugMode) {
        print('📡 Marking all notifications as read');
        print('   User ID: $userId');
        print('   URL: ${ApiConstants.getMarkAllNotificationsReadEndpoint(userId)}');
      }

      final response = await _dio.post(
        ApiConstants.getMarkAllNotificationsReadEndpoint(userId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Mark all as read response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw NotificationServiceException(
          message: 'Failed to mark all notifications as read: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      int? statusCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          statusCode = 408;
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot connect to server. Please ensure the server is running.';
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Mark all as read endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ??
                e.response?.data?['error']?.toString() ??
                'Failed to mark all notifications as read.';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
          errorMessage = 'Network error. Please try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }

      throw NotificationServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is NotificationServiceException) {
        rethrow;
      }

      throw NotificationServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Disposes the Dio instance
  void dispose() {
    _dio.close();
  }
}

