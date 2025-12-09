import 'package:flutter/material.dart';
import 'package:getrebate/app/models/post_closing_survey_model.dart';
import 'package:getrebate/app/services/survey_rating_service.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Widget to display agent reviews and ratings on their profile
class AgentReviewsWidget extends StatelessWidget {
  final AgentReviewStats stats;
  final List<PostClosingSurvey> reviews;
  final VoidCallback? onViewAllReviews;

  const AgentReviewsWidget({
    super.key,
    required this.stats,
    required this.reviews,
    this.onViewAllReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with overall rating
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rate, color: AppTheme.lightGreen, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Client Reviews',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOverallRating(context),
              ],
            ),
          ),

          const Divider(height: 1),

          // Rating distribution
          if (stats.totalReviews > 0) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRatingDistribution(context),
            ),
            const Divider(height: 1),
          ],

          // Recent reviews with comments
          if (reviews.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Reviews',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reviews
                      .where(
                        (review) =>
                            review.additionalComments != null &&
                            review.additionalComments!.isNotEmpty,
                      )
                      .take(3)
                      .map((review) => _buildReviewCard(context, review)),
                ],
              ),
            ),
          ],

          // View all reviews button
          if (onViewAllReviews != null && stats.totalReviews > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewAllReviews,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.lightGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('View All ${stats.totalReviews} Reviews'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverallRating(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    SurveyRatingService.formatStarRating(stats.starRating),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStars(stats.starRating),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                SurveyRatingService.getStarRatingDescription(stats.starRating),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.totalReviews} ${stats.totalReviews == 1 ? "review" : "reviews"}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.darkGray),
              ),
            ],
          ),
        ),

        // Recommendation percentage
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '${((stats.recommendationCount / stats.totalReviews) * 100).round()}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.lightGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Would\nRecommend',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: AppTheme.lightGreen, size: 20);
        } else if (index < rating) {
          return const Icon(
            Icons.star_half,
            color: AppTheme.lightGreen,
            size: 20,
          );
        } else {
          return Icon(
            Icons.star_border,
            color: AppTheme.mediumGray.withOpacity(0.5),
            size: 20,
          );
        }
      }),
    );
  }

  Widget _buildRatingDistribution(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Distribution',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (index) {
          final starLevel = 5 - index;
          final count = stats.ratingDistribution[starLevel] ?? 0;
          final percentage = stats.totalReviews > 0
              ? count / stats.totalReviews
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      Text(
                        '$starLevel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: AppTheme.lightGreen, size: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 30,
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.right,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, PostClosingSurvey review) {
    final score = review.calculatedScore ?? 0.0;
    final stars = SurveyRatingService.scoreToStars(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStars(stars),
              const Spacer(),
              Text(
                DateFormat(
                  'MMM d, yyyy',
                ).format(review.completedAt ?? review.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
              ),
            ],
          ),
          if (review.additionalComments != null &&
              review.additionalComments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.additionalComments!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.verified,
                color: AppTheme.lightGreen.withOpacity(0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Verified ${review.isBuyer ? "Buyer" : "Seller"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGray,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              if (review.recommendationLevel ==
                      RecommendationLevel.definitely ||
                  review.recommendationLevel ==
                      RecommendationLevel.probably) ...[
                Icon(
                  Icons.thumb_up,
                  color: AppTheme.lightGreen.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Would recommend',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact version for displaying in listing cards or search results
class AgentRatingBadge extends StatelessWidget {
  final double starRating;
  final int reviewCount;
  final bool showCount;

  const AgentRatingBadge({
    super.key,
    required this.starRating,
    required this.reviewCount,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'No reviews yet',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mediumGray,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: AppTheme.lightGreen, size: 14),
          const SizedBox(width: 4),
          Text(
            SurveyRatingService.formatStarRating(starRating),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.lightGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (showCount) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
