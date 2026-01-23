import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for leads service errors
class LeadsServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  LeadsServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling leads-related API calls
class LeadsService {
  late final Dio _dio;

  LeadsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl, // Use apiBaseUrl which includes /api/v1
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
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

  String _buildFullUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    return '${ApiConstants.baseUrl}$endpoint';
  }

  /// Handles Dio errors and converts them to LeadsServiceException
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Leads Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Fetches leads for a given agent ID
  ///
  /// Throws [LeadsServiceException] if the request fails
  Future<LeadsResponse> getLeadsByAgentId(String agentId) async {
    if (agentId.isEmpty) {
      throw LeadsServiceException(
        message: 'Agent ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      final endpoint = ApiConstants.getLeadsByAgentIdEndpoint(agentId);
      final fullUrl = _buildFullUrl(endpoint);

      if (kDebugMode) {
        print('📡 Fetching leads for agentId: $agentId');
        print('   Endpoint: $endpoint');
        print('   Base URL: ${ApiConstants.baseUrl}');
        print('   Full URL: $fullUrl');
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Leads response received');
        print('   Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          return LeadsResponse.fromJson(data);
        } else {
          throw LeadsServiceException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw LeadsServiceException(
          message: 'Failed to fetch leads: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException in getLeadsByAgentId:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Error: ${e.error}');
        print('   Request path: ${e.requestOptions.path}');
        print('   Request baseUrl: ${e.requestOptions.baseUrl}');
        print('   Full URL: ${e.requestOptions.uri}');
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage =
            e.response!.data?['message']?.toString() ??
            e.response!.data?['error']?.toString() ??
            'Failed to fetch leads';

        throw LeadsServiceException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: e,
        );
      } else {
        // Handle different DioException types
        String errorMsg = 'Network error';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'No internet connection. Please check your network.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = 'Network error: ${e.message}';
        } else if (e.error != null) {
          errorMsg = 'Network error: ${e.error}';
        }

        throw LeadsServiceException(message: errorMsg, originalError: e);
      }
    } catch (e) {
      if (e is LeadsServiceException) {
        rethrow;
      }
      throw LeadsServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Fetches leads for a given buyer/user ID
  ///
  /// Throws [LeadsServiceException] if the request fails
  Future<LeadsResponse> getLeadsByBuyerId(String buyerId) async {
    if (buyerId.isEmpty) {
      throw LeadsServiceException(
        message: 'Buyer ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      // Get auth token from storage
      final storage = GetStorage();
      final authToken = storage.read('auth_token');

      // Extract just the path from the full endpoint URL
      // getLeadsByBuyerIdEndpoint returns full URL, but we need just the path
      final fullEndpoint = ApiConstants.getLeadsByBuyerIdEndpoint(buyerId);
      final endpoint = fullEndpoint.replaceFirst(ApiConstants.apiBaseUrl, '');

      if (kDebugMode) {
        print('📡 Fetching leads for buyerId: $buyerId');
        print('   Full Endpoint: $fullEndpoint');
        print('   Endpoint Path: $endpoint');
        print('   Base URL: ${ApiConstants.apiBaseUrl}');
        print('   Full URL: ${ApiConstants.apiBaseUrl}$endpoint');
        print('   Auth Token: ${authToken != null ? "Present" : "Missing"}');
      }

      // Build headers with auth token
      final headers = <String, String>{
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add Authorization header if token exists
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      if (kDebugMode) {
        print('✅ Leads response received');
        print('   Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          return LeadsResponse.fromJson(data);
        } else {
          throw LeadsServiceException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw LeadsServiceException(
          message: 'Failed to fetch leads: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException in getLeadsByBuyerId:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Error: ${e.error}');
        print('   Request path: ${e.requestOptions.path}');
        print('   Request baseUrl: ${e.requestOptions.baseUrl}');
        print('   Full URL: ${e.requestOptions.uri}');
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage =
            e.response!.data?['message']?.toString() ??
            e.response!.data?['error']?.toString() ??
            'Failed to fetch leads';

        throw LeadsServiceException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: e,
        );
      } else {
        String errorMsg = 'Network error';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'No internet connection. Please check your network.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = 'Network error: ${e.message}';
        } else if (e.error != null) {
          errorMsg = 'Network error: ${e.error}';
        }

        throw LeadsServiceException(message: errorMsg, originalError: e);
      }
    } catch (e) {
      if (e is LeadsServiceException) {
        rethrow;
      }
      throw LeadsServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Responds to a lead (agent contacts buyer)
  ///
  /// [leadId] - The ID of the lead to respond to
  /// [agentId] - The ID of the agent responding to the lead
  /// [action] - The action to take: "accept" or "reject"
  /// [note] - Optional note/message from the agent
  ///
  /// Throws [LeadsServiceException] if the request fails
  Future<void> respondToLead(
    String leadId,
    String agentId, {
    String action = 'accept',
    String? note,
  }) async {
    if (leadId.isEmpty) {
      throw LeadsServiceException(
        message: 'Lead ID cannot be empty',
        statusCode: 400,
      );
    }

    if (agentId.isEmpty) {
      throw LeadsServiceException(
        message: 'Agent ID cannot be empty',
        statusCode: 400,
      );
    }

    if (action != 'accept' && action != 'reject') {
      throw LeadsServiceException(
        message: 'Action must be "accept" or "reject"',
        statusCode: 400,
      );
    }

    try {
      final endpoint = ApiConstants.getRespondToLeadEndpoint(leadId);
      final fullUrl = _buildFullUrl(endpoint);

      if (kDebugMode) {
        print('📡 Responding to lead: $leadId');
        print('   Agent ID: $agentId');
        print('   Action: $action');
        print('   Note: ${note ?? "Not provided"}');
        print('   Endpoint: $endpoint');
        print('   Base URL: ${ApiConstants.baseUrl}');
        print('   Full URL: $fullUrl');
      }

      // Get auth token from storage
      final storage = GetStorage();
      final authToken = storage.read('auth_token');

      if (kDebugMode) {
        if (authToken != null && authToken.isNotEmpty) {
          final tokenPreview = authToken.length > 20
              ? '${authToken.substring(0, 20)}...'
              : authToken;
          print('   Auth Token: Present ($tokenPreview)');
        } else {
          print('   Auth Token: Missing');
        }
      }

      // Send request body with action, agentId, and optional note
      final requestBody = <String, dynamic>{
        'action': action,
        'agentId': agentId,
      };

      // Add note if provided
      if (note != null && note.isNotEmpty) {
        requestBody['note'] = note;
      }

      if (kDebugMode) {
        print('   Request Body: $requestBody');
      }

      // Build headers with Bearer token
      final headers = <String, String>{
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add Authorization header with Bearer token
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      if (kDebugMode) {
        print('   Headers: ${headers.keys.toList()}');
        print(
          '   Authorization: ${headers.containsKey('Authorization') ? "Present" : "Missing"}',
        );
      }

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: Options(headers: headers),
      );

      if (kDebugMode) {
        print('✅ Respond to lead response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw LeadsServiceException(
          message: 'Failed to respond to lead: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException in respondToLead:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage =
            e.response!.data?['message']?.toString() ??
            e.response!.data?['error']?.toString() ??
            'Failed to respond to lead';

        throw LeadsServiceException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: e,
        );
      } else {
        String errorMsg = 'Network error';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'No internet connection. Please check your network.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = 'Network error: ${e.message}';
        }

        throw LeadsServiceException(message: errorMsg, originalError: e);
      }
    } catch (e) {
      if (e is LeadsServiceException) {
        rethrow;
      }
      throw LeadsServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Marks a lead as complete
  ///
  /// [leadId] - The ID of the lead to mark as complete
  /// [userId] - The ID of the user (buyer/seller)
  /// [role] - The role of the user ("buyer/seller" or "user")
  ///
  /// Throws [LeadsServiceException] if the request fails
  Future<void> markLeadComplete(
    String leadId,
    String userId,
    String role,
  ) async {
    if (leadId.isEmpty) {
      throw LeadsServiceException(
        message: 'Lead ID cannot be empty',
        statusCode: 400,
      );
    }

    if (userId.isEmpty) {
      throw LeadsServiceException(
        message: 'User ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      final endpoint = ApiConstants.getMarkLeadCompleteEndpoint(leadId);
      final fullUrl = _buildFullUrl(endpoint);

      if (kDebugMode) {
        print('📡 Marking lead as complete: $leadId');
        print('   User ID: $userId');
        print('   Role: $role');
        print('   Endpoint: $endpoint');
        print('   Base URL: ${ApiConstants.baseUrl}');
        print('   Full URL: $fullUrl');
      }

      // Get auth token from storage
      final storage = GetStorage();
      final authToken = storage.read('auth_token');

      if (kDebugMode) {
        if (authToken != null && authToken.isNotEmpty) {
          final tokenPreview = authToken.length > 20
              ? '${authToken.substring(0, 20)}...'
              : authToken;
          print('   Auth Token: Present ($tokenPreview)');
        } else {
          print('   Auth Token: Missing');
        }
      }

      // Send request body with userId and role
      final requestBody = <String, dynamic>{'userId': userId, 'role': role};

      if (kDebugMode) {
        print('   Request Body: $requestBody');
      }

      // Build headers with Bearer token
      final headers = <String, String>{
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add Authorization header with Bearer token
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      if (kDebugMode) {
        print('   Headers: ${headers.keys.toList()}');
        print(
          '   Authorization: ${headers.containsKey('Authorization') ? "Present" : "Missing"}',
        );
      }

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: Options(headers: headers),
      );

      if (kDebugMode) {
        print('✅ Mark lead complete response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw LeadsServiceException(
          message: 'Failed to mark lead as complete: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException in markLeadComplete:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage =
            e.response!.data?['message']?.toString() ??
            e.response!.data?['error']?.toString() ??
            'Failed to mark lead as complete';

        throw LeadsServiceException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: e,
        );
      } else {
        String errorMsg = 'Network error';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'No internet connection. Please check your network.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = 'Network error: ${e.message}';
        }

        throw LeadsServiceException(message: errorMsg, originalError: e);
      }
    } catch (e) {
      if (e is LeadsServiceException) {
        rethrow;
      }
      throw LeadsServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
