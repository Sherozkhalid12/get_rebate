import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/models/loan_officer_zip_code_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for loan officer zip code service errors
class LoanOfficerZipCodeServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  LoanOfficerZipCodeServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling loan officer zip code-related API calls
/// Uses separate endpoint: /api/v1/zip-codes/:country/:state/:userId
class LoanOfficerZipCodeService {
  late final Dio _dio;
  final GetStorage _storage = GetStorage();

  LoanOfficerZipCodeService() {
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
        onRequest: (options, handler) {
          // Add auth token if available
          final authToken = _storage.read('auth_token');
          if (authToken != null) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    );
  }

  static Map<String, dynamic> _ensurePostalCode(Map<String, dynamic> m) {
    final p = m['postalCode']?.toString() ?? '';
    if (p.isEmpty) {
      m['postalCode'] = m['zipCode']?.toString() ?? m['zipcode']?.toString() ?? '';
    }
    return m;
  }

  /// Handles Dio errors
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ Loan Officer Zip Code Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Converts full state name to two-letter abbreviation
  /// Returns the original string if conversion fails or if already an abbreviation
  String _convertStateNameToAbbreviation(String stateName) {
    const stateMap = {
      'Arizona': 'AZ',
      'Arkansas': 'AR',
      'California': 'CA',
      'Colorado': 'CO',
      'Connecticut': 'CT',
      'Delaware': 'DE',
      'Florida': 'FL',
      'Georgia': 'GA',
      'Hawaii': 'HI',
      'Idaho': 'ID',
      'Illinois': 'IL',
      'Indiana': 'IN',
      'Kentucky': 'KY',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Montana': 'MT',
      'Nebraska': 'NE',
      'Nevada': 'NV',
      'New Hampshire': 'NH',
      'New Jersey': 'NJ',
      'New Mexico': 'NM',
      'New York': 'NY',
      'North Carolina': 'NC',
      'North Dakota': 'ND',
      'Ohio': 'OH',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY',
    };

    // If already an abbreviation (2 letters), return as-is (uppercase)
    if (stateName.length == 2) {
      return stateName.toUpperCase();
    }

    return stateMap[stateName] ?? stateName.toUpperCase();
  }

  static void _logZipApi(String title, String method, String path, int? status, dynamic body) {
    if (!kDebugMode) return;
    const line = '─────────────────────────────────────────────────────────';
    print('\n$line');
    print('  $title');
    print('$line');
    print('  $method $path');
    print('  Response: ${status ?? "—"}');
    if (body != null) {
      final str = body is Map ? body.toString() : body.toString();
      print('  Body: $str');
    }
    print('$line\n');
  }

  /// Validates a 5-digit ZIP for a state via GET /api/v1/zip-codes/validate/:zipcode/:state
  /// Returns true if valid. Throws [LoanOfficerZipCodeServiceException] otherwise.
  Future<bool> validateZipCode({ required String zipcode, required String state }) async {
    final trimmed = zipcode.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(trimmed)) {
      throw LoanOfficerZipCodeServiceException(message: 'ZIP code must be exactly 5 digits', statusCode: 400);
    }
    if (state.isEmpty) {
      throw LoanOfficerZipCodeServiceException(message: 'State is required', statusCode: 400);
    }
    final stateAbbr = _convertStateNameToAbbreviation(state);
    final path = ApiConstants.validateZipCodeEndpoint(trimmed, stateAbbr);
    try {
      _logZipApi('ZIP Validate API', 'GET', path, null, null);
      final authToken = _storage.read('auth_token');
      final response = await _dio.get(
        path,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );
      _logZipApi('ZIP Validate API', 'GET', path, response.statusCode, response.data);
      if (response.statusCode == 200) {
        final data = response.data;
        final valid = data is Map && (data['valid'] == true || data['isValid'] == true);
        if (!valid) throw LoanOfficerZipCodeServiceException(
          message: (data is Map ? (data['message'] ?? data['error'])?.toString() : null) ?? 'ZIP code is not valid for this state',
          statusCode: response.statusCode,
        );
        return true;
      }
      final msg = response.data is Map ? (response.data['message'] ?? response.data['error'])?.toString() : null;
      throw LoanOfficerZipCodeServiceException(
        message: msg ?? 'ZIP code is not valid for this state',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      _logZipApi('ZIP Validate API', 'GET', path, status, body);
      final msg = body is Map ? (body['message'] ?? body['error'])?.toString() : e.message;
      throw LoanOfficerZipCodeServiceException(
        message: msg ?? 'ZIP code is not valid for this state',
        statusCode: status,
        originalError: e,
      );
    }
  }

  /// Fetches zip codes for a state via GET /api/v1/zip-codes/getstateZip/:country/:state
  /// Used for both agent and loan officer ZIP flows.
  Future<List<LoanOfficerZipCodeModel>> getStateZipCodes(
    String country,
    String state,
  ) async {
    try {
      final stateAbbr = _convertStateNameToAbbreviation(state);
      final endpoint = ApiConstants.getStateZipCodesEndpoint(country, stateAbbr);
      if (kDebugMode) {
        print('🚀 LoanOfficerZipCodeService: getStateZipCodes');
        print('   Endpoint: $endpoint');
      }

      final authToken = _storage.read('auth_token');
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw LoanOfficerZipCodeServiceException(
          message: 'Failed to fetch state ZIP codes: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map) {
        throw LoanOfficerZipCodeServiceException(
          message: 'Invalid response format from getstateZip',
        );
      }

      List<dynamic> raw = [];
      if (data.containsKey('zipCodes') && data['zipCodes'] is List) {
        raw = data['zipCodes'] as List<dynamic>;
      } else if (data.containsKey('results') && data['results'] is List) {
        raw = data['results'] as List<dynamic>;
      }

      final list = <LoanOfficerZipCodeModel>[];
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        try {
          final m = _ensurePostalCode(Map<String, dynamic>.from(e));
          final z = LoanOfficerZipCodeModel.fromJson(m);
          if (z.population >= 10) {
            list.add(z);
            if (kDebugMode && list.length <= 3) {
              // Log first few ZIP codes to verify city is being parsed
              print('   ZIP: ${z.postalCode}, City: ${z.city ?? "null"}, State: ${z.state}');
            }
          }
        } catch (_) {}
      }

      if (kDebugMode) {
        print('✅ getStateZipCodes: ${list.length} zip codes for $stateAbbr');
        final withCity = list.where((z) => z.city != null && z.city!.isNotEmpty).length;
        print('   ZIP codes with city: $withCity / ${list.length}');
      }
      return list;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          e.message ??
          'Failed to fetch state ZIP codes';
      throw LoanOfficerZipCodeServiceException(
        message: msg,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is LoanOfficerZipCodeServiceException) rethrow;
      throw LoanOfficerZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Verifies a 5-digit ZIP via GET /api/v1/zip-codes/:country/:state/:zipcode
  /// Returns list of zip code(s) from API; empty or error → throw.
  Future<List<LoanOfficerZipCodeModel>> verifyZipCode(
    String country,
    String state,
    String zipcode,
  ) async {
    if (!RegExp(r'^\d{5}$').hasMatch(zipcode)) {
      throw LoanOfficerZipCodeServiceException(
        message: 'ZIP code must be exactly 5 digits',
        statusCode: 400,
      );
    }
    try {
      final stateAbbr = _convertStateNameToAbbreviation(state);
      final endpoint = ApiConstants.verifyZipCodeEndpoint(country, stateAbbr, zipcode);
      _logZipApi('ZIP Fetch API', 'GET', endpoint, null, null);

      final authToken = _storage.read('auth_token');
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      _logZipApi('ZIP Fetch API', 'GET', endpoint, response.statusCode, response.data);

      if (response.statusCode != 200) {
        final msg = response.data is Map
            ? (response.data['message'] ?? response.data['error'] ?? 'Invalid or unknown ZIP code')
            : 'Invalid or unknown ZIP code';
        throw LoanOfficerZipCodeServiceException(
          message: msg.toString(),
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map) {
        throw LoanOfficerZipCodeServiceException(
          message: 'Invalid response format',
        );
      }

      List<dynamic> raw = [];
      if (data.containsKey('zipCodes') && data['zipCodes'] is List) {
        raw = data['zipCodes'] as List<dynamic>;
      } else if (data.containsKey('results') && data['results'] is List) {
        raw = data['results'] as List<dynamic>;
      }

      final list = <LoanOfficerZipCodeModel>[];
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        try {
          final m = _ensurePostalCode(Map<String, dynamic>.from(e));
          list.add(LoanOfficerZipCodeModel.fromJson(m));
        } catch (_) {}
      }
      return list;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          e.message ??
          'Invalid or unknown ZIP code';
      throw LoanOfficerZipCodeServiceException(
        message: msg,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is LoanOfficerZipCodeServiceException) rethrow;
      throw LoanOfficerZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Fetches zip codes for loan officers using the new endpoint
  /// GET /api/v1/zip-codes/:country/:state/:userId
  /// Returns only zip codes where claimedByOfficer is false
  /// State is automatically converted to abbreviation if needed
  ///
  /// Throws [LoanOfficerZipCodeServiceException] if the request fails
  Future<List<LoanOfficerZipCodeModel>> getZipCodes(
    String country,
    String state,
    String userId,
  ) async {
    try {
      // Convert state to abbreviation if needed
      final stateAbbreviation = _convertStateNameToAbbreviation(state);
      
      if (kDebugMode) {
        print('🚀 LoanOfficerZipCodeService: Fetching zip codes');
        print('   Country: $country');
        print('   State (original): $state');
        print('   State (abbreviation): $stateAbbreviation');
        print('   UserId: $userId');
      }

      final endpoint = '${ApiConstants.apiBaseUrl}/zip-codes/$country/$stateAbbreviation/$userId';
      
      if (kDebugMode) {
        print('   Endpoint: $endpoint');
      }

      final authToken = _storage.read('auth_token');
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Zip codes response received');
        print('   Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // API returns: { "zipCodes": [...] }
        List<dynamic> zipCodesList = [];
        if (responseData is Map && responseData.containsKey('zipCodes')) {
          zipCodesList = responseData['zipCodes'] as List<dynamic>? ?? [];
        } else if (responseData is List) {
          zipCodesList = responseData;
        }

        if (kDebugMode) {
          print('📦 Response structure:');
          print('   Zip codes count: ${zipCodesList.length}');
        }

        // Include ALL zip codes (claimedByOfficer true and false). When true, show "Join waiting list".
        // Only exclude very low population zips.
        final List<LoanOfficerZipCodeModel> zipCodes = [];
        for (final zipCodeData in zipCodesList) {
          try {
            if (zipCodeData is Map<String, dynamic>) {
              final zipCode = LoanOfficerZipCodeModel.fromJson(zipCodeData);
              if (zipCode.population >= 10) {
                zipCodes.add(zipCode);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Failed to parse zip code: $e');
            }
          }
        }

        if (kDebugMode) {
          print('✅ Parsed ${zipCodes.length} zip codes (includes claimed-by-other for waiting list)');
        }

        return zipCodes;
      } else {
        throw LoanOfficerZipCodeServiceException(
          message: 'Failed to fetch zip codes: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to fetch zip codes';

      throw LoanOfficerZipCodeServiceException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw LoanOfficerZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Claims a zip code for the current loan officer
  ///
  /// Throws [LoanOfficerZipCodeServiceException] if the request fails
  Future<void> claimZipCode(
    String userId,
    String zipcode,
    String price,
    String state,
    String population,
  ) async {
    try {
      if (kDebugMode) {
        print('🚀 LoanOfficerZipCodeService: Claiming zip code');
        print('   UserId: $userId');
        print('   Zipcode: $zipcode');
        print('   Price: $price');
        print('   State: $state');
        print('   Population: $population');
      }

      final authToken = _storage.read('auth_token');
      final response = await _dio.post(
        ApiConstants.zipCodeClaimEndpoint,
        data: {
          'id': userId,
          'zipcode': zipcode,
          'price': price,
          'state': state,
          'population': population,
          'role': 'loanofficer', // Specify role for loan officer
        },
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Zip code claimed successfully');
        print('   Status Code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to claim zip code';

      throw LoanOfficerZipCodeServiceException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw LoanOfficerZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Releases a previously claimed zip code
  ///
  /// Throws [LoanOfficerZipCodeServiceException] if the request fails
  Future<void> releaseZipCode(String userId, String zipcode) async {
    try {
      if (kDebugMode) {
        print('🚀 LoanOfficerZipCodeService: Releasing zip code');
        print('   UserId: $userId');
        print('   Zipcode: $zipcode');
      }

      final authToken = _storage.read('auth_token');
      final response = await _dio.patch(
        ApiConstants.zipCodeReleaseEndpoint,
        data: {
          'id': userId,
          'zipcode': zipcode,
        },
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Zip code released successfully');
        print('   Status Code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ??
          e.message ??
          'Failed to release zip code';

      throw LoanOfficerZipCodeServiceException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw LoanOfficerZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
