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
  }) async {
    try {
      final authToken = _storage.read('auth_token');
      
      final requestBody = {
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

      if (kDebugMode) {
        print('📡 Submitting survey');
        print('   Endpoint: ${ApiConstants.submitSurveyEndpoint}');
        print('   Request body: $requestBody');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        ...ApiConstants.ngrokHeaders,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await _dio.post(
        '/api/v1/survey/submit',
        data: requestBody,
        options: Options(headers: headers),
      );

      if (kDebugMode) {
        print('✅ Survey submitted successfully');
        print('   Status Code: ${response.statusCode}');
        print('   Response: ${response.data}');
      }

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
}
