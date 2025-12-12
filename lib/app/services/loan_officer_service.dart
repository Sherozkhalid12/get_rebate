import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

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
      print('❌ Loan Officer Service Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Fetches all loan officers from the API
  /// 
  /// Throws [LoanOfficerServiceException] if the request fails
  Future<List<LoanOfficerModel>> getAllLoanOfficers() async {
    try {
      if (kDebugMode) {
        print('📡 Fetching all loan officers from API...');
        print('   URL: ${ApiConstants.allLoanOfficersEndpoint}');
      }

      final response = await _dio.get(
        ApiConstants.allLoanOfficersEndpoint,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
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

  /// Disposes the Dio instance
  void dispose() {
    _dio.close();
  }
}


