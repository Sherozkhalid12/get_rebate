import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for user service errors
class UserServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  UserServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// User data model from API
class UserData {
  final String id;
  final String? fullname;
  final String? email;
  final String? bio;
  final String? profilePic;
  final String? role;

  UserData({
    required this.id,
    this.fullname,
    this.email,
    this.bio,
    this.profilePic,
    this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? json['name']?.toString(),
      email: json['email']?.toString(),
      bio: json['bio']?.toString(),
      profilePic: json['profilePic']?.toString() ?? 
                  json['profileImage']?.toString() ??
                  json['profile_pic']?.toString(),
      role: json['role']?.toString(),
    );
  }

  /// Gets the full profile picture URL
  String? getProfilePicUrl() {
    if (profilePic == null || profilePic!.isEmpty) return null;
    
    // If already a full URL, return as is
    if (profilePic!.startsWith('http://') || profilePic!.startsWith('https://')) {
      return profilePic;
    }
    
    // Otherwise, prepend base URL
    String path = profilePic!;
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '${ApiConstants.baseUrl}$path';
  }
}

/// Service for handling user-related API calls
class UserService {
  late final Dio _dio;

  UserService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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

  /// Handles Dio errors
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ User Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Fetches user data by ID
  /// 
  /// Throws [UserServiceException] if the request fails
  Future<UserData> getUserById(String userId) async {
    if (userId.isEmpty) {
      throw UserServiceException(
        message: 'User ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      if (kDebugMode) {
        print('📡 Fetching user data for userId: $userId');
        print('   URL: ${ApiConstants.getUserByIdEndpoint(userId)}');
      }

      final response = await _dio.get(
        ApiConstants.getUserByIdEndpoint(userId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ User data response received');
        print('   Status Code: ${response.statusCode}');
      }

      // Handle different response formats
      Map<String, dynamic> userData;
      
      if (response.data is Map) {
        userData = response.data as Map<String, dynamic>;
        // If data is nested in a 'data' or 'user' field
        if (userData['data'] != null) {
          userData = userData['data'] as Map<String, dynamic>;
        } else if (userData['user'] != null) {
          userData = userData['user'] as Map<String, dynamic>;
        }
      } else {
        throw UserServiceException(
          message: 'Invalid response format from server',
          statusCode: response.statusCode,
        );
      }

      final user = UserData.fromJson(userData);

      if (kDebugMode) {
        print('✅ Successfully parsed user data: ${user.fullname}');
      }

      return user;
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
            errorMessage = 'User not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          e.response?.data?['error']?.toString() ?? 
                          'Failed to fetch user data.';
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

      throw UserServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is UserServiceException) {
        rethrow;
      }

      throw UserServiceException(
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

