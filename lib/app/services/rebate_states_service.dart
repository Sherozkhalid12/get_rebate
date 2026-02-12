import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Service for managing rebate-allowed states
/// Can fetch from backend API or use cached fallback list
class RebateStatesService {
  static const String _cacheKey = 'rebate_allowed_states';
  static const String _cacheTimestampKey = 'rebate_states_cache_timestamp';
  static const Duration _cacheValidity = Duration(hours: 24);

  late final Dio _dio;
  final GetStorage _storage = GetStorage();

  // Fallback list of states that allow rebates (if API fails)
  static const List<String> _fallbackAllowedStates = [
    'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'KY', 'ME', 'MD', 'MA',
    'MI', 'MN', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM',
    'NY', 'NC', 'ND', 'OH', 'PA', 'RI', 'SC', 'SD',
    'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
  ];

  RebateStatesService() {
    _dio = Dio();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (kDebugMode) {
            print('RebateStatesService error: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Fetches allowed states from backend API
  /// Returns cached list if API fails or cache is still valid
  Future<List<String>> getAllowedStates({bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedStates = _getCachedStates();
        if (cachedStates != null && _isCacheValid()) {
          if (kDebugMode) {
            print('✅ Using cached rebate-allowed states');
          }
          return cachedStates;
        }
      }

      // Try to fetch from API
      final endpoint = '${ApiConstants.apiBaseUrl}/rebate/allowed-states';
      if (kDebugMode) {
        print('📡 Fetching rebate-allowed states from: $endpoint');
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

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<String> states = [];

        // Handle different response formats
        if (data is List) {
          states = data.map((e) => e.toString().toUpperCase()).toList();
        } else if (data is Map<String, dynamic>) {
          final statesList = data['states'] ?? data['allowedStates'] ?? [];
          if (statesList is List) {
            states = statesList.map((e) => e.toString().toUpperCase()).toList();
          }
        }

        if (states.isNotEmpty) {
          // Cache the result
          _cacheStates(states);
          if (kDebugMode) {
            print('✅ Fetched ${states.length} rebate-allowed states from API');
          }
          return states;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch rebate-allowed states from API: $e');
        print('   Using fallback list');
      }
    }

    // Fallback to cached or default list
    final cachedStates = _getCachedStates();
    if (cachedStates != null) {
      return cachedStates;
    }

    return List<String>.from(_fallbackAllowedStates);
  }

  /// Checks if a state allows rebates
  Future<bool> isStateAllowed(String stateCode) async {
    final allowedStates = await getAllowedStates();
    return allowedStates.contains(stateCode.toUpperCase());
  }

  /// Gets cached states from local storage
  List<String>? _getCachedStates() {
    try {
      final cached = _storage.read<List<dynamic>>(_cacheKey);
      if (cached != null) {
        return cached.map((e) => e.toString().toUpperCase()).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading cached states: $e');
      }
    }
    return null;
  }

  /// Checks if cache is still valid
  bool _isCacheValid() {
    try {
      final timestamp = _storage.read<int>(_cacheTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        return now.difference(cacheTime) < _cacheValidity;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking cache validity: $e');
      }
    }
    return false;
  }

  /// Caches states to local storage
  void _cacheStates(List<String> states) {
    try {
      _storage.write(_cacheKey, states);
      _storage.write(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching states: $e');
      }
    }
  }

  /// Gets the fallback list (for UI display when API is unavailable)
  static List<String> getFallbackAllowedStates() {
    return List<String>.from(_fallbackAllowedStates);
  }
}
