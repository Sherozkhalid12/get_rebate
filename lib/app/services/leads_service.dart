import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        baseUrl: ApiConstants.baseUrl, // Use baseUrl which is http://98.93.16.113:3001
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
      // Get endpoint path (relative to baseUrl)
      // apiBaseUrl is "baseUrl/api/v1", so we need "/api/v1/agent/getLeadsByAgentId/$agentId"
      final endpoint = '/api/v1/agent/getLeadsByAgentId/$agentId';
      
      if (kDebugMode) {
        print('📡 Fetching leads for agentId: $agentId');
        print('   Endpoint path: $endpoint');
        print('   Dio Base URL: ${_dio.options.baseUrl}');
        print('   Full URL: ${_dio.options.baseUrl}$endpoint');
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
        final errorMessage = e.response!.data?['message']?.toString() ?? 
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
          errorMsg = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'No internet connection. Please check your network.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = 'Network error: ${e.message}';
        } else if (e.error != null) {
          errorMsg = 'Network error: ${e.error}';
        }
        
        throw LeadsServiceException(
          message: errorMsg,
          originalError: e,
        );
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

  /// Fetches leads created by a buyer (user)
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
      // Get endpoint path (relative to baseUrl)
      // apiBaseUrl is "baseUrl/api/v1", so we need "/api/v1/buyer/getLeadsByAgentId/$buyerId"
      final endpoint = '/api/v1/buyer/getLeadsByAgentId/$buyerId';
      
      if (kDebugMode) {
        print('📡 Fetching leads for buyerId: $buyerId');
        print('   Endpoint path: $endpoint');
        print('   Dio Base URL: ${_dio.options.baseUrl}');
        print('   Full URL: ${_dio.options.baseUrl}$endpoint');
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
        print('✅ Buyer leads response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response data: ${response.data}');
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
        final errorMessage = e.response!.data?['message']?.toString() ?? 
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
          errorMsg = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'No internet connection. Please check your network.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = 'Network error: ${e.message}';
        } else if (e.error != null) {
          errorMsg = 'Network error: ${e.error}';
        }
        
        throw LeadsServiceException(
          message: errorMsg,
          originalError: e,
        );
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

  /// Responds to a lead (accept/reject) with optional note
  /// 
  /// Throws [LeadsServiceException] if the request fails
  Future<void> respondToLead(
    String leadId,
    String agentId, {
    required String action, // 'accepted' or 'rejected'
    String? note,
  }) async {
    if (leadId.isEmpty || agentId.isEmpty) {
      throw LeadsServiceException(
        message: 'Lead ID and Agent ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      final endpoint = '/api/v1/agent/respondToLead';
      
      if (kDebugMode) {
        print('📡 Responding to lead: $leadId');
        print('   Agent ID: $agentId');
        print('   Action: $action');
        print('   Note: ${note ?? "Not provided"}');
      }

      final response = await _dio.post(
        endpoint,
        data: {
          'leadId': leadId,
          'agentId': agentId,
          'action': action,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Successfully responded to lead');
        }
      } else {
        throw LeadsServiceException(
          message: 'Failed to respond to lead: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = e.response!.data?['message']?.toString() ?? 
                            e.response!.data?['error']?.toString() ?? 
                            'Failed to respond to lead';
        
        throw LeadsServiceException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: e,
        );
      } else {
        throw LeadsServiceException(
          message: 'Network error: ${e.message ?? "Unknown error"}',
          originalError: e,
        );
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
  /// Throws [LeadsServiceException] if the request fails
  Future<void> markLeadComplete(
    String leadId,
    String userId,
    String role,
  ) async {
    if (leadId.isEmpty || userId.isEmpty) {
      throw LeadsServiceException(
        message: 'Lead ID and User ID cannot be empty',
        statusCode: 400,
      );
    }

    try {
      final endpoint = '/api/v1/agent/markLeadComplete';
      
      if (kDebugMode) {
        print('📡 Marking lead as complete: $leadId');
        print('   User ID: $userId');
        print('   Role: $role');
      }

      final response = await _dio.post(
        endpoint,
        data: {
          'leadId': leadId,
          'userId': userId,
          'role': role,
        },
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Successfully marked lead as complete');
        }
      } else {
        throw LeadsServiceException(
          message: 'Failed to mark lead as complete: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = e.response!.data?['message']?.toString() ?? 
                            e.response!.data?['error']?.toString() ?? 
                            'Failed to mark lead as complete';
        
        throw LeadsServiceException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: e,
        );
      } else {
        throw LeadsServiceException(
          message: 'Network error: ${e.message ?? "Unknown error"}',
          originalError: e,
        );
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

