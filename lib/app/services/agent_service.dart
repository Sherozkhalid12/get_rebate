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

/// Paginated agents response model
class PaginatedAgentsResponse {
  final List<AgentModel> agents;
  final int page;
  final int limit;
  final int totalAgents;
  final int totalPages;
  final int count;
  final bool hasMore;

  PaginatedAgentsResponse({
    required this.agents,
    required this.page,
    required this.limit,
    required this.totalAgents,
    required this.totalPages,
    required this.count,
  }) : hasMore = page < totalPages;
}

/// Service for handling agent-related API calls
class AgentService {
  late final Dio _dio;
  
  // Cache to prevent duplicate API calls within a short time window
  final Map<String, DateTime> _searchCallCache = {};
  final Map<String, DateTime> _profileViewCallCache = {};
  final Map<String, DateTime> _contactCallCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes
  
  // Track 404 errors to reduce logging noise
  static bool _hasLogged404ForSearch = false;
  static bool _hasLogged404ForProfileView = false;
  static bool _hasLogged404ForContact = false;

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
    // Suppress 404 errors for tracking endpoints (they're expected if endpoints don't exist)
    final path = error.requestOptions.path.toLowerCase();
    final isTrackingEndpoint = path.contains('addsearch') || 
                               path.contains('addprofileview') || 
                               path.contains('addcontact');
    
    if (error.response?.statusCode == 404 && isTrackingEndpoint) {
      // Suppress 404s for tracking endpoints - they're already handled in individual methods
      return;
    }
    
    if (kDebugMode) {
      print('❌ Agent Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
      print('   Path: ${error.requestOptions.path}');
    }
  }

  /// Fetches all agents from the API (backward compatibility - uses page 1)
  /// 
  /// Throws [AgentServiceException] if the request fails
  Future<List<AgentModel>> getAllAgents() async {
    final result = await getAllAgentsPaginated(page: 1);
    return result.agents;
  }

  /// Fetches agents from the API with pagination
  /// 
  /// Throws [AgentServiceException] if the request fails
  Future<PaginatedAgentsResponse> getAllAgentsPaginated({required int page}) async {
    try {
      if (kDebugMode) {
        print('📡 Fetching agents from API (page $page)...');
        print('   URL: ${ApiConstants.getAllAgentsEndpoint(page)}');
      }

      final response = await _dio.get(
        ApiConstants.getAllAgentsEndpoint(page),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Agents response received');
        print('   Status Code: ${response.statusCode}');
      }

      // Handle paginated response format
      if (response.data is! Map<String, dynamic>) {
        throw AgentServiceException(
          message: 'Invalid response format from server',
        );
      }

      final responseMap = response.data as Map<String, dynamic>;
      
      // Check for success flag
      if (responseMap['success'] != true) {
        throw AgentServiceException(
          message: responseMap['message']?.toString() ?? 'Failed to fetch agents',
        );
      }

      // Extract pagination metadata
      final pageNum = responseMap['page'] as int? ?? page;
      final limit = responseMap['limit'] as int? ?? 10;
      final totalAgents = responseMap['totalAgents'] as int? ?? 0;
      final totalPages = responseMap['totalPages'] as int? ?? 1;
      final count = responseMap['count'] as int? ?? 0;

      // Extract agents array
      List<dynamic> agentsData;
      if (responseMap['agents'] != null && responseMap['agents'] is List) {
        agentsData = responseMap['agents'] as List<dynamic>;
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
        print('   Page: $pageNum/$totalPages');
        print('   Total: $totalAgents');
        print('   Has more: ${pageNum < totalPages}');
      }

      return PaginatedAgentsResponse(
        agents: agents,
        page: pageNum,
        limit: limit,
        totalAgents: totalAgents,
        totalPages: totalPages,
        count: count,
      );
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
  /// Note: API expects agent name, not ID
  Future<Map<String, dynamic>?> recordSearch(String agentId, {String? agentName}) async {
    if (agentId.isEmpty) {
      return null;
    }

    // Get agent name - use provided name or fetch by ID
    String? name = agentName?.trim();
    if (kDebugMode) {
      print('📊 recordSearch called with:');
      print('   Agent ID: $agentId');
      print('   Agent Name provided: ${agentName ?? "null"}');
    }
    
    if (name == null || name.isEmpty) {
      if (kDebugMode) {
        print('📊 Agent name not provided, fetching by ID: $agentId');
      }
      try {
        // Try to get agent by ID to get the name
        final agent = await getAgentById(agentId);
        name = agent?.name?.trim();
        if (kDebugMode) {
          if (name != null && name.isNotEmpty) {
            print('✅ Fetched agent name: "$name" for ID: $agentId');
          } else {
            print('⚠️ Agent found but name is empty for ID: $agentId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Could not fetch agent name for ID: $agentId - $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('✅ Using provided agent name: "$name" for ID: $agentId');
      }
    }
    
    if (name == null || name.isEmpty) {
      if (kDebugMode) {
        print('❌ Cannot record search: Agent name not available for ID: $agentId');
        print('   Skipping search recording - API requires agent name, not ID');
      }
      return null;
    }

    // Check cache to prevent duplicate calls (use name as key)
    final now = DateTime.now();
    if (_searchCallCache.containsKey(name)) {
      final lastCall = _searchCallCache[name]!;
      if (now.difference(lastCall) < _cacheDuration) {
        // Already called recently, skip
        return null;
      }
    }
    
    // Update cache
    _searchCallCache[name] = now;
    
    // Clean old cache entries (keep only last 100)
    if (_searchCallCache.length > 100) {
      final entries = _searchCallCache.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _searchCallCache.clear();
      for (var i = 0; i < 50 && i < entries.length; i++) {
        _searchCallCache[entries[i].key] = entries[i].value;
      }
    }

    // Use agent name in the endpoint instead of ID
    // URL encode the name to handle spaces and special characters
    final encodedName = Uri.encodeComponent(name);
    final endpoint = ApiConstants.getAddSearchEndpoint(encodedName);
    
    if (kDebugMode) {
      print('📊 Recording search for agent: "$name" (ID: $agentId)');
      print('   Encoded name: $encodedName');
      print('   URL: $endpoint');
    }

    try {
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
          validateStatus: (status) {
            // Accept all status codes to handle them manually
            return true;
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Search recorded successfully for agent: $name');
        }
        return response.data as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - log once and suppress future logs
        if (kDebugMode && !_hasLogged404ForSearch) {
          print('⚠️ Search endpoint not found (404) - endpoint may not exist on server');
          print('   Endpoint: $endpoint');
          print('   Future 404 errors for this endpoint will be suppressed');
          _hasLogged404ForSearch = true;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('⚠️ Search recording failed for agent: $name');
          print('   Status Code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      // Suppress 404 errors after first log
      if (e.response?.statusCode == 404 && _hasLogged404ForSearch) {
        return null;
      }
      
      if (kDebugMode && (!_hasLogged404ForSearch || e.response?.statusCode != 404)) {
        print('⚠️ Error recording search for agent: $name');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          _hasLogged404ForSearch = true;
        }
      }
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
    if (agentId.isEmpty) {
      return null;
    }

    // Check cache to prevent duplicate calls
    final now = DateTime.now();
    if (_contactCallCache.containsKey(agentId)) {
      final lastCall = _contactCallCache[agentId]!;
      if (now.difference(lastCall) < _cacheDuration) {
        // Already called recently, skip
        return null;
      }
    }
    
    // Update cache
    _contactCallCache[agentId] = now;

    final endpoint = ApiConstants.getAddContactEndpoint(agentId);
    
    if (kDebugMode && !_hasLogged404ForContact) {
      print('📞 Recording contact for agent: $agentId');
      print('   URL: $endpoint');
    }

    try {
      // API expects GET request, not POST
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Contact recorded successfully for agent: $agentId');
        }
        return response.data as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - log once and suppress future logs
        if (kDebugMode && !_hasLogged404ForContact) {
          print('⚠️ Contact endpoint not found (404) - endpoint may not exist on server');
          print('   Endpoint: $endpoint');
          print('   Future 404 errors for this endpoint will be suppressed');
          _hasLogged404ForContact = true;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('⚠️ Contact recording failed for agent: $agentId');
          print('   Status Code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      // Suppress 404 errors after first log
      if (e.response?.statusCode == 404 && _hasLogged404ForContact) {
        return null;
      }
      
      if (kDebugMode && (!_hasLogged404ForContact || e.response?.statusCode != 404)) {
        print('⚠️ Error recording contact for agent: $agentId');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          _hasLogged404ForContact = true;
        }
      }
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
    if (agentId.isEmpty) {
      return null;
    }

    // Check cache to prevent duplicate calls
    final now = DateTime.now();
    if (_profileViewCallCache.containsKey(agentId)) {
      final lastCall = _profileViewCallCache[agentId]!;
      if (now.difference(lastCall) < _cacheDuration) {
        // Already called recently, skip
        return null;
      }
    }
    
    // Update cache
    _profileViewCallCache[agentId] = now;

    final endpoint = ApiConstants.getAddProfileViewEndpoint(agentId);
    
    if (kDebugMode && !_hasLogged404ForProfileView) {
      print('👁️ Recording profile view for agent: $agentId');
      print('   URL: $endpoint');
    }

    try {
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
          validateStatus: (status) {
            // Accept all status codes to handle them manually
            return true;
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Profile view recorded successfully for agent: $agentId');
        }
        return response.data as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - log once and suppress future logs
        if (kDebugMode && !_hasLogged404ForProfileView) {
          print('⚠️ Profile view endpoint not found (404) - endpoint may not exist on server');
          print('   Endpoint: $endpoint');
          print('   Future 404 errors for this endpoint will be suppressed');
          _hasLogged404ForProfileView = true;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('⚠️ Profile view recording failed for agent: $agentId');
          print('   Status Code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      // Suppress 404 errors after first log
      if (e.response?.statusCode == 404 && _hasLogged404ForProfileView) {
        return null;
      }
      
      if (kDebugMode && (!_hasLogged404ForProfileView || e.response?.statusCode != 404)) {
        print('⚠️ Error recording profile view for agent: $agentId');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          _hasLogged404ForProfileView = true;
        }
      }
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

