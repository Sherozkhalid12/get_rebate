import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Custom exception for rebate calculator API errors
class RebateCalculatorApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  RebateCalculatorApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// API response model for rebate calculator
class RebateCalculatorResponse {
  final bool success;
  final String? tier;
  final double? rebatePercentage;
  final double? minRebate;
  final double? maxRebate;
  final double? minCommission;
  final double? maxCommission;
  final List<String>? notes;
  final List<String>? warnings;
  final Map<String, dynamic>? rawData;

  RebateCalculatorResponse({
    required this.success,
    this.tier,
    this.rebatePercentage,
    this.minRebate,
    this.maxRebate,
    this.minCommission,
    this.maxCommission,
    this.notes,
    this.warnings,
    this.rawData,
  });

  factory RebateCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return RebateCalculatorResponse(
      success: json['success'] ?? false,
      tier: json['tier']?.toString(),
      rebatePercentage: json['rebatePercentage'] != null
          ? (json['rebatePercentage'] is num
              ? (json['rebatePercentage'] as num).toDouble()
              : double.tryParse(json['rebatePercentage'].toString()))
          : null,
      minRebate: json['minRebate'] != null
          ? (json['minRebate'] is num
              ? (json['minRebate'] as num).toDouble()
              : double.tryParse(json['minRebate'].toString()))
          : null,
      maxRebate: json['maxRebate'] != null
          ? (json['maxRebate'] is num
              ? (json['maxRebate'] as num).toDouble()
              : double.tryParse(json['maxRebate'].toString()))
          : null,
      minCommission: json['minCommission'] != null
          ? (json['minCommission'] is num
              ? (json['minCommission'] as num).toDouble()
              : double.tryParse(json['minCommission'].toString()))
          : null,
      maxCommission: json['maxCommission'] != null
          ? (json['maxCommission'] is num
              ? (json['maxCommission'] as num).toDouble()
              : double.tryParse(json['maxCommission'].toString()))
          : null,
      notes: json['notes'] != null
          ? (json['notes'] is List
              ? List<String>.from(json['notes'].map((e) => e.toString()))
              : [json['notes'].toString()])
          : null,
      warnings: json['warnings'] != null
          ? (json['warnings'] is List
              ? List<String>.from(json['warnings'].map((e) => e.toString()))
              : [json['warnings'].toString()])
          : null,
      rawData: json,
    );
  }
}

/// Service for handling rebate calculator API calls
class RebateCalculatorApiService {
  late final Dio _dio;

  RebateCalculatorApiService() {
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
      print('❌ Rebate Calculator API Error:');
      print('   Type: ${error.type}');
      print('   Message: ${error.message}');
      print('   Response: ${error.response?.data}');
      print('   Status Code: ${error.response?.statusCode}');
    }
  }

  /// Estimates rebate (Estimated tab)
  /// POST /api/v1/rebate/estimate
  Future<RebateCalculatorResponse> estimateRebate({
    required String price,
    required String commission,
    required String state,
  }) async {
    try {
      if (kDebugMode) {
        print('📡 Rebate Calculator API: Estimating rebate...');
        print('   Price: $price');
        print('   Commission: $commission');
        print('   State: $state');
        print('   URL: ${ApiConstants.rebateEstimateEndpoint}');
      }

      final response = await _dio.post(
        ApiConstants.rebateEstimateEndpoint,
        data: {
          'price': price,
          'commission': commission,
          'state': state.toUpperCase(),
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Rebate estimate response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw RebateCalculatorApiException(
          message: 'Unexpected response format from rebate estimate API.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      return RebateCalculatorResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
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
          final data = e.response?.data;
          if (data is Map<String, dynamic>) {
            errorMessage = data['message']?.toString() ??
                data['error']?.toString() ??
                'Failed to estimate rebate.';
          } else {
            errorMessage = 'Failed to estimate rebate.';
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

      throw RebateCalculatorApiException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is RebateCalculatorApiException) {
        rethrow;
      }

      throw RebateCalculatorApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Calculates exact rebate (Actual tab)
  /// POST /api/v1/rebate/calculate-exact
  Future<RebateCalculatorResponse> calculateExactRebate({
    required String price,
    required String commission,
    required String state,
  }) async {
    try {
      if (kDebugMode) {
        print('📡 Rebate Calculator API: Calculating exact rebate...');
        print('   Price: $price');
        print('   Commission: $commission');
        print('   State: $state');
        print('   URL: ${ApiConstants.rebateCalculateExactEndpoint}');
      }

      final response = await _dio.post(
        ApiConstants.rebateCalculateExactEndpoint,
        data: {
          'price': price,
          'commission': commission,
          'state': state.toUpperCase(),
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Exact rebate calculation response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw RebateCalculatorApiException(
          message: 'Unexpected response format from exact rebate API.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      return RebateCalculatorResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
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
          final data = e.response?.data;
          if (data is Map<String, dynamic>) {
            errorMessage = data['message']?.toString() ??
                data['error']?.toString() ??
                'Failed to calculate exact rebate.';
          } else {
            errorMessage = 'Failed to calculate exact rebate.';
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

      throw RebateCalculatorApiException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is RebateCalculatorApiException) {
        rethrow;
      }

      throw RebateCalculatorApiException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Calculates seller conversion rate (Seller Conversion tab)
  /// POST /api/v1/rebate/calculate-seller-rate
  Future<RebateCalculatorResponse> calculateSellerRate({
    required String price,
    required String commission,
    required String state,
  }) async {
    try {
      if (kDebugMode) {
        print('📡 Rebate Calculator API: Calculating seller rate...');
        print('   Price: $price');
        print('   Commission: $commission');
        print('   State: $state');
        print('   URL: ${ApiConstants.rebateCalculateSellerRateEndpoint}');
      }

      final response = await _dio.post(
        ApiConstants.rebateCalculateSellerRateEndpoint,
        data: {
          'price': price,
          'commission': commission,
          'state': state.toUpperCase(),
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Seller rate calculation response received');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw RebateCalculatorApiException(
          message: 'Unexpected response format from seller rate API.',
          statusCode: response.statusCode,
          originalError: response.data,
        );
      }

      return RebateCalculatorResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
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
          final data = e.response?.data;
          if (data is Map<String, dynamic>) {
            errorMessage = data['message']?.toString() ??
                data['error']?.toString() ??
                'Failed to calculate seller rate.';
          } else {
            errorMessage = 'Failed to calculate seller rate.';
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

      throw RebateCalculatorApiException(
        message: errorMessage,
        statusCode: statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is RebateCalculatorApiException) {
        rethrow;
      }

      throw RebateCalculatorApiException(
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



