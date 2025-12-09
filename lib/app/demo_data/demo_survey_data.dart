import 'package:getrebate/app/models/post_closing_survey_model.dart';
import 'package:getrebate/app/services/survey_rating_service.dart';

/// Demo data for testing the post-closing survey feature
class DemoSurveyData {
  /// Sample completed surveys for testing
  static List<PostClosingSurvey> getSampleSurveys(String agentId) {
    final now = DateTime.now();

    final survey1 = PostClosingSurvey(
      id: 'survey-1',
      agentId: agentId,
      userId: 'user-1',
      transactionId: 'transaction-1',
      isBuyer: true,
      rebateAmount: 8500.0,
      receivedExpectedRebate: ReceivedExpectedRebate.yes,
      rebateApplicationMethod: RebateApplicationMethod.credit,
      signedDisclosure: SignedDisclosure.yes,
      overallSatisfaction: 5,
      rebateEase: RebateEase.veryEasy,
      recommendationLevel: RecommendationLevel.definitely,
      additionalComments:
          'John was absolutely fantastic! The rebate process was seamless and he saved us thousands. Highly recommend!',
      agentRating: 10,
      createdAt: now.subtract(const Duration(days: 30)),
      completedAt: now.subtract(const Duration(days: 30)),
      isComplete: true,
    );

    final survey2 = PostClosingSurvey(
      id: 'survey-2',
      agentId: agentId,
      userId: 'user-2',
      transactionId: 'transaction-2',
      isBuyer: true,
      rebateAmount: 12000.0,
      receivedExpectedRebate: ReceivedExpectedRebate.yes,
      rebateApplicationMethod: RebateApplicationMethod.credit,
      signedDisclosure: SignedDisclosure.yes,
      overallSatisfaction: 4,
      rebateEase: RebateEase.veryEasy,
      recommendationLevel: RecommendationLevel.probably,
      additionalComments:
          'Great experience overall. The rebate was substantial and made a real difference in our closing costs.',
      agentRating: 9,
      createdAt: now.subtract(const Duration(days: 45)),
      completedAt: now.subtract(const Duration(days: 45)),
      isComplete: true,
    );

    final survey3 = PostClosingSurvey(
      id: 'survey-3',
      agentId: agentId,
      userId: 'user-3',
      transactionId: 'transaction-3',
      isBuyer: false, // Seller
      rebateAmount: 15500.0,
      receivedExpectedRebate: ReceivedExpectedRebate.yes,
      rebateApplicationMethod: RebateApplicationMethod.credit,
      signedDisclosure: SignedDisclosure.yes,
      overallSatisfaction: 5,
      rebateEase: RebateEase.somewhatEasy,
      recommendationLevel: RecommendationLevel.definitely,
      additionalComments:
          'Professional service from start to finish. The rebate was processed exactly as promised.',
      agentRating: 9,
      createdAt: now.subtract(const Duration(days: 60)),
      completedAt: now.subtract(const Duration(days: 60)),
      isComplete: true,
    );

    final survey4 = PostClosingSurvey(
      id: 'survey-4',
      agentId: agentId,
      userId: 'user-4',
      transactionId: 'transaction-4',
      isBuyer: true,
      rebateAmount: 6800.0,
      receivedExpectedRebate: ReceivedExpectedRebate.notSure,
      rebateApplicationMethod: RebateApplicationMethod.credit,
      signedDisclosure: SignedDisclosure.yes,
      overallSatisfaction: 4,
      rebateEase: RebateEase.neutral,
      recommendationLevel: RecommendationLevel.probably,
      agentRating: 8,
      createdAt: now.subtract(const Duration(days: 15)),
      completedAt: now.subtract(const Duration(days: 15)),
      isComplete: true,
    );

    final survey5 = PostClosingSurvey(
      id: 'survey-5',
      agentId: agentId,
      userId: 'user-5',
      transactionId: 'transaction-5',
      isBuyer: true,
      rebateAmount: 9200.0,
      receivedExpectedRebate: ReceivedExpectedRebate.yes,
      rebateApplicationMethod: RebateApplicationMethod.credit,
      signedDisclosure: SignedDisclosure.yes,
      overallSatisfaction: 3,
      rebateEase: RebateEase.neutral,
      recommendationLevel: RecommendationLevel.notSure,
      additionalComments:
          'The rebate was good but the process took longer than expected. Would have appreciated better communication.',
      agentRating: 6,
      createdAt: now.subtract(const Duration(days: 90)),
      completedAt: now.subtract(const Duration(days: 90)),
      isComplete: true,
    );

    // Calculate scores for each survey
    final surveysWithScores = [survey1, survey2, survey3, survey4, survey5].map(
      (survey) {
        final score = SurveyRatingService.calculateScore(survey);
        return survey.copyWith(calculatedScore: score);
      },
    ).toList();

    return surveysWithScores;
  }

  /// Get aggregated stats for an agent
  static AgentReviewStats getSampleAgentStats(String agentId) {
    final surveys = getSampleSurveys(agentId);
    return SurveyRatingService.calculateAgentStats(
      agentId: agentId,
      completedSurveys: surveys,
    );
  }

  /// Get an empty/new survey for testing the form
  static Map<String, dynamic> getTestSurveyArguments({
    String agentId = 'test-agent-123',
    String agentName = 'John Smith',
    String userId = 'test-user-456',
    String transactionId = 'test-transaction-789',
    bool isBuyer = true,
  }) {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'userId': userId,
      'transactionId': transactionId,
      'isBuyer': isBuyer,
    };
  }
}
