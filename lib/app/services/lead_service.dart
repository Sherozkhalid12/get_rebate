import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class LeadService {
  final Dio _dio;

  LeadService() : _dio = Dio() {
    _dio.options.baseUrl = ApiConstants.apiBaseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      ...ApiConstants.ngrokHeaders,
    };
    // Set timeouts to prevent hanging
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
  }

  /// Create a lead (works for both buyer and seller)
  /// 
  /// [leadData] should contain all the fields from the lead form
  /// [leadType] should be 'buyer' or 'seller' to identify the lead type
  /// Returns the created lead data or throws an exception
  Future<Map<String, dynamic>> createLead(
    Map<String, dynamic> leadData, {
    String leadType = 'buyer',
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Creating $leadType lead...');
        print('   URL: ${ApiConstants.createLeadEndpoint}');
        print('   Data: $leadData');
      }

      final response = await _dio.post(
        '/buyer/createLead',
        data: leadData,
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ $leadType lead created successfully');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create $leadType lead: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error creating $leadType lead');
        print('   Status Code: ${e.response?.statusCode ?? "N/A"}');
        print('   Error: ${e.message}');
        print('   Response: ${e.response?.data}');
      }

      // Extract error message from response
      String errorMessage = 'Failed to submit lead form. Please try again.';
      
      if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid form data. Please check all fields and try again.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Please log in to submit a lead.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Agent not found. Please try again.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message']?.toString() ?? 
                        errorData['error']?.toString() ?? 
                        errorMessage;
        } else if (errorData is String) {
          errorMessage = errorData;
        }
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error creating $leadType lead: $e');
        print('   Error type: ${e.runtimeType}');
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Create a buyer lead (deprecated - use createLead instead)
  @Deprecated('Use createLead instead')
  Future<Map<String, dynamic>> createBuyerLead(
    Map<String, dynamic> leadData,
  ) async {
    return createLead(leadData, leadType: 'buyer');
  }

  /// Create a seller lead (deprecated - use createLead instead)
  @Deprecated('Use createLead instead')
  Future<Map<String, dynamic>> createSellerLead(
    Map<String, dynamic> leadData,
  ) async {
    return createLead(leadData, leadType: 'seller');
  }
}

