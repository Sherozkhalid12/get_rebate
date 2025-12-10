import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for agent service errors
class AgentServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AgentServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling agent-related API calls
class AgentService {
  late final Dio _dio;

  AgentService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
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

  /// Handles Dio errors
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Agent Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Fetches all agents from the API
  /// 
  /// Throws [AgentServiceException] if the request fails
  Future<List<AgentModel>> getAllAgents() async {
    try {
      if (kDebugMode) {
        print('📡 Fetching all agents from API...');
        print('   URL: ${ApiConstants.apiBaseUrl}/agent/getAllAgents');
      }

      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}/agent/getAllAgents',
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Agents response received');
        print('   Status Code: ${response.statusCode}');
      }

      // Handle different response formats
      List<dynamic> agentsData;
      
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        // Check for the format with 'success' and 'agents'
        if (responseMap['success'] == true && responseMap['agents'] != null) {
          agentsData = responseMap['agents'] as List<dynamic>;
        } else if (responseMap['data'] != null) {
          agentsData = responseMap['data'] as List<dynamic>;
        } else {
          agentsData = [];
        }
      } else if (response.data is List) {
        agentsData = response.data as List<dynamic>;
      } else {
        agentsData = [];
      }

      final agents = agentsData
          .map((json) => AgentModel.fromJson(
                json is Map<String, dynamic> ? json : json as Map<String, dynamic>,
              ))
          .toList();

      if (kDebugMode) {
        print('✅ Successfully parsed ${agents.length} agents');
      }

      return agents;
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
            errorMessage = 'Agents endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          e.response?.data?['error']?.toString() ?? 
                          'Failed to fetch agents.';
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

      throw AgentServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is AgentServiceException) {
        rethrow;
      }

      throw AgentServiceException(
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

