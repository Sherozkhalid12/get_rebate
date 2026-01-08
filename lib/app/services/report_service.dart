import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class ReportServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ReportServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ReportService {
  final Dio _dio = Dio();

  /// Submit a report about a user or service issue
  /// 
  /// POST {{server}}/api/v1/reports
  /// {
  ///   "reporterId": "64f0a2b1c2d3e4f567890456",
  ///   "reportedUserId": "69146a3eb4a7200ab915b7be",
  ///   "reason": "Very rude behavior",
  ///   "description": "The agent repeatedly delivered the order late on multiple occasions."
  /// }
  Future<Map<String, dynamic>> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
    String? proposalId, // Optional: link report to a specific proposal
  }) async {
    try {
      if (kDebugMode) {
        print('📋 Submitting report...');
        print('   Reporter: $reporterId');
        print('   Reported User: $reportedUserId');
        print('   Reason: $reason');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/reports',
        data: {
          'reporterId': reporterId,
          'reportedUserId': reportedUserId,
          'reason': reason,
          'description': description,
          if (proposalId != null) 'proposalId': proposalId,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Report submitted successfully');
      }

      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      } else {
        return {'success': true, 'message': 'Report submitted successfully'};
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ReportServiceException(
        message: 'Failed to submit report: ${e.toString()}',
        originalError: e,
      );
    }
  }

  ReportServiceException _handleDioError(DioException e) {
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
        if (statusCode == 400) {
          errorMessage = e.response?.data?['message']?.toString() ?? 
                        'Invalid request. Please check your input.';
        } else if (statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = e.response?.data?['message']?.toString() ?? 
                        e.response?.data?['error']?.toString() ?? 
                        'Failed to submit report.';
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

    return ReportServiceException(
      message: errorMessage,
      statusCode: statusCode,
      originalError: e,
    );
  }
}



