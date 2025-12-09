// Post-closing survey model for collecting agent reviews from buyers/sellers

enum ReceivedExpectedRebate { yes, no, notSure }

enum RebateApplicationMethod { credit, no, other }

enum SignedDisclosure { yes, no, notSure }

enum RebateEase { veryEasy, somewhatEasy, neutral, difficult }

enum RecommendationLevel {
  definitely,
  probably,
  notSure,
  probablyNot,
  definitelyNot,
}

class PostClosingSurvey {
  final String id;
  final String agentId;
  final String userId; // Buyer or seller who completed the survey
  final String transactionId; // Reference to the transaction/listing
  final bool isBuyer; // true for buyer, false for seller

  // Survey responses
  final double rebateAmount; // Question 1
  final ReceivedExpectedRebate?
  receivedExpectedRebate; // Question 2 (nullable until answered)
  final RebateApplicationMethod? rebateApplicationMethod; // Question 3
  final String? rebateApplicationOther; // For "Other" explanation
  final SignedDisclosure? signedDisclosure; // Question 4
  final int? overallSatisfaction; // Question 5 (1-5)
  final RebateEase? rebateEase; // Question 6
  final RecommendationLevel? recommendationLevel; // Question 7
  final String? additionalComments; // Question 8 (optional)
  final int? agentRating; // Question 9 (1-10)

  // Metadata
  final DateTime createdAt;
  final DateTime? completedAt; // null if not completed
  final bool isComplete;
  final double? calculatedScore; // 0-100 score calculated from responses

  const PostClosingSurvey({
    required this.id,
    required this.agentId,
    required this.userId,
    required this.transactionId,
    required this.isBuyer,
    required this.rebateAmount,
    this.receivedExpectedRebate,
    this.rebateApplicationMethod,
    this.rebateApplicationOther,
    this.signedDisclosure,
    this.overallSatisfaction,
    this.rebateEase,
    this.recommendationLevel,
    this.additionalComments,
    this.agentRating,
    required this.createdAt,
    this.completedAt,
    this.isComplete = false,
    this.calculatedScore,
  });

  PostClosingSurvey copyWith({
    String? id,
    String? agentId,
    String? userId,
    String? transactionId,
    bool? isBuyer,
    double? rebateAmount,
    ReceivedExpectedRebate? receivedExpectedRebate,
    RebateApplicationMethod? rebateApplicationMethod,
    String? rebateApplicationOther,
    SignedDisclosure? signedDisclosure,
    int? overallSatisfaction,
    RebateEase? rebateEase,
    RecommendationLevel? recommendationLevel,
    String? additionalComments,
    int? agentRating,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isComplete,
    double? calculatedScore,
  }) {
    return PostClosingSurvey(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      userId: userId ?? this.userId,
      transactionId: transactionId ?? this.transactionId,
      isBuyer: isBuyer ?? this.isBuyer,
      rebateAmount: rebateAmount ?? this.rebateAmount,
      receivedExpectedRebate:
          receivedExpectedRebate ?? this.receivedExpectedRebate,
      rebateApplicationMethod:
          rebateApplicationMethod ?? this.rebateApplicationMethod,
      rebateApplicationOther:
          rebateApplicationOther ?? this.rebateApplicationOther,
      signedDisclosure: signedDisclosure ?? this.signedDisclosure,
      overallSatisfaction: overallSatisfaction ?? this.overallSatisfaction,
      rebateEase: rebateEase ?? this.rebateEase,
      recommendationLevel: recommendationLevel ?? this.recommendationLevel,
      additionalComments: additionalComments ?? this.additionalComments,
      agentRating: agentRating ?? this.agentRating,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isComplete: isComplete ?? this.isComplete,
      calculatedScore: calculatedScore ?? this.calculatedScore,
    );
  }

  factory PostClosingSurvey.fromJson(Map<String, dynamic> json) {
    return PostClosingSurvey(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      userId: json['userId'] as String,
      transactionId: json['transactionId'] as String,
      isBuyer: json['isBuyer'] as bool,
      rebateAmount: (json['rebateAmount'] as num).toDouble(),
      receivedExpectedRebate: json['receivedExpectedRebate'] != null
          ? ReceivedExpectedRebate.values.byName(
              json['receivedExpectedRebate'] as String,
            )
          : null,
      rebateApplicationMethod: json['rebateApplicationMethod'] != null
          ? RebateApplicationMethod.values.byName(
              json['rebateApplicationMethod'] as String,
            )
          : null,
      rebateApplicationOther: json['rebateApplicationOther'] as String?,
      signedDisclosure: json['signedDisclosure'] != null
          ? SignedDisclosure.values.byName(json['signedDisclosure'] as String)
          : null,
      overallSatisfaction: json['overallSatisfaction'] as int?,
      rebateEase: json['rebateEase'] != null
          ? RebateEase.values.byName(json['rebateEase'] as String)
          : null,
      recommendationLevel: json['recommendationLevel'] != null
          ? RecommendationLevel.values.byName(
              json['recommendationLevel'] as String,
            )
          : null,
      additionalComments: json['additionalComments'] as String?,
      agentRating: json['agentRating'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isComplete: json['isComplete'] as bool? ?? false,
      calculatedScore: json['calculatedScore'] != null
          ? (json['calculatedScore'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'userId': userId,
      'transactionId': transactionId,
      'isBuyer': isBuyer,
      'rebateAmount': rebateAmount,
      'receivedExpectedRebate': receivedExpectedRebate?.name,
      'rebateApplicationMethod': rebateApplicationMethod?.name,
      'rebateApplicationOther': rebateApplicationOther,
      'signedDisclosure': signedDisclosure?.name,
      'overallSatisfaction': overallSatisfaction,
      'rebateEase': rebateEase?.name,
      'recommendationLevel': recommendationLevel?.name,
      'additionalComments': additionalComments,
      'agentRating': agentRating,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isComplete': isComplete,
      'calculatedScore': calculatedScore,
    };
  }

  /// Check if all mandatory fields are filled
  bool get hasAllMandatoryFields {
    return receivedExpectedRebate != null &&
        rebateApplicationMethod != null &&
        signedDisclosure != null &&
        overallSatisfaction != null &&
        rebateEase != null &&
        recommendationLevel != null &&
        agentRating != null;
  }
}

/// Agent review statistics aggregated from surveys
class AgentReviewStats {
  final String agentId;
  final int totalReviews;
  final double averageScore; // 0-100
  final double starRating; // 0-5 (calculated from averageScore)
  final double totalRebatesPaid;
  final int recommendationCount; // How many would recommend
  final Map<int, int> ratingDistribution; // Distribution of star ratings (1-5)

  const AgentReviewStats({
    required this.agentId,
    required this.totalReviews,
    required this.averageScore,
    required this.starRating,
    required this.totalRebatesPaid,
    required this.recommendationCount,
    required this.ratingDistribution,
  });

  factory AgentReviewStats.fromJson(Map<String, dynamic> json) {
    return AgentReviewStats(
      agentId: json['agentId'] as String,
      totalReviews: json['totalReviews'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      starRating: (json['starRating'] as num).toDouble(),
      totalRebatesPaid: (json['totalRebatesPaid'] as num).toDouble(),
      recommendationCount: json['recommendationCount'] as int,
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'totalReviews': totalReviews,
      'averageScore': averageScore,
      'starRating': starRating,
      'totalRebatesPaid': totalRebatesPaid,
      'recommendationCount': recommendationCount,
      'ratingDistribution': ratingDistribution,
    };
  }
}
