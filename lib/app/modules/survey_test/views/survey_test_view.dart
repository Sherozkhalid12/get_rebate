import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/demo_data/demo_survey_data.dart';
import 'package:getrebate/app/modules/post_closing_survey/views/post_closing_survey_view.dart';
import 'package:getrebate/app/modules/post_closing_survey/views/survey_preview_view.dart';
import 'package:getrebate/app/modules/post_closing_survey/controllers/post_closing_survey_controller.dart';
import 'package:getrebate/app/widgets/agent_reviews_widget.dart';
import 'package:getrebate/app/theme/app_theme.dart';

/// Test view for the Post-Closing Survey feature
/// Use this to test all survey functionality
class SurveyTestView extends StatelessWidget {
  const SurveyTestView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get sample data
    final agentId = 'test-agent-123';
    final stats = DemoSurveyData.getSampleAgentStats(agentId);
    final reviews = DemoSurveyData.getSampleSurveys(agentId);

    return Scaffold(
      backgroundColor: AppTheme.lightGray.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Survey Testing Dashboard'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),

            // Test Section 1: Take Survey
            _buildSection(
              context,
              'Test 1: Take Survey',
              'Fill out a complete post-closing survey as a buyer or seller',
              [
                _buildTestButton(
                  context,
                  'Start Survey (as Buyer)',
                  Icons.rate_review,
                  AppTheme.lightGreen,
                  () => _startSurvey(isBuyer: true),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  context,
                  'Start Survey (as Seller)',
                  Icons.rate_review,
                  AppTheme.primaryBlue,
                  () => _startSurvey(isBuyer: false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Section 2: Agent Preview
            _buildSection(
              context,
              'Test 2: Agent Preview',
              'View the survey questions from the agent\'s perspective',
              [
                _buildTestButton(
                  context,
                  'View Survey Preview (Agent View)',
                  Icons.visibility,
                  AppTheme.primaryBlue,
                  () => _showAgentPreview(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Section 3: View Reviews
            _buildSection(
              context,
              'Test 3: View Reviews',
              'See how reviews are displayed on agent profiles',
              [
                _buildTestButton(
                  context,
                  'View Full Reviews Widget',
                  Icons.star_rate,
                  AppTheme.lightGreen,
                  () => _showReviewsWidget(stats, reviews),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  context,
                  'View Rating Badge (Compact)',
                  Icons.stars,
                  AppTheme.lightGreen,
                  () => _showRatingBadge(stats),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Section 4: View Sample Data
            _buildSection(
              context,
              'Test 4: Sample Data',
              'View the generated sample data and statistics',
              [
                _buildTestButton(
                  context,
                  'View Sample Statistics',
                  Icons.analytics,
                  AppTheme.primaryBlue,
                  () => _showSampleStats(context, stats, reviews),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.lightGreen, AppTheme.lightGreen.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: AppTheme.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Survey Testing Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Test all features of the Post-Closing Survey system',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Testing Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(
            context,
            '1. Survey Flow Test',
            'Click "Start Survey" to test the complete survey experience. Try filling it out completely and also try exiting after Question 1 to test auto-save.',
          ),
          _buildInstructionItem(
            context,
            '2. Agent Preview Test',
            'Click "View Survey Preview" to see what agents see before working with clients.',
          ),
          _buildInstructionItem(
            context,
            '3. Reviews Display Test',
            'Test both the full reviews widget and compact rating badge to see how they appear on profiles.',
          ),
          _buildInstructionItem(
            context,
            '4. Sample Data Test',
            'View the generated sample data including 5 surveys with different ratings.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: This is demo data only. No actual API calls are made.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }

  // Test Actions

  void _startSurvey({required bool isBuyer}) {
    Get.delete<PostClosingSurveyController>();
    Get.put(PostClosingSurveyController());

    Get.to(
      () => const PostClosingSurveyView(),
      arguments: DemoSurveyData.getTestSurveyArguments(
        agentName: 'John Smith',
        isBuyer: isBuyer,
      ),
    );
  }

  void _showAgentPreview() {
    Get.to(() => const SurveyPreviewView(isBuyer: true));
  }

  void _showReviewsWidget(stats, reviews) {
    Get.to(
      () => Scaffold(
        backgroundColor: AppTheme.lightGray.withOpacity(0.3),
        appBar: AppBar(
          title: const Text('Reviews Widget Demo'),
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AgentReviewsWidget(
            stats: stats,
            reviews: reviews,
            onViewAllReviews: () {
              Get.snackbar(
                'View All Reviews',
                'This would navigate to a full reviews page',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRatingBadge(stats) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rating Badge Examples',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text('With Count:'),
              const SizedBox(height: 8),
              AgentRatingBadge(
                starRating: stats.starRating,
                reviewCount: stats.totalReviews,
                showCount: true,
              ),
              const SizedBox(height: 24),
              const Text('Without Count:'),
              const SizedBox(height: 8),
              AgentRatingBadge(
                starRating: stats.starRating,
                reviewCount: stats.totalReviews,
                showCount: false,
              ),
              const SizedBox(height: 24),
              const Text('No Reviews Yet:'),
              const SizedBox(height: 8),
              const AgentRatingBadge(
                starRating: 0,
                reviewCount: 0,
                showCount: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(Get.context!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  foregroundColor: AppTheme.white,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSampleStats(context, stats, reviews) {
    Get.dialog(
      Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Data Statistics',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow('Total Reviews:', '${stats.totalReviews}'),
                _buildStatRow(
                  'Average Score:',
                  '${stats.averageScore.toStringAsFixed(1)}/100',
                ),
                _buildStatRow(
                  'Star Rating:',
                  '${stats.starRating.toStringAsFixed(1)} ⭐',
                ),
                _buildStatRow(
                  'Total Rebates Paid:',
                  '\$${stats.totalRebatesPaid.toStringAsFixed(0)}',
                ),
                _buildStatRow(
                  'Would Recommend:',
                  '${stats.recommendationCount}/${stats.totalReviews}',
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Rating Distribution:',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(5, (index) {
                  final starLevel = 5 - index;
                  final count = stats.ratingDistribution[starLevel] ?? 0;
                  return _buildStatRow('$starLevel ⭐:', '$count reviews');
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightGreen,
                      foregroundColor: AppTheme.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppTheme.mediumGray)),
        ],
      ),
    );
  }
}
