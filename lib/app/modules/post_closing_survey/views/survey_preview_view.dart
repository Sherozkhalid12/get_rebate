import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';

/// View for agents to preview the post-closing survey questions
/// This helps agents understand what buyers/sellers will be asked
class SurveyPreviewView extends StatelessWidget {
  final bool isBuyer;

  const SurveyPreviewView({super.key, this.isBuyer = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Post-Closing Survey Questions'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'What Your Clients Will Be Asked',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.black,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'After closing, your ${isBuyer ? "buyers" : "sellers"} will be asked to complete this survey. Their responses will contribute to your rating on GetaRebate.com. Use these questions as a guide to ensure you provide exceptional service.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Survey questions
            _buildQuestion(
              context,
              1,
              'How much was the rebate amount you received?',
              'Text input for dollar amount',
              isRequired: true,
              note:
                  'This amount is captured even if the client doesn\'t complete the full survey.',
            ),

            _buildQuestion(
              context,
              2,
              'Did you receive the rebate amount you expected?',
              'Options: Yes / No / Not sure',
              isRequired: true,
            ),

            _buildQuestion(
              context,
              3,
              'Was the rebate applied as a credit to you at closing?',
              'Options: Yes / No / Other (with explanation field)',
              isRequired: true,
            ),

            _buildQuestion(
              context,
              4,
              'Did you and your agent sign the rebate disclosure form?',
              'Options: Yes / No / Not sure',
              isRequired: true,
              note:
                  'Compliance is important. Make sure to complete this step with your clients.',
            ),

            _buildQuestion(
              context,
              5,
              'How satisfied are you with your agent and the rebate process overall?',
              'Scale: 1 (Not satisfied) to 5 (Very satisfied)',
              isRequired: true,
              weight: 'High impact on rating',
            ),

            _buildQuestion(
              context,
              6,
              'Was receiving your rebate easy?',
              'Options: Very easy / Somewhat easy / Neutral / Difficult',
              isRequired: true,
            ),

            _buildQuestion(
              context,
              7,
              'Would you recommend your agent to family and friends?',
              'Options: Definitely / Probably / Not sure / Probably not / Definitely not',
              isRequired: true,
              weight: 'High impact on rating',
            ),

            _buildQuestion(
              context,
              8,
              'Is there anything else you\'d like to share about your experience?',
              'Free text field (up to 500 characters)',
              isRequired: false,
              note:
                  'Comments may be displayed publicly on your profile. Encourage clients to share positive experiences!',
            ),

            _buildQuestion(
              context,
              9,
              'Overall, how would you rate your satisfaction with your agent?',
              'Scale: 1 (Poor) to 10 (Excellent)',
              isRequired: true,
              weight: 'High impact on rating',
            ),

            const SizedBox(height: 24),

            // Rating information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: AppTheme.lightGreen, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'How Your Rating is Calculated',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.black,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRatingInfo(
                    context,
                    'Questions 5 & 9',
                    'Direct satisfaction ratings',
                    '40% of your score',
                  ),
                  _buildRatingInfo(
                    context,
                    'Question 7',
                    'Client recommendation',
                    '25% of your score',
                  ),
                  _buildRatingInfo(
                    context,
                    'Questions 2, 4, 6',
                    'Process quality',
                    '25% of your score',
                  ),
                  _buildRatingInfo(
                    context,
                    'Question 3',
                    'Rebate application',
                    '10% of your score',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your final rating will be displayed as a 5-star rating on your profile, calculated from the weighted average of all completed surveys.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    int number,
    String question,
    String answerFormat, {
    required bool isRequired,
    String? note,
    String? weight,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            question,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Required',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answerFormat,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    if (weight != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          weight,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.lightGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInfo(
    BuildContext context,
    String questions,
    String description,
    String weight,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: AppTheme.lightGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.darkGray),
                children: [
                  TextSpan(
                    text: '$questions: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: '$description '),
                  TextSpan(
                    text: '($weight)',
                    style: TextStyle(
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
