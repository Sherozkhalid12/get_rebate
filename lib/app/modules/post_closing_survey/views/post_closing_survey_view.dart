// post_closing_survey_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import '../controllers/post_closing_survey_controller.dart';

class PostClosingSurveyView extends GetView<PostClosingSurveyController> {
  const PostClosingSurveyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.showSelectionScreen 
            ? 'Select Professional to Review'
            : (controller.isAgentSurvey ? 'Rate Your Agent' : 'Rate Loan Officer'),
        )),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.showSelectionScreen) {
          return _buildSelectionScreen(context);
        } else {
          return Column(
            children: [
              _buildProgress(),
              Expanded(child: _buildQuestion()),
              _buildNavButtons(),
            ],
          );
        }
      }),
    );
  }

  /// Build the professional selection screen (first screen)
  Widget _buildSelectionScreen(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProfessionals) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitFadingCircle(
                color: AppTheme.primaryBlue,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading completed professionals...',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.completedProfessionals.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(height: 20),
                Text(
                  'No Completed Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You don\'t have any completed transactions with agents yet.\nComplete a service with an agent to leave a review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select an Agent to Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an agent you worked with to submit your review',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          
          // Professionals List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.completedProfessionals.length,
              itemBuilder: (context, index) {
                final professional = controller.completedProfessionals[index];
                return _buildProfessionalCard(context, professional);
              },
            ),
          ),
        ],
      );
    });
  }

  /// Build profile image widget
  Widget _buildProfileImage(CompletedProfessional professional) {
    if (professional.profileImage == null || professional.profileImage!.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: AppTheme.lightGray,
        child: Icon(
          Icons.person,
          color: AppTheme.mediumGray,
          size: 30,
        ),
      );
    }

    final imageUrl = ApiConstants.getImageUrl(professional.profileImage);
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: AppTheme.lightGray,
        child: Icon(
          Icons.person,
          color: AppTheme.mediumGray,
          size: 30,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 60,
        height: 60,
        color: AppTheme.lightGray,
        child: Icon(
          Icons.person,
          color: AppTheme.mediumGray,
          size: 30,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 60,
        height: 60,
        color: AppTheme.lightGray,
        child: Icon(
          Icons.person,
          color: AppTheme.mediumGray,
          size: 30,
        ),
      ),
    );
  }

  /// Build a card for a professional (agent or loan officer)
  Widget _buildProfessionalCard(BuildContext context, CompletedProfessional professional) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => controller.selectProfessional(professional),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: _buildProfileImage(professional),
              ),
              const SizedBox(width: 16),
              
              // Name and Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: professional.type == 'agent'
                                ? AppTheme.primaryBlue.withOpacity(0.1)
                                : AppTheme.lightGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Agent',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        if (professional.company != null &&
                            professional.company!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            professional.company!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.mediumGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${controller.currentStep + 1} of ${controller.totalSteps}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${((controller.currentStep + 1) / controller.totalSteps * 100).round()}%',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LinearProgressIndicator(
              value: (controller.currentStep + 1) / controller.totalSteps,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: AppTheme.lightGray,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Obx(() {
        if (controller.isAgentSurvey) return _agentQuestion();
        return _loanOfficerQuestion();
      }),
    );
  }

  Widget _agentQuestion() {
    final q = controller.currentStep;
    final List<Widget> questions = [
      _moneyField(
        'How much was your rebate from your agent?',
        controller.rebateAmountController,
        (v) => controller.agentRebateAmount.value = double.tryParse(v) ?? 0,
      ),
      _radioGroup(
        'Did you receive the rebate you expected?',
        ['Yes', 'No', 'Not sure'],
        controller.agentRebateExpected,
      ),
      _radioGroup(
        'Was rebate applied as credit at closing?',
        ['Yes', 'No', 'Other', 'Lower listing fee (selling only)'],
        controller.agentRebateMethod,
        hasOther: true,
      ),
      _radioGroup('Did you sign the rebate disclosure?', [
        'Yes',
        'No',
        'Not sure',
      ], controller.agentSignedDisclosure),
      _radioGroup(
        'Was receiving your rebate easy?',
        ['Very easy', 'Somewhat easy', 'Neutral', 'Difficult'],
        controller.agentRebateEase,
        required: true,
      ),
      _radioGroup('Would you recommend your agent?', [
        'Definitely',
        'Probably',
        'Not sure',
        'Probably not',
        'Definitely not',
      ], controller.agentRecommend),
      _textArea('Anything else to share?', controller.commentsController),
      _sliderRating(
        'Overall satisfaction with agent',
        controller.agentRating,
        required: true,
      ),
    ];
    return questions[q];
  }

  Widget _loanOfficerQuestion() {
    final q = controller.currentStep;
    final List<Widget> questions = [
      _sliderRating(
        'How satisfied with loan officer?',
        controller.loSatisfaction,
        required: true,
      ),
      _radioGroup('Explained loan options clearly?', [
        'Yes',
        'Somewhat',
        'No',
      ], controller.loExplainedOptions),
      _radioGroup('Communication clear & timely?', [
        'Always',
        'Most of time',
        'Occasionally',
        'Rarely',
      ], controller.loCommunication),
      _radioGroup('Helped with rebate?', [
        'Yes',
        'Somewhat',
        'No',
        'Not applicable',
      ], controller.loRebateHelp),
      _radioGroup('Loan process easy?', [
        'Very easy',
        'Somewhat easy',
        'Neutral',
        'Difficult',
      ], controller.loEase),
      _radioGroup('Knowledgeable & professional?', [
        'Yes',
        'Somewhat',
        'No',
      ], controller.loProfessional),
      _radioGroup('Closed on time?', [
        'Yes',
        'No',
        'Not sure',
      ], controller.loClosedOnTime),
      _radioGroup('Recommend loan officer?', [
        'Definitely',
        'Probably',
        'Not sure',
        'Probably not',
        'Definitely not',
      ], controller.loRecommend),
      _radioGroup(
        'Loan type?',
        ['Conventional', 'FHA', 'VA', 'USDA', 'Jumbo', 'Other'],
        controller.loLoanType,
        hasOther: true,
        otherController: controller.loanTypeOtherController,
      ),
      _textArea('Additional comments?', controller.commentsController),
    ];
    return questions[q];
  }

  Widget _moneyField(
    String label,
    TextEditingController ctrl,
    Function(String) onChanged,
  ) {
    return _questionCard(
      label,
      required: true,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '\$ ',
          hintText: '0.00',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _radioGroup(
    String label,
    List<String> options,
    Rxn<String> value, {
    bool required = false,
    bool hasOther = false,
    TextEditingController? otherController,
  }) {
    return _questionCard(
      label,
      required: required,
      child: Column(
        children: options.map((opt) {
          final isOther = opt == 'Other';
          return Column(
            children: [
              RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: value.value,
                onChanged: (v) => value.value = v,
                activeColor: AppTheme.lightGreen,
              ),
              if (isOther && value.value == 'Other' && hasOther)
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: TextField(
                    controller: otherController,
                    decoration: InputDecoration(
                      hintText: 'Please explain',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _sliderRating(String label, RxDouble value, {bool required = false}) {
    return _questionCard(
      label,
      required: required,
      child: Column(
        children: [
          Text(
            value.value == 0
                ? 'Tap to rate'
                : '${value.value.toStringAsFixed(1)} / 5.0',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: value.value,
            min: 0.5,
            max: 5.0,
            divisions: 90,
            label: value.value.toStringAsFixed(1),
            activeColor: AppTheme.lightGreen,
            onChanged: (v) => value.value = v,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Poor'), Text('Excellent')],
          ),
        ],
      ),
    );
  }

  Widget _textArea(String label, TextEditingController ctrl) {
    return _questionCard(
      label,
      child: TextField(
        controller: ctrl,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Optional comments...',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _questionCard(
    String title, {
    bool required = false,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: required ? Colors.red.shade100 : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 10),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Obx(
        () => Row(
          children: [
            if (controller.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.lightGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (controller.currentStep > 0) SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: controller.canProceed() && !controller.isLoading
                    ? (controller.currentStep == controller.totalSteps - 1
                          ? controller.submitSurvey
                          : controller.nextStep)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: SpinKitFadingCircle(
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : Text(
                        controller.currentStep == controller.totalSteps - 1
                            ? 'Submit'
                            : 'Next',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
