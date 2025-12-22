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
    // Handle nested structure: check if data is in 'estimate' object
    Map<String, dynamic>? estimateData;
    if (json.containsKey('estimate') && json['estimate'] is Map<String, dynamic>) {
      estimateData = json['estimate'] as Map<String, dynamic>;
    } else {
      // Fallback: use top-level data if no 'estimate' key
      estimateData = json;
    }

    // Extract rebate range from nested structure
    double? minRebate;
    String? maxRebateStr;
    if (estimateData.containsKey('estimatedRebateRange')) {
      final range = estimateData['estimatedRebateRange'];
      if (range is Map<String, dynamic>) {
        minRebate = range['min'] != null
            ? (range['min'] is num
                ? (range['min'] as num).toDouble()
                : double.tryParse(range['min'].toString()))
            : null;
        maxRebateStr = range['max']?.toString();
      }
    } else if (estimateData.containsKey('minRebate')) {
      minRebate = estimateData['minRebate'] != null
          ? (estimateData['minRebate'] is num
              ? (estimateData['minRebate'] as num).toDouble()
              : double.tryParse(estimateData['minRebate'].toString()))
          : null;
    }

    // Handle maxRebate - could be "or more" string or number
    double? maxRebate;
    if (maxRebateStr != null) {
      if (maxRebateStr.toLowerCase().contains('more') || 
          maxRebateStr.toLowerCase().contains('or')) {
        maxRebate = null; // Will be handled as "or more" in UI
      } else {
        maxRebate = double.tryParse(maxRebateStr);
      }
    } else if (estimateData.containsKey('maxRebate')) {
      final maxVal = estimateData['maxRebate'];
      if (maxVal is String && (maxVal.toLowerCase().contains('more') || 
          maxVal.toLowerCase().contains('or'))) {
        maxRebate = null;
      } else {
        maxRebate = maxVal != null
            ? (maxVal is num
                ? (maxVal as num).toDouble()
                : double.tryParse(maxVal.toString()))
            : null;
      }
    }

    // Extract commission range from nested structure
    double? minCommission;
    double? maxCommission;
    if (estimateData.containsKey('commissionRangeForTier')) {
      final range = estimateData['commissionRangeForTier'];
      if (range is Map<String, dynamic>) {
        minCommission = range['min'] != null
            ? (range['min'] is num
                ? (range['min'] as num).toDouble()
                : double.tryParse(range['min'].toString()))
            : null;
        maxCommission = range['max'] != null
            ? (range['max'] is num
                ? (range['max'] as num).toDouble()
                : double.tryParse(range['max'].toString()))
            : null;
      }
    } else {
      minCommission = estimateData['minCommission'] != null
          ? (estimateData['minCommission'] is num
              ? (estimateData['minCommission'] as num).toDouble()
              : double.tryParse(estimateData['minCommission'].toString()))
          : null;
      maxCommission = estimateData['maxCommission'] != null
          ? (estimateData['maxCommission'] is num
              ? (estimateData['maxCommission'] as num).toDouble()
              : double.tryParse(estimateData['maxCommission'].toString()))
          : null;
    }

    return RebateCalculatorResponse(
      success: json['success'] ?? false,
      tier: estimateData['tier']?.toString(),
      rebatePercentage: estimateData['rebatePercentage'] != null
          ? (estimateData['rebatePercentage'] is num
              ? (estimateData['rebatePercentage'] as num).toDouble()
              : double.tryParse(estimateData['rebatePercentage'].toString()))
          : null,
      minRebate: minRebate,
      maxRebate: maxRebate,
      minCommission: minCommission,
      maxCommission: maxCommission,
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



