import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/zip_code_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for zip code service errors
class ZipCodeServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ZipCodeServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling zip code-related API calls
class ZipCodeService {
  late final Dio _dio;

  ZipCodeService() {
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
      print('❌ Zip Code Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Converts full state name to two-letter abbreviation
  /// Returns the original string if conversion fails
  /// Only includes states where rebates are allowed
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

    // If already an abbreviation (2 letters), return as-is
    if (stateName.length == 2) {
      return stateName.toUpperCase();
    }

    // Try to find the abbreviation
    return stateMap[stateName] ?? stateName;
  }

  /// Fetches all available zip codes for a given country and state
  ///
  /// Throws [ZipCodeServiceException] if the request fails
  Future<List<ZipCodeModel>> getZipCodes(String country, String state) async {
    try {
      if (kDebugMode) {
        print('🚀 ZipCodeService: Fetching zip codes');
        print('   Country: $country');
        print('   State: $state');
        print('   Endpoint: ${ApiConstants.getZipCodesEndpoint(country, state)}');
      }

      final response = await _dio.get(
        ApiConstants.getZipCodesEndpoint(country, state),
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Zip codes response received');
        print('   Status Code: ${response.statusCode}');
      }

      // Parse the API response structure: { count: number, results: [...] }
      final responseMap = response.data as Map<String, dynamic>;
      final results = responseMap['results'] as List<dynamic>? ?? [];

      if (kDebugMode) {
        print('📦 Response structure:');
        print('   Count: ${responseMap['count'] ?? 0}');
        print('   Results (cities): ${results.length}');
      }

      // Flatten the response: each city has multiple postalCodes
      // Optimized for large datasets (1864+ items)
      final List<ZipCodeModel> zipCodes = [];
      final now = DateTime.now(); // Cache DateTime to avoid repeated calls
      int processedCount = 0;

      for (final cityData in results) {
        try {
          final cityMap = cityData as Map<String, dynamic>;
          final postalCodes = cityMap['postalCodes'] as List<dynamic>? ?? [];

          if (postalCodes.isEmpty) continue; // Skip cities with no postal codes

          final population = (cityMap['population'] as num?)?.toInt() ?? 0;
          final price = (cityMap['price'] as num?)?.toDouble();
          final stateFullName = cityMap['state'] as String? ?? '';

          // Convert full state name to abbreviation (e.g., "California" -> "CA")
          final stateAbbr = _convertStateNameToAbbreviation(stateFullName);

          if (kDebugMode && processedCount == 0) {
            final city = cityMap['city'] as String? ?? '';
            print('   Sample city: $city, State: $stateFullName ($stateAbbr), Postal codes: ${postalCodes.length}');
          }

          // Create a ZipCodeModel for each postal code (optimized batch processing)
          for (final postalCode in postalCodes) {
            try {
              final zipCodeStr = postalCode.toString().trim();

              if (zipCodeStr.isNotEmpty && zipCodeStr.length >= 5) { // Valid zip codes are at least 5 digits
                zipCodes.add(
                  ZipCodeModel(
                    zipCode: zipCodeStr,
                    state: stateAbbr,
                    population: population,
                    price: price,
                    isAvailable: true,
                    createdAt: now, // Use cached DateTime
                    searchCount: 0,
                  ),
                );
                processedCount++;
              }
            } catch (e) {
              if (kDebugMode && processedCount < 5) {
                print('⚠️ Failed to create zip code model for $postalCode: $e');
              }
              // Continue processing other zip codes
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to process city data: $e');
          }
          // Continue processing other cities
        }
      }

      if (kDebugMode) {
        print('✅ Parsed ${zipCodes.length} zip codes from ${results.length} cities');
      }

      return zipCodes;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ??
          e.message ??
          'Failed to fetch zip codes';

      throw ZipCodeServiceException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw ZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Claims a zip code for the current loan officer
  ///
  /// Required body: { id, zipcode, price, state, population }
  ///
  /// Throws [ZipCodeServiceException] if the request fails
  Future<void> claimZipCode(String id, String zipcode, String price, String state, String population) async {
    try {
      if (kDebugMode) {
        print('🚀 ZipCodeService: Claiming zip code');
        print('   ID: $id');
        print('   Zipcode: $zipcode');
        print('   Price: $price');
        print('   State: $state');
        print('   Population: $population');
      }

      final response = await _dio.post(
        ApiConstants.zipCodeClaimEndpoint,
        data: {
          'id': id,
          'zipcode': zipcode,
          'price': price,
          'state': state,
          'population': population,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
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

      throw ZipCodeServiceException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw ZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Releases a previously claimed zip code
  ///
  /// Throws [ZipCodeServiceException] if the request fails
  Future<void> releaseZipCode(String id, String zipcode) async {
    try {
      if (kDebugMode) {
        print('🚀 ZipCodeService: Releasing zip code');
        print('   ID: $id');
        print('   Zipcode: $zipcode');
      }

      final response = await _dio.patch(
        ApiConstants.zipCodeReleaseEndpoint,
        data: {
          'id': id,
          'zipcode': zipcode,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
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

      throw ZipCodeServiceException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw ZipCodeServiceException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

