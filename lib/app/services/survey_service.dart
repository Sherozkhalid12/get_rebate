import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getrebate/app/utils/api_constants.dart';

/// Service for handling survey-related API calls
class SurveyService {
  late final Dio _dio;
  final _storage = GetStorage();

  SurveyService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...ApiConstants.ngrokHeaders,
        },
      ),
    );
    
    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authToken = _storage.read('auth_token');
          if (authToken != null && authToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  /// Submit post-closing survey
  /// 
  /// [userId] - The user ID who is submitting the survey
  /// [rebateFromAgent] - Rebate amount received
  /// [receivedExpectedRebate] - Whether expected rebate was received
  /// [rebateAppliedAsCreditClosing] - How rebate was applied
  /// [signedRebateDisclosure] - Whether rebate disclosure was signed
  /// [receivingRebateEasy] - Ease of receiving rebate
  /// [agentRecommended] - Whether agent is recommended
  /// [comment] - Additional comments
  /// [rating] - Overall rating (0-5)
  /// 
  /// Returns true if successful, throws exception on error
  Future<bool> submitSurvey({
    required String userId,
    required double rebateFromAgent,
    required String receivedExpectedRebate,
    required String rebateAppliedAsCreditClosing,
    required String signedRebateDisclosure,
    required String receivingRebateEasy,
    required String agentRecommended,
    String? comment,
    required double rating,
    String? surveyType,
    String? type,
    String? professionalId,
    String? professionalType,
    double? loSatisfaction,
    String? loExplainedOptions,
    String? loCommunication,
    String? loRebateHelp,
    String? loEase,
    String? loProfessional,
    String? loClosedOnTime,
    String? loRecommend,
  }) async {
    try {
      final authToken = _storage.read('auth_token');
      final normalizedSurveyType = (surveyType ?? type ?? '')
          .toLowerCase()
          .replaceAll('_', '')
          .replaceAll(' ', '');
      final isLoanOfficerSurvey = normalizedSurveyType == 'loanofficer';

      final requestBody = isLoanOfficerSurvey
          ? {
              'userId': userId,
              'loSatisfaction': loSatisfaction ?? rating,
              'loExplainedOptions': loExplainedOptions ?? '',
              'loCommunication': loCommunication ?? '',
              'loRebateHelp': loRebateHelp ?? '',
              'loEase': loEase ?? '',
              'loProfessional': loProfessional ?? '',
              'loClosedOnTime': loClosedOnTime ?? '',
              'loRecommend': loRecommend ?? '',
              'rating': rating,
            }
          : {
              'userId': userId,
              'rebateFromAgent': rebateFromAgent,
              'receivedExpectedRebate': receivedExpectedRebate,
              'rebateAppliedAsCreditClosing': rebateAppliedAsCreditClosing,
              'signedRebateDisclosure': signedRebateDisclosure,
              'receivingRebateEasy': receivingRebateEasy,
              'agentRecommended': agentRecommended,
              if (comment != null && comment.isNotEmpty) 'comment': comment,
              'rating': rating,
            };

      final endpoint = isLoanOfficerSurvey
          ? '/survey/submitLoanSurvey'
          : '/survey/submit';

      print('📡 Submitting survey (${isLoanOfficerSurvey ? "loan officer" : "agent"})');
      print(
        '   Endpoint: ${isLoanOfficerSurvey ? ApiConstants.submitLoanSurveyEndpoint : ApiConstants.submitSurveyEndpoint}',
      );
      print('   Request body: $requestBody');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: Options(headers: headers),
      );

      print('✅ Survey submitted successfully');
      print('   Status Code: ${response.statusCode}');
      print('   Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to submit survey: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException in submitSurvey:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }

      if (e.response != null) {
        final errorMessage =
            e.response!.data?['message']?.toString() ??
            e.response!.data?['error']?.toString() ??
            'Failed to submit survey';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message ?? "Unknown error"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error submitting survey: $e');
      }
      rethrow;
    }
  }

  /// Silently creates a buyer review entry.
  /// This call should never block the primary survey submission flow.
  Future<bool> submitBuyerReviewSilently({
    required String currentUserId,
    required String professionalId,
    required double rating,
    required String review,
  }) async {
    try {
      final authToken = _storage.read('auth_token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = {
        'currentUserId': currentUserId,
        // Backend contract uses "agentId"; pass selected professional ID for both agent/LO.
        'agentId': professionalId,
        'rating': rating.round(),
        'review': review,
      };

      final response = await _dio.post(
        '/buyer/addReview',
        data: body,
        options: Options(headers: headers),
      );

      print('✅ submitBuyerReviewSilently response received');
      print('   Endpoint: ${ApiConstants.submitReviewEndpoint}');
      print('   Request body: $body');
      print('   Status Code: ${response.statusCode}');
      print('   Response: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Silent by requirement: ignore errors and avoid blocking UX.
      print('⚠️ submitBuyerReviewSilently failed: $e');
      return false;
    }
  }
}
