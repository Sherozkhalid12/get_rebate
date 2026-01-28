import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for ZIP codes service errors
class ZipCodesServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ZipCodesServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Response model for ZIP codes API
class ZipCodesResponse {
  final int count;
  final List<ZipCodeResult> results;

  ZipCodesResponse({required this.count, required this.results});

  factory ZipCodesResponse.fromJson(Map<String, dynamic> json) {
    return ZipCodesResponse(
      count: json['count'] ?? 0,
      results:
          (json['results'] as List<dynamic>?)
              ?.map(
                (item) => ZipCodeResult.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Converts the API response to a list of ZipCodeModel
  List<ZipCodeModel> toZipCodeModels() {
    final zipCodes = <ZipCodeModel>[];

    for (final result in results) {
      // Each result has multiple postal codes
      // If the API returns individual ZIP code records with IDs, they might be in a different format
      // For now, we'll use the result ID if available (though multiple postal codes share one result)
      for (final postalCode in result.postalCodes) {
        zipCodes.add(
          ZipCodeModel(
            id: result.id,
            zipCode: postalCode,
            state: _getStateCodeFromName(result.state),
            city: result.city.isNotEmpty ? result.city : null,
            population: result.population,
            price: result.price?.toDouble(),
            isAvailable: true,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return zipCodes;
  }

  /// Converts full state name to state code
  String _getStateCodeFromName(String name) {
    final stateMap = {
      'Alabama': 'AL',
      'Alaska': 'AK',
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
      'Iowa': 'IA',
      'Kansas': 'KS',
      'Kentucky': 'KY',
      'Louisiana': 'LA',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Mississippi': 'MS',
      'Missouri': 'MO',
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
      'Oklahoma': 'OK',
      'Oregon': 'OR',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Tennessee': 'TN',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY',
    };
    // If already a code (2 letters), return as is
    if (name.length == 2 && name == name.toUpperCase()) {
      return name;
    }
    return stateMap[name] ?? name;
  }
}

/// Individual ZIP code result from API
class ZipCodeResult {
  final String? id; // MongoDB ID if available
  final String city;
  final List<String> postalCodes;
  final int population;
  final num? price;
  final String state;
  final String country;

  ZipCodeResult({
    this.id,
    required this.city,
    required this.postalCodes,
    required this.population,
    this.price,
    required this.state,
    required this.country,
  });

  factory ZipCodeResult.fromJson(Map<String, dynamic> json) {
    return ZipCodeResult(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      city: json['city'] ?? '',
      postalCodes:
          (json['postalCodes'] as List<dynamic>?)
              ?.map((code) => code.toString())
              .toList() ??
          [],
      population: json['population'] ?? 0,
      price: json['price'],
      state: json['state'] ?? '',
      country: json['country'] ?? 'US',
    );
  }
}

/// Service for handling ZIP codes-related API calls
class ZipCodesService {
  late final Dio _dio;

  /// Converts full state name to state code (helper function)
  static String _getStateCodeFromName(String name) {
    final stateMap = {
      'Alabama': 'AL',
      'Alaska': 'AK',
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
      'Iowa': 'IA',
      'Kansas': 'KS',
      'Kentucky': 'KY',
      'Louisiana': 'LA',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Mississippi': 'MS',
      'Missouri': 'MO',
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
      'Oklahoma': 'OK',
      'Oregon': 'OR',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Tennessee': 'TN',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY',
    };
    // If already a code (2 letters), return as is
    if (name.length == 2 && name == name.toUpperCase()) {
      return name;
    }
    return stateMap[name] ?? name;
  }

  ZipCodesService() {
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

  /// Handles Dio errors and converts them to ZipCodesServiceException
  void _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ ZIP Codes Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Only includes ZIP codes that have a valid population
  ///
  /// Claim status is preserved so callers can show claimed vs available states.
  List<ZipCodeModel> _filterValidZipCodes(List<ZipCodeModel> zipCodes) {
    return zipCodes.where((zip) => zip.population > 0).toList();
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
  /// Returns true if valid. Throws [ZipCodesServiceException] on invalid or error.
  Future<bool> validateZipCode({ required String zipcode, required String state }) async {
    final trimmed = zipcode.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(trimmed)) {
      throw ZipCodesServiceException(message: 'ZIP code must be exactly 5 digits', statusCode: 400);
    }
    if (state.isEmpty) {
      throw ZipCodesServiceException(message: 'State is required', statusCode: 400);
    }
    final stateCode = _getStateCodeFromName(state);
    if (stateCode.length != 2) {
      throw ZipCodesServiceException(message: 'Invalid state', statusCode: 400);
    }

    final path = ApiConstants.validateZipCodeEndpoint(trimmed, stateCode);
    try {
      _logZipApi('ZIP Validate API', 'GET', path, null, null);
      final response = await _dio.get(
        path,
        options: Options(
          headers: { ...ApiConstants.ngrokHeaders, 'Content-Type': 'application/json', 'Accept': 'application/json' },
        ),
      );
      _logZipApi('ZIP Validate API', 'GET', path, response.statusCode, response.data);
      if (response.statusCode == 200) {
        final data = response.data;
        final valid = data is Map && (data['valid'] == true || data['isValid'] == true);
        if (!valid) throw ZipCodesServiceException(
          message: (data is Map ? (data['message'] ?? data['error'])?.toString() : null) ?? 'ZIP code is not valid for this state',
          statusCode: response.statusCode,
        );
        return true;
      }
      final msg = response.data is Map
          ? (response.data['message'] ?? response.data['error'])?.toString()
          : null;
      throw ZipCodesServiceException(
        message: msg ?? 'ZIP code is not valid for this state',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      _logZipApi('ZIP Validate API', 'GET', path, status, body);
      final msg = body is Map
          ? (body['message'] ?? body['error'])?.toString()
          : e.message;
      throw ZipCodesServiceException(
        message: msg ?? 'ZIP code is not valid for this state',
        statusCode: status,
        originalError: e,
      );
    }
  }

  /// Fetches ZIP codes within X miles of searched zip via GET /api/v1/zip-codes/within10miles/:zipcode/:miles
  /// Returns map of postalCode -> distanceMiles (for filtering + sorting agents/LOs by proximity)
  Future<Map<String, double>> getZipCodesWithinMiles({
    required String zipcode,
    int miles = 10,
  }) async {
    final trimmed = zipcode.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(trimmed)) {
      throw ZipCodesServiceException(
        message: 'ZIP code must be exactly 5 digits',
        statusCode: 400,
      );
    }
    final path = ApiConstants.within10MilesEndpoint(trimmed, miles.toString());
    try {
      _logZipApi('ZIP Within10Miles API', 'GET', path, null, null);
      final response = await _dio.get(
        path,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      _logZipApi('ZIP Within10Miles API', 'GET', path, response.statusCode, response.data);
      if (response.statusCode != 200) {
        throw ZipCodesServiceException(
          message: 'Failed to fetch zip codes within $miles miles: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ZipCodesServiceException(
          message: 'Invalid response format from within10miles',
          statusCode: response.statusCode,
        );
      }
      final raw = data['zipCodes'];
      if (raw is! List) {
        return {};
      }
      final map = <String, double>{};
      for (final e in raw) {
        if (e is! Map) continue;
        final pc = e['postalCode']?.toString().trim();
        if (pc == null || pc.isEmpty) continue;
        final d = e['distanceMiles'];
        final dist = d is num ? d.toDouble() : (d is String ? double.tryParse(d) : null);
        map[pc] = dist ?? 0.0;
      }
      if (kDebugMode) {
        print('   Parsed ${map.length} zips within ${miles}mi of $trimmed');
      }
      return map;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          e.message ??
          'Failed to fetch zip codes within $miles miles';
      throw ZipCodesServiceException(
        message: msg,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// Fetches ZIP codes for a state via GET /api/v1/zip-codes/getstateZip/:country/:state
  ///
  /// [country] e.g. "US", [state] e.g. "CA" or "California"
  /// Throws [ZipCodesServiceException] on failure
  Future<List<ZipCodeModel>> getStateZipCodes({
    String country = 'US',
    required String state,
  }) async {
    if (state.isEmpty) {
      throw ZipCodesServiceException(
        message: 'State cannot be empty',
        statusCode: 400,
      );
    }
    final stateCode = _getStateCodeFromName(state);
    if (stateCode.length != 2) {
      throw ZipCodesServiceException(
        message: 'Invalid state. Use code (e.g. CA) or full name.',
        statusCode: 400,
      );
    }

    try {
      final endpoint = ApiConstants.getStateZipCodesEndpoint(country, stateCode);
      if (kDebugMode) {
        print('📡 ZipCodesService: getStateZipCodes');
        print('   Endpoint: $endpoint');
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
        print('✅ getStateZipCodes response: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        throw ZipCodesServiceException(
          message: 'Failed to fetch state ZIP codes: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ZipCodesServiceException(
          message: 'Invalid response format from getstateZip',
          statusCode: response.statusCode,
        );
      }

      List<dynamic> raw = [];
      if (data.containsKey('zipCodes') && data['zipCodes'] is List) {
        raw = data['zipCodes'] as List<dynamic>;
      } else if (data.containsKey('results') && data['results'] is List) {
        raw = data['results'] as List<dynamic>;
      }

      final list = <ZipCodeModel>[];
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        try {
          final z = ZipCodeModel.fromJson(e);
          if (z.population > 0) list.add(z);
        } catch (_) {}
      }

      if (kDebugMode) {
        print('   Parsed ${list.length} ZIP codes for state $stateCode');
      }
      return list;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          e.message ??
          'Failed to fetch state ZIP codes';
      throw ZipCodesServiceException(
        message: msg,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ZipCodesServiceException) rethrow;
      throw ZipCodesServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Fetches ZIP code data for a given country, state and ZIP code
  ///
  /// [country] should be "US" (default)
  /// [state] should be a state code (e.g., "CA", "NY")
  /// [zipcode] must be a 5-digit ZIP code string
  ///
  /// Throws [ZipCodesServiceException] if the request fails
  Future<List<ZipCodeModel>> getZipCodesByState({
    String country = 'US',
    required String state,
    required String zipcode,
  }) async {
    if (state.isEmpty) {
      throw ZipCodesServiceException(
        message: 'State cannot be empty',
        statusCode: 400,
      );
    }
    if (zipcode.isEmpty) {
      throw ZipCodesServiceException(
        message: 'ZIP code is required',
        statusCode: 400,
      );
    }
    if (!RegExp(r'^\d{5}$').hasMatch(zipcode)) {
      throw ZipCodesServiceException(
        message: 'Invalid ZIP code format. ZIP code must be exactly 5 digits.',
        statusCode: 400,
      );
    }

    try {
      final endpoint = ApiConstants.verifyZipCodeEndpoint(country, state, zipcode);
      _logZipApi('ZIP Fetch API', 'GET', endpoint, null, null);

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

      _logZipApi('ZIP Fetch API', 'GET', endpoint, response.statusCode, response.data);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('zipCodes')) {
            final zipCodesList = data['zipCodes'];
            if (zipCodesList is List && zipCodesList.isNotEmpty) {
              final parsed = zipCodesList
                  .whereType<Map<String, dynamic>>()
                  .map((zipJson) => ZipCodeModel.fromJson(zipJson))
                  .toList();

              if (kDebugMode) {
                print(
                  '🛰️ Parsed ${parsed.length} ZIP codes from new api.zipCodes payload',
                );
              }

              final filtered = _filterValidZipCodes(parsed);
              if (kDebugMode) {
                print(
                  '   Filtered to ${filtered.length} ZIP codes with population>0',
                );
              }
              return filtered;
            }
          }

          // Check if results is a list of individual ZIP code objects (each with its own ID)
          final results = data['results'];
          if (results is List && results.isNotEmpty) {
            final firstResult = results[0];
            // Check if each result is an individual ZIP code (has zipcode/zipCode field directly)
            if (firstResult is Map &&
                (firstResult.containsKey('zipcode') ||
                    firstResult.containsKey('zipCode') ||
                    firstResult.containsKey('postalCodes'))) {
              // Handle two possible formats:
              // 1. Individual ZIP code objects (each with ID)
              // 2. City-grouped objects (with postalCodes array)

              final zipCodes = <ZipCodeModel>[];
              for (final item in results) {
                if (item is Map<String, dynamic>) {
                  // Check if it's an individual ZIP code object
                  if (item.containsKey('zipcode') ||
                      item.containsKey('zipCode')) {
                    // Individual ZIP code object - parse directly
                    if (kDebugMode) {
                      print(
                        '   Parsing individual ZIP code: ${item['zipcode'] ?? item['zipCode']}',
                      );
                      print(
                        '      Has _id: ${item.containsKey('_id')}, value: ${item['_id']}',
                      );
                      print(
                        '      Has id: ${item.containsKey('id')}, value: ${item['id']}',
                      );
                    }
                    final zipCode = ZipCodeModel.fromJson(item);
                    if (kDebugMode && zipCode.id == null) {
                      print(
                        '   ⚠️ WARNING: ZIP code ${zipCode.zipCode} parsed without ID!',
                      );
                      print('      Item keys: ${item.keys.toList()}');
                    }
                    zipCodes.add(zipCode);
                  } else if (item.containsKey('postalCodes')) {
                    // City-grouped object - extract individual ZIP codes
                    if (kDebugMode) {
                      print(
                        '   Parsing city-grouped object with ID: ${item['_id'] ?? item['id']}',
                      );
                    }
                    final zipCodeResult = ZipCodeResult.fromJson(item);
                    final stateCode = ZipCodesService._getStateCodeFromName(
                      zipCodeResult.state,
                    );
                    for (final postalCode in zipCodeResult.postalCodes) {
                      if (kDebugMode && zipCodeResult.id == null) {
                        print(
                          '   ⚠️ WARNING: City-grouped object has no ID for postal codes!',
                        );
                      }
                      zipCodes.add(
                        ZipCodeModel(
                          id: zipCodeResult.id,
                          zipCode: postalCode,
                          state: stateCode,
                          city: zipCodeResult.city.isNotEmpty ? zipCodeResult.city : null,
                          population: zipCodeResult.population,
                          price: zipCodeResult.price?.toDouble(),
                          isAvailable: true,
                          createdAt: DateTime.now(),
                        ),
                      );
                    }
                  }
                }
              }

              if (kDebugMode) {
                print('✅ Converted ${zipCodes.length} ZIP codes from API');
                if (zipCodes.isNotEmpty) {
                  print('   First ZIP code ID: ${zipCodes[0].id ?? "NULL"}');
                  print('   First ZIP code: ${zipCodes[0].zipCode}');
                  // Count how many have IDs
                  final withIds = zipCodes
                      .where((z) => z.id != null && z.id!.isNotEmpty)
                      .length;
                  final withoutIds = zipCodes.length - withIds;
                  print('   ZIP codes with IDs: $withIds');
                  print('   ZIP codes without IDs: $withoutIds');
                  if (withoutIds > 0) {
                    print('   ⚠️ WARNING: Some ZIP codes are missing IDs!');
                  }
                }
              }

              final filtered = _filterValidZipCodes(zipCodes);
              if (kDebugMode) {
                print(
                  '   Filtered to ${filtered.length} ZIP codes with population>0',
                );
              }
              return filtered;
            }
          }

          // Fallback to original parsing logic
          final zipCodesResponse = ZipCodesResponse.fromJson(data);
          final zipCodes = zipCodesResponse.toZipCodeModels();

          if (kDebugMode) {
            print(
              '✅ Converted ${zipCodes.length} ZIP codes from API (using fallback)',
            );
            if (zipCodes.isNotEmpty) {
              print('   First ZIP code ID: ${zipCodes[0].id}');
              print('   First ZIP code: ${zipCodes[0].zipCode}');
            }
          }

          final filtered = _filterValidZipCodes(zipCodes);
          if (kDebugMode) {
            print(
              '   Filtered to ${filtered.length} ZIP codes with population>0',
            );
          }
          return filtered;
        } else {
          throw ZipCodesServiceException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ZipCodesServiceException(
          message: 'Failed to fetch ZIP codes: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException in getZipCodesByState:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Error: ${e.error}');
        print('   Request path: ${e.requestOptions.path}');
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage =
            e.response!.data?['message']?.toString() ??
            e.response!.data?['error']?.toString() ??
            'Failed to fetch ZIP codes';

        throw ZipCodesServiceException(
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
        }

        throw ZipCodesServiceException(message: errorMsg, originalError: e);
      }
    } catch (e) {
      if (e is ZipCodesServiceException) {
        rethrow;
      }
      throw ZipCodesServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
