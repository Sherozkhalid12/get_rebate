import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class ReviewServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ReviewServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ReviewService {
  final Dio _dio = Dio();

  /// Submit a review and rating for an agent
  /// 
  /// POST {{server}}/api/v1/buyer/addReview
  /// {
  ///   "currentUserId": "693a903e9a5af92010b20123",
  ///   "agentId": "6918628fb08c1ffea0a43f2b",
  ///   "rating": 5,
  ///   "review": "Excellent service! Highly recommended."
  /// }
  Future<Map<String, dynamic>> submitReview({
    required String currentUserId,
    required String agentId,
    required int rating, // 1-5
    required String review,
    String? proposalId, // Optional: link review to a specific proposal
  }) async {
    try {
      if (kDebugMode) {
        print('⭐ Submitting review...');
        print('   User: $currentUserId');
        print('   Agent: $agentId');
        print('   Rating: $rating/5');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/buyer/addReview',
        data: {
          'currentUserId': currentUserId,
          'agentId': agentId,
          'rating': rating,
          'review': review,
          if (proposalId != null) 'proposalId': proposalId,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Review submitted successfully');
      }

      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      } else {
        return {'success': true, 'message': 'Review submitted successfully'};
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ReviewServiceException(
        message: 'Failed to submit review: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Submit a review and rating for a loan officer
  Future<Map<String, dynamic>> submitLoanOfficerReview({
    required String currentUserId,
    required String loanOfficerId,
    required int rating, // 1-5
    required String review,
    String? proposalId, // Optional: link review to a specific proposal
  }) async {
    try {
      if (kDebugMode) {
        print('⭐ Submitting loan officer review...');
        print('   User: $currentUserId');
        print('   Loan Officer: $loanOfficerId');
        print('   Rating: $rating/5');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/loan-officers/$loanOfficerId/reviews',
        data: {
          'currentUserId': currentUserId,
          'rating': rating,
          'review': review,
          if (proposalId != null) 'proposalId': proposalId,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Review submitted successfully');
      }

      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      } else {
        return {'success': true, 'message': 'Review submitted successfully'};
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ReviewServiceException(
        message: 'Failed to submit review: ${e.toString()}',
        originalError: e,
      );
    }
  }

  ReviewServiceException _handleDioError(DioException e) {
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
                        'Failed to submit review.';
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

    return ReviewServiceException(
      message: errorMessage,
      statusCode: statusCode,
      originalError: e,
    );
  }
}



