import 'package:getrebate/app/models/post_closing_survey_model.dart';

/// Service for calculating agent ratings from post-closing surveys
class SurveyRatingService {
  /// Calculate a 0-100 score from survey responses
  /// Weighted scoring:
  /// - Questions 5 & 9 (direct satisfaction): 40% of score
  /// - Question 7 (recommendation): 25% of score
  /// - Questions 2, 4, 6 (process quality): 25% of score
  /// - Question 3 (rebate application): 10% of score
  static double calculateScore(PostClosingSurvey survey) {
    if (!survey.hasAllMandatoryFields) {
      return 0.0;
    }

    double totalScore = 0.0;

    // Question 5: Overall satisfaction (1-5) - 20% weight
    if (survey.overallSatisfaction != null) {
      totalScore += (survey.overallSatisfaction! - 1) / 4 * 20.0;
    }

    // Question 9: Agent rating (1-10) - 20% weight
    if (survey.agentRating != null) {
      totalScore += (survey.agentRating! - 1) / 9 * 20.0;
    }

    // Question 7: Recommendation level - 25% weight
    if (survey.recommendationLevel != null) {
      totalScore += _getRecommendationScore(survey.recommendationLevel!) * 25.0;
    }

    // Question 2: Received expected rebate - 10% weight
    if (survey.receivedExpectedRebate != null) {
      totalScore +=
          _getExpectedRebateScore(survey.receivedExpectedRebate!) * 10.0;
    }

    // Question 4: Signed disclosure - 7.5% weight
    if (survey.signedDisclosure != null) {
      totalScore += _getSignedDisclosureScore(survey.signedDisclosure!) * 7.5;
    }

    // Question 6: Rebate ease - 7.5% weight
    if (survey.rebateEase != null) {
      totalScore += _getRebateEaseScore(survey.rebateEase!) * 7.5;
    }

    // Question 3: Rebate application method - 10% weight
    if (survey.rebateApplicationMethod != null) {
      totalScore +=
          _getRebateApplicationScore(survey.rebateApplicationMethod!) * 10.0;
    }

    return totalScore;
  }

  /// Convert 0-100 score to 5-star rating
  static double scoreToStars(double score) {
    return (score / 100.0) * 5.0;
  }

  /// Convert 5-star rating back to 0-100 score
  static double starsToScore(double stars) {
    return (stars / 5.0) * 100.0;
  }

  // Scoring helpers for individual questions

  static double _getRecommendationScore(RecommendationLevel level) {
    switch (level) {
      case RecommendationLevel.definitely:
        return 1.0;
      case RecommendationLevel.probably:
        return 0.75;
      case RecommendationLevel.notSure:
        return 0.5;
      case RecommendationLevel.probablyNot:
        return 0.25;
      case RecommendationLevel.definitelyNot:
        return 0.0;
    }
  }

  static double _getExpectedRebateScore(ReceivedExpectedRebate received) {
    switch (received) {
      case ReceivedExpectedRebate.yes:
        return 1.0;
      case ReceivedExpectedRebate.notSure:
        return 0.5;
      case ReceivedExpectedRebate.no:
        return 0.0;
    }
  }

  static double _getSignedDisclosureScore(SignedDisclosure signed) {
    switch (signed) {
      case SignedDisclosure.yes:
        return 1.0;
      case SignedDisclosure.notSure:
        return 0.5;
      case SignedDisclosure.no:
        return 0.0; // Could be concerning if not signed
    }
  }

  static double _getRebateEaseScore(RebateEase ease) {
    switch (ease) {
      case RebateEase.veryEasy:
        return 1.0;
      case RebateEase.somewhatEasy:
        return 0.75;
      case RebateEase.neutral:
        return 0.5;
      case RebateEase.difficult:
        return 0.25;
    }
  }

  static double _getRebateApplicationScore(RebateApplicationMethod method) {
    switch (method) {
      case RebateApplicationMethod.credit:
        return 1.0; // Applied as credit is ideal
      case RebateApplicationMethod.other:
        return 0.75; // Other methods might be acceptable
      case RebateApplicationMethod.no:
        return 0.0; // Not applied could be a problem
    }
  }

  /// Get text description of star rating
  static String getStarRatingDescription(double stars) {
    if (stars >= 4.5) return 'Excellent';
    if (stars >= 4.0) return 'Very Good';
    if (stars >= 3.5) return 'Good';
    if (stars >= 3.0) return 'Average';
    if (stars >= 2.0) return 'Below Average';
    return 'Poor';
  }

  /// Calculate aggregate stats for an agent from multiple surveys
  static AgentReviewStats calculateAgentStats({
    required String agentId,
    required List<PostClosingSurvey> completedSurveys,
  }) {
    if (completedSurveys.isEmpty) {
      return AgentReviewStats(
        agentId: agentId,
        totalReviews: 0,
        averageScore: 0.0,
        starRating: 0.0,
        totalRebatesPaid: 0.0,
        recommendationCount: 0,
        ratingDistribution: {},
      );
    }

    // Calculate average score
    double totalScore = 0.0;
    double totalRebates = 0.0;
    int recommendCount = 0;
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var survey in completedSurveys) {
      double score = survey.calculatedScore ?? calculateScore(survey);
      totalScore += score;
      totalRebates += survey.rebateAmount;

      // Count recommendations
      if (survey.recommendationLevel == RecommendationLevel.definitely ||
          survey.recommendationLevel == RecommendationLevel.probably) {
        recommendCount++;
      }

      // Build distribution
      double stars = scoreToStars(score);
      int starBucket = stars.round().clamp(1, 5);
      distribution[starBucket] = (distribution[starBucket] ?? 0) + 1;
    }

    double averageScore = totalScore / completedSurveys.length;
    double starRating = scoreToStars(averageScore);

    return AgentReviewStats(
      agentId: agentId,
      totalReviews: completedSurveys.length,
      averageScore: averageScore,
      starRating: starRating,
      totalRebatesPaid: totalRebates,
      recommendationCount: recommendCount,
      ratingDistribution: distribution,
    );
  }

  /// Format star rating for display (e.g., "4.5")
  static String formatStarRating(double stars) {
    return stars.toStringAsFixed(1);
  }

  /// Format score for display (e.g., "87")
  static String formatScore(double score) {
    return score.round().toString();
  }
}
