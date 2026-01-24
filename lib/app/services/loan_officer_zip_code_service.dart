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

    // If already an abbreviation (2 letters), return as-is (uppercase)
    if (stateName.length == 2) {
      return stateName.toUpperCase();
    }

    // Try to find the abbreviation
    return stateMap[stateName] ?? stateName.toUpperCase();
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
