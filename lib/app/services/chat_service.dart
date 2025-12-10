import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/chat_thread_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for chat service errors
class ChatServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ChatServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling chat-related API calls
class ChatService {
  late final Dio _dio;

  ChatService() {
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

  /// Handles Dio errors and converts them to ChatServiceException
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Chat Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Fetches chat threads for a given user ID
  /// 
  /// Throws [ChatServiceException] if the request fails
  Future<List<ChatThreadModel>> getChatThreads(String userId) async {
    if (userId.isEmpty) {
      throw ChatServiceException(
        message: 'User ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      if (kDebugMode) {
        print('📡 Fetching chat threads for userId: $userId');
        print('   URL: ${ApiConstants.getChatThreadsEndpoint(userId)}');
      }

      final response = await _dio.get(
        ApiConstants.getChatThreadsEndpoint(userId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Chat threads response received');
        print('   Status Code: ${response.statusCode}');
        print('   Data: ${response.data}');
      }

      // Handle different response formats
      List<dynamic> threadsData;
      
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        // Check for the new format with 'success' and 'threads'
        if (responseMap['success'] == true && responseMap['threads'] != null) {
          threadsData = responseMap['threads'] as List<dynamic>;
        } else if (responseMap['data'] != null) {
          threadsData = responseMap['data'] as List<dynamic>;
        } else if (responseMap['threads'] != null) {
          threadsData = responseMap['threads'] as List<dynamic>;
        } else {
          threadsData = [];
        }
      } else if (response.data is List) {
        threadsData = response.data as List<dynamic>;
      } else {
        threadsData = [];
      }

      final threads = threadsData
          .map((json) => ChatThreadModel.fromJson(
                json is Map<String, dynamic> ? json : json as Map<String, dynamic>,
              ))
          .toList();

      if (kDebugMode) {
        print('✅ Successfully parsed ${threads.length} chat threads');
      }

      return threads;
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
          // Connection refused or connection error
          if (e.message?.contains('Connection refused') == true ||
              e.message?.contains('Failed host lookup') == true) {
            errorMessage = 'Cannot connect to server. Please ensure:\n'
                '1. The server is running on port 3001\n'
                '2. For Android devices: Use your computer\'s IP address instead of localhost\n'
                '3. Both device and computer are on the same network';
          } else {
            errorMessage = 'Connection error. Please check your network and server status.';
          }
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Chat threads endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 403) {
            errorMessage = 'Access forbidden.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          e.response?.data?['error']?.toString() ?? 
                          'Failed to fetch chat threads.';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
          if (e.message?.contains('SocketException') == true ||
              e.message?.contains('Network is unreachable') == true ||
              e.message?.contains('Connection refused') == true) {
            errorMessage = 'Cannot connect to server. Please ensure the server is running and accessible.';
          } else {
            errorMessage = 'Network error. Please try again.';
          }
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }

      throw ChatServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      // Handle any other unexpected errors
      if (e is ChatServiceException) {
        rethrow;
      }

      throw ChatServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Creates a new chat thread between two users
  /// 
  /// Throws [ChatServiceException] if the request fails
  Future<Map<String, dynamic>> createThread({
    required String userId1,
    required String userId2,
  }) async {
    if (userId1.isEmpty || userId2.isEmpty) {
      throw ChatServiceException(
        message: 'Both user IDs are required',
        statusCode: 400,
      );
    }

    try {
      if (kDebugMode) {
        print('📡 Creating chat thread between $userId1 and $userId2');
        print('   URL: ${ApiConstants.apiBaseUrl}/chat/thread/create');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/chat/thread/create',
        data: {
          'userId1': userId1,
          'userId2': userId2,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Thread created successfully');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      // Handle different response formats
      Map<String, dynamic> threadData;
      
      if (response.data is Map) {
        threadData = response.data as Map<String, dynamic>;
        // If data is nested
        if (threadData['data'] != null) {
          threadData = threadData['data'] as Map<String, dynamic>;
        } else if (threadData['thread'] != null) {
          threadData = threadData['thread'] as Map<String, dynamic>;
        }
      } else {
        throw ChatServiceException(
          message: 'Invalid response format from server',
          statusCode: response.statusCode,
        );
      }

      return threadData;
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
            errorMessage = 'Thread creation endpoint not found.';
          } else if (statusCode == 400) {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          'Invalid request. Please check the user IDs.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          e.response?.data?['error']?.toString() ?? 
                          'Failed to create chat thread.';
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

      throw ChatServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ChatServiceException) {
        rethrow;
      }

      throw ChatServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Fetches messages for a specific chat thread
  /// 
  /// Throws [ChatServiceException] if the request fails
  Future<List<Map<String, dynamic>>> getThreadMessages({
    required String threadId,
    required String userId,
  }) async {
    if (threadId.isEmpty || userId.isEmpty) {
      throw ChatServiceException(
        message: 'Thread ID and User ID are required',
        statusCode: 400,
      );
    }

    try {
      // Build the endpoint URL - try both userId and userid (case sensitivity)
      final endpointUrl = '${ApiConstants.chatEndPoint}thread/$threadId/messages?userId=$userId';
      
      if (kDebugMode) {
        print('📡 Fetching messages for thread: $threadId');
        print('   User ID: $userId');
        print('   URL: $endpointUrl');
      }

      final response = await _dio.get(
        endpointUrl,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Messages response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      // Handle different response formats
      List<dynamic> messagesData;
      
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        // Check for the format with 'success' and 'messages'
        if (responseMap['success'] == true && responseMap['messages'] != null) {
          messagesData = responseMap['messages'] as List<dynamic>;
        } else if (responseMap['data'] != null) {
          messagesData = responseMap['data'] as List<dynamic>;
        } else if (responseMap['messages'] != null) {
          messagesData = responseMap['messages'] as List<dynamic>;
        } else {
          messagesData = [];
        }
      } else if (response.data is List) {
        messagesData = response.data as List<dynamic>;
      } else {
        messagesData = [];
      }

      final messages = messagesData
          .map((json) => json is Map<String, dynamic> 
              ? json 
              : json as Map<String, dynamic>)
          .toList();

      if (kDebugMode) {
        print('✅ Successfully parsed ${messages.length} messages');
      }

      return messages;
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
            errorMessage = 'Messages endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 403) {
            errorMessage = 'Access forbidden.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          e.response?.data?['error']?.toString() ?? 
                          'Failed to fetch messages.';
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

      throw ChatServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ChatServiceException) {
        rethrow;
      }

      throw ChatServiceException(
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

