import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';

/// Custom exception for loan officer service errors
class LoanOfficerServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  LoanOfficerServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Service for handling loan officer-related API calls
class LoanOfficerService {
  late final Dio _dio;

  LoanOfficerService() {
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

    // Add interceptors for error handling and auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Automatically add auth token to all requests
          try {
            if (Get.isRegistered<AuthController>()) {
              final authController = Get.find<AuthController>();
              final token = authController.token;
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
                if (kDebugMode) {
                  print('🔑 LoanOfficerService: Added auth token to request');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ LoanOfficerService: Could not add auth token: $e');
            }
          }
          
          // Add ngrok headers if needed
          options.headers.addAll(ApiConstants.ngrokHeaders);
          
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
      print('❌ Loan Officer Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Request URL: ${error.requestOptions.uri}');
      print('   Request Headers: ${error.requestOptions.headers}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
      print('   Error: ${error.error}');
      print('   Stack Trace: ${error.stackTrace}');
    }
  }

  /// Fetches all loan officers from the API
  /// 
  /// Throws [LoanOfficerServiceException] if the request fails
  Future<List<LoanOfficerModel>> getAllLoanOfficers() async {
    try {
      final response = await _dio.get(
        ApiConstants.allLoanOfficersEndpoint,
      );

      if (kDebugMode) {
        print('✅ Loan officers response received');
        print('   Status Code: ${response.statusCode}');
      }

      // Handle different response formats
      List<dynamic> loanOfficersData;
      
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        // Check for the format with 'success' and 'loanOfficers'
        if (responseMap['success'] == true && responseMap['loanOfficers'] != null) {
          loanOfficersData = responseMap['loanOfficers'] as List<dynamic>;
        } else if (responseMap['data'] != null) {
          loanOfficersData = responseMap['data'] as List<dynamic>;
        } else if (responseMap['loanOfficers'] != null) {
          loanOfficersData = responseMap['loanOfficers'] as List<dynamic>;
        } else {
          loanOfficersData = [];
        }
      } else if (response.data is List) {
        loanOfficersData = response.data as List<dynamic>;
      } else {
        loanOfficersData = [];
      }

      final loanOfficers = <LoanOfficerModel>[];
      
      for (int i = 0; i < loanOfficersData.length; i++) {
        try {
          final json = loanOfficersData[i];
          
          // Skip if not a Map
          if (json is! Map<String, dynamic>) {
            if (kDebugMode) {
              print('⚠️ Skipping loan officer at index $i: expected Map but got ${json.runtimeType}');
            }
            continue;
          }
          
          final loanOfficer = LoanOfficerModel.fromJson(json);
          loanOfficers.add(loanOfficer);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing loan officer at index $i: $e');
            print('   Data: ${loanOfficersData[i]}');
          }
          // Continue to next loan officer instead of failing completely
        }
      }

      if (kDebugMode) {
        print('✅ Successfully parsed ${loanOfficers.length} loan officers');
      }

      return loanOfficers;
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
            errorMessage = 'Loan officers endpoint not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            errorMessage = e.response?.data?['message']?.toString() ?? 
                          e.response?.data?['error']?.toString() ?? 
                          'Failed to fetch loan officers.';
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

      throw LoanOfficerServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is LoanOfficerServiceException) {
        rethrow;
      }

      throw LoanOfficerServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Fetches the currently authenticated loan officer by ID
  /// 
  /// Calls `/api/v1/loan-officers/{id}` and returns a single [LoanOfficerModel]
  /// from the `loanOfficer` field in the response.
  /// 
  /// Throws [LoanOfficerServiceException] if the request fails.
  Future<LoanOfficerModel> getCurrentLoanOfficer(String loanOfficerId) async {
    try {
      final endpoint = ApiConstants.getLoanOfficerByIdEndpoint(loanOfficerId);
      
      if (kDebugMode) {
        print('📡 Fetching current loan officer from API...');
        print('   ID: $loanOfficerId');
        print('   Endpoint: $endpoint');
        print('   Base URL: ${_dio.options.baseUrl}');
        
        // Check if auth token is available
        try {
          if (Get.isRegistered<AuthController>()) {
            final authController = Get.find<AuthController>();
            final token = authController.token;
            if (token != null && token.isNotEmpty) {
              print('   Auth Token: Present (${token.substring(0, 10)}...)');
            } else {
              print('   ⚠️ Auth Token: Missing or empty');
            }
          } else {
            print('   ⚠️ AuthController: Not registered');
          }
        } catch (e) {
          print('   ⚠️ Could not check auth token: $e');
        }
      }

      final response = await _dio.get(endpoint);

      if (kDebugMode) {
        print('✅ Current loan officer response received');
        print('   Status Code: ${response.statusCode}');
        print('   Raw Response: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw LoanOfficerServiceException(
          message: 'Unexpected response format when fetching current loan officer.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      final Map<String, dynamic> responseMap =
          response.data as Map<String, dynamic>;

      // Expecting: { success: true, loanOfficer: { ... } }
      final dynamic loanOfficerJson = responseMap['loanOfficer'] ?? responseMap['data'];

      if (loanOfficerJson == null || loanOfficerJson is! Map<String, dynamic>) {
        throw LoanOfficerServiceException(
          message: 'Loan officer data not found in response.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      try {
        final loanOfficer =
            LoanOfficerModel.fromJson(loanOfficerJson as Map<String, dynamic>);

        // Build full URLs for profile picture and company logo
        final loanOfficerWithUrls = _buildImageUrls(loanOfficer);

        if (kDebugMode) {
          print('✅ Successfully parsed current loan officer: ${loanOfficerWithUrls.id}');
          print('   Profile Image URL: ${loanOfficerWithUrls.profileImage ?? "Not set"}');
          print('   Company Logo URL: ${loanOfficerWithUrls.companyLogoUrl ?? "Not set"}');
        }

        return loanOfficerWithUrls;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error parsing current loan officer: $e');
          print('   Data: $loanOfficerJson');
        }

        throw LoanOfficerServiceException(
          message: 'Failed to parse current loan officer data.',
          statusCode: response.statusCode,
          originalError: e,
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      int? statusCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Connection timeout. Please check your internet connection.';
          statusCode = 408;
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Cannot connect to server. Please ensure the server is running.';
          break;
        case DioExceptionType.badResponse:
          statusCode = e.response?.statusCode;
          if (statusCode == 404) {
            errorMessage = 'Loan officer not found.';
          } else if (statusCode == 401) {
            errorMessage = 'Unauthorized. Please login again.';
          } else if (statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else {
            final data = e.response?.data;
            if (data is Map<String, dynamic>) {
              errorMessage = data['message']?.toString() ??
                  data['error']?.toString() ??
                  'Failed to fetch current loan officer.';
            } else {
              errorMessage = 'Failed to fetch current loan officer.';
            }
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

      throw LoanOfficerServiceException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is LoanOfficerServiceException) {
        rethrow;
      }

      throw LoanOfficerServiceException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Builds full URLs for profile images
  LoanOfficerModel _buildImageUrls(LoanOfficerModel loanOfficer) {
    String? profileImage = loanOfficer.profileImage;
    if (profileImage != null && profileImage.isNotEmpty) {
      if (!profileImage.startsWith('http://') && !profileImage.startsWith('https://')) {
        // Build full URL with base URL
        final baseUrl = ApiConstants.baseUrl;
        profileImage = profileImage.startsWith('/') 
            ? '$baseUrl$profileImage'
            : '$baseUrl/$profileImage';
      }
    }

    String? companyLogoUrl = loanOfficer.companyLogoUrl;
    if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) {
      if (!companyLogoUrl.startsWith('http://') && !companyLogoUrl.startsWith('https://')) {
        // Build full URL with base URL
        final baseUrl = ApiConstants.baseUrl;
        companyLogoUrl = companyLogoUrl.startsWith('/')
            ? '$baseUrl$companyLogoUrl'
            : '$baseUrl/$companyLogoUrl';
      }
    }

    return loanOfficer.copyWith(
      profileImage: profileImage,
      companyLogoUrl: companyLogoUrl,
    );
  }

  /// Disposes the Dio instance
  void dispose() {
    _dio.close();
  }
}







