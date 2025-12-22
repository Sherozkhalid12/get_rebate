import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
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
        connectTimeout: const Duration(seconds: 10), // Reduced from 30 to 10
        receiveTimeout: const Duration(seconds: 10), // Reduced from 30 to 10
        sendTimeout: const Duration(seconds: 10), // Reduced from 30 to 10
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

      final agents = <AgentModel>[];
      
      for (int i = 0; i < agentsData.length; i++) {
        try {
          final json = agentsData[i];
          
          // Skip if not a Map
          if (json is! Map<String, dynamic>) {
            if (kDebugMode) {
              print('⚠️ Skipping agent at index $i: expected Map but got ${json.runtimeType}');
            }
            continue;
          }
          
          final agent = AgentModel.fromJson(json);
          agents.add(agent);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing agent at index $i: $e');
            print('   Data: ${agentsData[i]}');
          }
          // Continue to next agent instead of failing completely
        }
      }

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

  /// Fetches a single agent by ID from the API
  /// 
  /// Throws [AgentServiceException] if the request fails
  Future<AgentModel?> getAgentById(String agentId) async {
    try {
      if (kDebugMode) {
        print('📡 Fetching agent by ID: $agentId');
      }

      // First try to get all agents and find the one with matching ID
      final allAgents = await getAllAgents();
      final agent = allAgents.firstWhereOrNull((a) => a.id == agentId);
      
      if (agent != null) {
        if (kDebugMode) {
          print('✅ Found agent: ${agent.name}');
        }
        return agent;
      }

      if (kDebugMode) {
        print('⚠️ Agent with ID $agentId not found');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching agent by ID: $e');
      }
      rethrow;
    }
  }

  /// Records a search for an agent
  /// Returns the response data with message and searches count
  Future<Map<String, dynamic>?> recordSearch(String agentId) async {
    try {
      if (kDebugMode) {
        print('📊 Recording search for agent: $agentId');
        print('   URL: ${ApiConstants.getAddSearchEndpoint(agentId)}');
      }

      final response = await _dio.post(
        ApiConstants.getAddSearchEndpoint(agentId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Search recorded successfully');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording search: ${e.message}');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }
      // Don't throw - tracking should not break the app
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error recording search: $e');
      }
      return null;
    }
  }

  /// Records a contact/chat action for an agent
  /// Returns the response data
  Future<Map<String, dynamic>?> recordContact(String agentId) async {
    try {
      if (kDebugMode) {
        print('📞 Recording contact for agent: $agentId');
        print('   URL: ${ApiConstants.getAddContactEndpoint(agentId)}');
      }

      final response = await _dio.post(
        ApiConstants.getAddContactEndpoint(agentId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Contact recorded successfully');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording contact: ${e.message}');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }
      // Don't throw - tracking should not break the app
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error recording contact: $e');
      }
      return null;
    }
  }

  /// Records a profile view for an agent
  /// Returns the response data
  Future<Map<String, dynamic>?> recordProfileView(String agentId) async {
    try {
      if (kDebugMode) {
        print('👁️ Recording profile view for agent: $agentId');
        print('   URL: ${ApiConstants.getAddProfileViewEndpoint(agentId)}');
      }

      final response = await _dio.post(
        ApiConstants.getAddProfileViewEndpoint(agentId),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Profile view recorded successfully');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording profile view: ${e.message}');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }
      // Don't throw - tracking should not break the app
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected error recording profile view: $e');
      }
      return null;
    }
  }

  /// Disposes the Dio instance
  void dispose() {
    _dio.close();
  }
}

